namespace UnityEngine.Rendering.Universal.Internal
{
    public class MainLightNoToonShadowCasterPass : MainLightShadowCasterPassBase
    {
        protected override string k_MainLightShadowMapTextureName => "_MainLightNoToonShadowmapTexture";
        protected override string k_EmptyMainLightShadowMapTextureName => "_EmptyMainLightNoToonShadowmapTexture";
        protected override ProfilingSampler m_ProfilingSetupSampler => new ProfilingSampler("Setup Main No Toon Shadowmap");
        internal override URPProfileId m_MainLightProfileId => URPProfileId.MainLightNoToonShadow;

        public MainLightNoToonShadowCasterPass(RenderPassEvent evt) : base(evt)
        {
        }

        protected override void RenderMainLightCascadeShadowmap(ref ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = renderingData.commandBuffer;
            using (new ProfilingScope(cmd, ProfilingSampler.Get(URPProfileId.MainLightNoToonShadow)))
            {
                CoreUtils.SetKeyword(cmd, ShaderKeywordStrings.MainLightNoToonShadows, true);
            }
            base.RenderMainLightCascadeShadowmap(ref context, ref renderingData);
        }
    }
}