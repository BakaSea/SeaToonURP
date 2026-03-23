namespace UnityEngine.Rendering.Universal.Internal
{
    /// <summary>
    /// Renders a shadow map for the main Light.
    /// </summary>
    public class MainLightShadowCasterPass : MainLightShadowCasterPassBase
    {
        protected override string k_MainLightShadowMapTextureName => "_MainLightShadowmapTexture";
        protected override string k_EmptyMainLightShadowMapTextureName => "_EmptyMainLightShadowmapTexture";
        protected override ProfilingSampler m_ProfilingSetupSampler => new ProfilingSampler("Setup Main Shadowmap");
        internal override URPProfileId m_MainLightProfileId => URPProfileId.MainLightShadow;
        public MainLightShadowCasterPass(RenderPassEvent evt) : base(evt)
        {
        }

        protected override void RenderMainLightCascadeShadowmap(ref ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = renderingData.commandBuffer;
            using (new ProfilingScope(cmd, ProfilingSampler.Get(URPProfileId.MainLightShadow)))
            {
                CoreUtils.SetKeyword(cmd, ShaderKeywordStrings.MainLightNoToonShadows, false);
            }
            base.RenderMainLightCascadeShadowmap(ref context, ref renderingData);
        }
    };
}
