using UnityEngine;
using UnityEngine.Rendering.Universal;

public class ShellFurRendererFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        // 全局最大迭代层数，Pass会迭代这么多次
        // 每个材质通过自身的_ShellCount控制实际使用的层数（超出部分会被shader discard）
        [Range(1, 64)]
        public int maxShellCount = 64;
    }

    public Settings settings = new Settings();
    ShellFurPass m_ShellFurPass;

    public override void Create()
    {
        m_ShellFurPass = new ShellFurPass(settings.maxShellCount);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_ShellFurPass.Setup(settings.maxShellCount);
        renderer.EnqueuePass(m_ShellFurPass);
    }

    protected override void Dispose(bool disposing)
    {
        m_ShellFurPass = null;
    }
}
