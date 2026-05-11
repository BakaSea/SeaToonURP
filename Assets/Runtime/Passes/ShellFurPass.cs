using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ShellFurPass : ScriptableRenderPass
{
    private static readonly int ShellIndexId = Shader.PropertyToID("_ShellIndex");

    private ShaderTagId m_ShaderTagId = new ShaderTagId("ShellFur");
    private FilteringSettings m_FilteringSettings;
    private ProfilingSampler m_ProfilingSampler = new ProfilingSampler("ShellFur");

    private int m_MaxShellCount;

    public ShellFurPass(int maxShellCount)
    {
        renderPassEvent = RenderPassEvent.AfterRenderingOpaques + 5;
        m_FilteringSettings = new FilteringSettings(RenderQueueRange.all);
        m_MaxShellCount = maxShellCount;
    }

    public void Setup(int maxShellCount)
    {
        m_MaxShellCount = maxShellCount;
    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        CameraData cameraData = renderingData.cameraData;
        ConfigureTarget(cameraData.renderer.cameraColorTargetHandle, cameraData.renderer.cameraDepthTargetHandle);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get();

        using (new ProfilingScope(cmd, m_ProfilingSampler))
        {
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            CameraData cameraData = renderingData.cameraData;

            // 逐层迭代绘制所有Shell层
            // _ShellIndex作为全局变量传入shader，每个材质在片元中根据自身的_ShellCount判断是否discard
            // 这样每个材质可以拥有独立的层数参数，超出自身层数的迭代会被shader丢弃
            for (int i = 0; i < m_MaxShellCount; i++)
            {
                cmd.SetGlobalInteger(ShellIndexId, i);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                DrawingSettings drawingSettings =
                    CreateDrawingSettings(m_ShaderTagId, ref renderingData, cameraData.defaultOpaqueSortFlags);
                drawingSettings.enableInstancing = true;
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringSettings);
            }
        }

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }
}
