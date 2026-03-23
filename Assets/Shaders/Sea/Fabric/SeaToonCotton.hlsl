#ifndef SEA_TOON_COTTON_INCLUDED
#define SEA_TOON_COTTON_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#include "../SeaToonLitInput.hlsl"

half3 ShadeBSDF(ToonInputData inputData, ToonSurfaceData surfaceData, half shadowMask, Light light)
{
    half3 Li = 0.0;

    half3 N = inputData.normalWS;
    half3 L = light.direction;
    half3 V = inputData.viewDirWS;
    half3 H = SafeNormalize(V+L);
    
    half3 albedo = surfaceData.albedo;
    half3 specularColor = surfaceData.specularColor*albedo;
    half smoothness = surfaceData.smoothness;
    half perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
    half roughness = ClampRoughnessForAnalyticalLights(PerceptualRoughnessToRoughness(perceptualRoughness));
    
    // Diffuse
    half3 brdfDiffuse = ToonDiffuse(albedo, surfaceData.rampColor, shadowMask)*FabricLambertNoPI(roughness);
    Li += brdfDiffuse*light.color*light.distanceAttenuation;

    // Specular
    half NdotH = saturate(dot(N, H));
    half NdotL = dot(N, L);
    half clampedNdotL = saturate(NdotL);
    half clampedNdotV = ClampNdotV(dot(N, V));
    half VdotH = saturate(dot(V, H));
    
    half3 F = F_Schlick(specularColor, VdotH);
    half D = D_CharlieNoPI(NdotH, roughness);
    half Vis = V_Ashikhmin(NdotL, clampedNdotV);
    
    Li += F*D*Vis*clampedNdotL*light.color*light.distanceAttenuation*shadowMask;
    
    return Li;
}

half GetBSDFAlpha(ToonInputData inputData, ToonSurfaceData surfaceData)
{
    return 1.0;
}

#endif
