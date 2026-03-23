
using UnityEngine.Rendering.Universal;

public class OutlineRendererFeature : ScriptableRendererFeature
{
    OutlinePass m_OutlinePass;
    
    public override void Create()
    {
        m_OutlinePass = new OutlinePass();
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_OutlinePass);
    }

    protected override void Dispose(bool disposing)
    {
        m_OutlinePass = null;
    }
    
}