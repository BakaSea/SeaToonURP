using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class EyeBrowMaskPass : ScriptableRenderPass
{
    private int m_EyeBrowMaskID;
    private RTHandle m_EyeBrowMaskTexture;
    private RenderTextureDescriptor m_EyeBrowMaskTextureDescriptor;
    private const string k_EyeBrowMaskTextureName = "_EyeBrowMaskTexture";
    
    private ShaderTagId m_ShaderTagId = new ShaderTagId("EyeBrowMask");
    private FilteringSettings m_FilteringSettings;
    
    private ProfilingSampler m_ProfilingSampler = new ProfilingSampler("EyeBrowMask");
    
    public EyeBrowMaskPass()
    {
        renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque);
        m_EyeBrowMaskID = Shader.PropertyToID(k_EyeBrowMaskTextureName);
    }

    public void Dispose()
    {
        m_EyeBrowMaskTexture?.Release();
    }
    
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        CameraData cameraData = renderingData.cameraData;
        m_EyeBrowMaskTextureDescriptor = cameraData.cameraTargetDescriptor;
        m_EyeBrowMaskTextureDescriptor.msaaSamples = cameraData.cameraTargetDescriptor.msaaSamples;
        m_EyeBrowMaskTextureDescriptor.graphicsFormat = GraphicsFormat.R8_UNorm;
        m_EyeBrowMaskTextureDescriptor.depthStencilFormat = GraphicsFormat.None;
        RenderingUtils.ReAllocateIfNeeded(ref m_EyeBrowMaskTexture, m_EyeBrowMaskTextureDescriptor, FilterMode.Bilinear, TextureWrapMode.Clamp, name: k_EyeBrowMaskTextureName);
        
        ConfigureTarget( m_EyeBrowMaskTexture, cameraData.renderer.cameraDepthTargetHandle);
        ConfigureClear(ClearFlag.Color, Color.black);
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
            cmd.SetGlobalTexture(m_EyeBrowMaskID, m_EyeBrowMaskTexture);
        }
        
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }
}