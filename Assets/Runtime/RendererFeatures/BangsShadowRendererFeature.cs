using UnityEngine;
using UnityEngine.Rendering.Universal;

public class BangsShadowRendererFeature : ScriptableRendererFeature
{
    BangsShadowPass m_BangsShadowPass;
    
    public override void Create()
    {
        m_BangsShadowPass = new BangsShadowPass();
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_BangsShadowPass);
    }

    protected override void Dispose(bool disposing)
    {
        m_BangsShadowPass?.Dispose();
        m_BangsShadowPass = null;
    }
}