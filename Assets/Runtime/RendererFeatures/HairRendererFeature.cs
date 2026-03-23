using UnityEngine.Rendering.Universal;

public class HairRendererFeature : ScriptableRendererFeature
{
    HairPass m_HairPass;
    
    public override void Create()
    {
        m_HairPass = new HairPass();
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_HairPass);
    }

    protected override void Dispose(bool disposing)
    {
        m_HairPass = null;
    }
    
}