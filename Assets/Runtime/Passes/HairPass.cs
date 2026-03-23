using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class HairPass : ScriptableRenderPass
{
    private ShaderTagId m_ShaderTagId = new ShaderTagId("Hair");
    private FilteringSettings m_FilteringSettings;
    private ProfilingSampler m_ProfilingSampler = new ProfilingSampler("Hair");
    
    public HairPass()
    {
        renderPassEvent = RenderPassEvent.AfterRenderingOpaques + 10;
        m_FilteringSettings = new FilteringSettings(RenderQueueRange.all);
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
            DrawingSettings drawingSettings =
                CreateDrawingSettings(m_ShaderTagId, ref renderingData, cameraData.defaultOpaqueSortFlags);
            context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringSettings);
        }
        
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }
}