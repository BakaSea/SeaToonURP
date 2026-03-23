using UnityEngine.Rendering.Universal;

public class EyeBrowMaskRendererFeature : ScriptableRendererFeature
{
    EyeBrowMaskPass m_EyeBrowMaskPass;
    
    public override void Create()
    {
        m_EyeBrowMaskPass = new EyeBrowMaskPass();
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_EyeBrowMaskPass);
    }

    protected override void Dispose(bool disposing)
    {
        m_EyeBrowMaskPass?.Dispose();
        m_EyeBrowMaskPass = null;
    }
}