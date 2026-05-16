#ifndef SEA_TOON_METALLIC_INCLUDED
#define SEA_TOON_METALLIC_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#include "../SeaToonLitInput.hlsl"

half3 ShadeBSDF(ToonInputData inputData, ToonSurfaceData surfaceData, half shadowMask, Light light)
{
    half3 Li = 0.0;

    half3 N = inputData.normalWS;
    half3 L = light.direction;
    half3 V = inputData.viewDirWS;
    half3 H = SafeNormalize(V+L);
    half NdotL = saturate(dot(N, L));
    half NdotH = saturate(dot(N, H));
    half VdotH = saturate(dot(V, H));
    
    half3 albedo = surfaceData.albedo;
    half metallic = surfaceData.metallic;
    half smoothness = surfaceData.smoothness;
    //half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
    //half3 specular = lerp(kDielectricSpec.rgb, albedo, metallic);
    half perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
    half roughness = max(PerceptualRoughnessToRoughness(perceptualRoughness), HALF_MIN_SQRT);
    half roughness2 = max(roughness*roughness, HALF_MIN);
    half roughness2MinusOne = roughness2-1.0h;
    half normalizationTerm = roughness*4.0h+2.0h;

    // Diffuse
    //half3 brdfDiffuse = oneMinusReflectivity*ToonDiffuse(albedo, surfaceData.rampColor, shadowMask);
    half3 brdfDiffuse = ToonDiffuse(albedo, surfaceData.rampColor, shadowMask);
    Li += brdfDiffuse*light.color*light.distanceAttenuation;

#if !defined(FACE_MAT)
    // Specular
    float d = NdotH*NdotH*roughness2MinusOne+1.00001f;
    half VdotH2 = VdotH*VdotH;
    //half F = F_Schlick(specular, VdotH);
    half3 F = F_Schlick(albedo, VdotH);
    half3 brdfSpecular = F*roughness2/(d*d*max(0.1h, VdotH2)*normalizationTerm);
    Li += brdfSpecular*NdotL*light.color*shadowMask*light.distanceAttenuation;
#endif
    
    return Li;
}

half3 ShadeBSDFGI(ToonInputData inputData, ToonSurfaceData surfaceData, half shadowMask)
{
    half3 Li = 0.0;
    
    half3 albedo = surfaceData.albedo;

    half3 LiSH0 = SampleGISH0();
    half3 brdfDiffuse = ToonDiffuse(albedo, surfaceData.rampColor, shadowMask);
    Li += brdfDiffuse*LiSH0;

    // half3 LiSH0 = SampleSH(inputData.normalWS);
    // half3 brdfDiffuse = surfaceData.albedo;
    // Li += brdfDiffuse*LiSH0;
    
    return Li;
}

half GetBSDFAlpha(ToonInputData inputData, ToonSurfaceData surfaceData)
{
    return 1.0;
}

#endif
