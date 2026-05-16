#ifndef SEA_TOON_SILK_INCLUDED
#define SEA_TOON_SILK_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#include "../SeaToonLitInput.hlsl"

half3 ShadeBSDF(ToonInputData inputData, ToonSurfaceData surfaceData, half shadowMask, Light light)
{
    half3 Li = 0.0;

    half3 N = inputData.normalWS;
    half3 L = light.direction;
    half3 V = inputData.viewDirWS;
    half3 H = SafeNormalize(V+L);
    half3 T = inputData.tangentWS;
    half3 B = inputData.bitangentWS;
    
    half3 albedo = surfaceData.albedo;
    half3 specularColor = surfaceData.specularColor*albedo;
    half smoothness = surfaceData.smoothness;
    half anisotropy = surfaceData.anisotropy;
    half perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
    half roughnessT = 0, roughnessB = 0;
    ConvertAnisotropyToClampRoughness(perceptualRoughness, anisotropy, roughnessT, roughnessB);
    
    // Diffuse
    half3 brdfDiffuse = ToonDiffuse(albedo, surfaceData.rampColor, shadowMask);
    Li += brdfDiffuse*light.color*light.distanceAttenuation;

    // Specular
    half TdotH = dot(T, H);
    half TdotL = dot(T, L);
    half TdotV = dot(T, V);
    half BdotH = dot(B, H);
    half BdotL = dot(B, L);
    half BdotV = dot(B, V);
    half NdotH = saturate(dot(N, H));
    half NdotL = dot(N, L);
    half clampedNdotL = saturate(NdotL);
    half clampedNdotV = ClampNdotV(dot(N, V));
    half VdotH = saturate(dot(V, H));
    
    half3 F = F_Schlick(specularColor, VdotH);
    half DV = PI*DV_SmithJointGGXAniso(TdotH, BdotH, NdotH, TdotV, BdotV, clampedNdotV, TdotL, BdotL, abs(NdotL), roughnessT, roughnessB);
    
    Li += F*DV*clampedNdotL*light.color*light.distanceAttenuation*shadowMask;
    
    return Li;
}

half3 ShadeBSDFGI(ToonInputData inputData, ToonSurfaceData surfaceData, half shadowMask)
{
    half3 Li = 0.0;
    
    half3 albedo = surfaceData.albedo;

    half3 LiSH0 = SampleGISH0();
    half3 brdfDiffuse = ToonDiffuse(albedo, surfaceData.rampColor, shadowMask);
    Li += brdfDiffuse*LiSH0;
    
    return Li;
}

half GetBSDFAlpha(ToonInputData inputData, ToonSurfaceData surfaceData)
{
    return 1.0;
}

#endif
