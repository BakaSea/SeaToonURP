#ifndef SEA_TOON_HAIR_INCLUDED
#define SEA_TOON_HAIR_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#include "../SeaToonLitInput.hlsl"

half RoughnessToBlinnPhongSpecularExponent(half roughness)
{
    return clamp(2 * rcp(max(roughness * roughness, FLT_EPS)) - 2, FLT_EPS, rcp(FLT_EPS));
}

half3 ShadeBSDF(ToonInputData inputData, ToonSurfaceData surfaceData, half shadowMask, Light light)
{
    half3 Li = 0.0;
    
    half3 albedo = surfaceData.albedo;
    
    // Diffuse
    half3 brdfDiffuse = ToonDiffuse(albedo, surfaceData.rampColor, shadowMask);
    Li += brdfDiffuse*light.color*light.distanceAttenuation;
    
    // Specular
    half3 V = inputData.viewDirWS;
    half3 U = inputData.upwardWS;
    half UdotV = clamp(dot(U, V)*0.5+0.5+surfaceData.specularShift, 0, 0.85);
    half3 specular = _SpecularIntensity*smoothstep(-0.5*_SpecularWidth, 0.0, UdotV-surfaceData.hairUV.y)
        *smoothstep(-0.5*_SpecularWidth, 0.0, surfaceData.hairUV.y-UdotV)*surfaceData.hairMask.r;
    half3 brdfSpecular = ToonDiffuse(specular, surfaceData.rampColor, shadowMask);
    Li += brdfSpecular*light.color*light.distanceAttenuation;
    
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
    float2 uv = inputData.positionCS.xy/inputData.positionCS.w;
    uv = uv*0.5+0.5;
    uv.y = 1.0-uv.y;
    half mask = SAMPLE_TEXTURE2D(_EyeBrowMaskTexture, sampler_EyeBrowMaskTexture, uv).r;
    return lerp(1.0, surfaceData.bangsAlpha, mask);
}

#endif