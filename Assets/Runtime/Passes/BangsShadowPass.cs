using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BangsShadowPass : ScriptableRenderPass
{
    
    private int m_BangsShadowID;
    private RTHandle m_BangsShadowTexture;
    private RTHandle m_BangsShadowDepthTexture;
    private RenderTextureDescriptor m_BangsShadowTextureDescriptor;
    private RenderTextureDescriptor m_BangsShadowDepthTextureDescriptor;
    private const string k_BangsShadowTextureName = "_BangsShadowTexture";
    private const string k_BangsShadowDepthTextureName = "_BangsShadowDepthTexture";
    
    private ShaderTagId m_ShaderTagId = new ShaderTagId("BangsShadow");
    private FilteringSettings m_FilteringSettings;
    
    private ProfilingSampler m_ProfilingSampler = new ProfilingSampler("BangsShadow");
    
    public BangsShadowPass()
    {
        renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;
        m_FilteringSettings = new FilteringSettings(RenderQueueRange.all);
        m_BangsShadowID = Shader.PropertyToID(k_BangsShadowTextureName);
    }

    public void Dispose()
    {
        m_BangsShadowTexture?.Release();
        m_BangsShadowDepthTexture?.Release();
    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        CameraData cameraData = renderingData.cameraData;
        m_BangsShadowTextureDescriptor = cameraData.cameraTargetDescriptor;
        m_BangsShadowTextureDescriptor.msaaSamples = 1;
        m_BangsShadowTextureDescriptor.graphicsFormat = GraphicsFormat.R8_UNorm;
        m_BangsShadowTextureDescriptor.depthStencilFormat = GraphicsFormat.None;
        RenderingUtils.ReAllocateIfNeeded(ref m_BangsShadowTexture, m_BangsShadowTextureDescriptor, FilterMode.Bilinear, TextureWrapMode.Clamp, name: k_BangsShadowTextureName);

        m_BangsShadowDepthTextureDescriptor = cameraData.cameraTargetDescriptor;
        m_BangsShadowDepthTextureDescriptor.msaaSamples = 1;
        m_BangsShadowDepthTextureDescriptor.graphicsFormat = GraphicsFormat.None;
        m_BangsShadowDepthTextureDescriptor.depthStencilFormat = GraphicsFormat.D16_UNorm;
        RenderingUtils.ReAllocateIfNeeded(ref m_BangsShadowDepthTexture, m_BangsShadowDepthTextureDescriptor, FilterMode.Point, TextureWrapMode.Clamp, name: k_BangsShadowDepthTextureName);
        
        ConfigureTarget(m_BangsShadowTexture, m_BangsShadowDepthTexture);
        //ConfigureTarget(m_BangsShadowTexture);
        ConfigureClear(ClearFlag.All, Color.clear);
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
            cmd.SetGlobalTexture(m_BangsShadowID, m_BangsShadowTexture);
        }
        
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }
}