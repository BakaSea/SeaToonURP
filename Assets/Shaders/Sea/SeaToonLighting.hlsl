#ifndef SEA_TOON_LIGHTING_INCLUDED
#define SEA_TOON_LIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

#include "SeaToonLitInput.hlsl"

#if defined(METALLIC_MAT)
#include "Metallic/SeaToonMetallic.hlsl"
#elif defined(SKIN_MAT)
#include "Skin/SeaToonSkin.hlsl"
#elif defined(HAIR_MAT)
#include "Hair/SeaToonHair.hlsl"
#elif defined(SILK_MAT) || defined(FUR_CONTOUR_MAT)
#include "Fabric/SeaToonSilk.hlsl"
#elif defined(COTTON_MAT)
#include "Fabric/SeaToonCotton.hlsl"
#elif defined(SHELL_FUR_MAT)
#include "Fur/SeaToonShellFur.hlsl"
#endif

struct ShadowLightResult
{
    half3 Li;
    half shadowMask;
};

half4 CalculateShadowMask(ToonInputData inputData)
{    // To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
#if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
    half4 shadowMask = inputData.shadowMask;
#elif !defined (LIGHTMAP_ON)
    half4 shadowMask = unity_ProbesOcclusion;
#else
    half4 shadowMask = half4(1, 1, 1, 1);
#endif

    return shadowMask;
}

half CalculateRimMask(ToonInputData inputData)
{
    float2 uv = inputData.positionCS.xy/inputData.positionCS.w;
    uv = uv*0.5+0.5;
    uv.y = 1.0-uv.y;
    half depth = LinearEyeDepth(SampleSceneDepth(uv), _ZBufferParams);
    half rimDepth = LinearEyeDepth(SampleSceneDepth(inputData.rimUV), _ZBufferParams);
    return smoothstep(RIM_LIGHT_DEPTH_DIFF_MIN_THRESHOLD, RIM_LIGHT_DEPTH_DIFF_MAX_THRESHOLD, abs(depth-rimDepth));
}

half CalculateFaceShadow(half4 faceSDF, half4 flipFaceSDF, half3 F, half3 U, half3 R, half3 L, float2 bangsShadowCoord)
{
    L = normalize(L-U*dot(U, L));
    half lightSDF = -dot(L, F)*0.5+0.5;
    half4 sdf = lerp(faceSDF, flipFaceSDF, sign(dot(L, R))*0.5+0.5);
    half sdfShadow = smoothstep(SHADOW_MIN_THRESHOLD, SHADOW_MAX_THRESHOLD, sdf.b-lightSDF)*smoothstep(SHADOW_MIN_THRESHOLD, SHADOW_MAX_THRESHOLD, sdf.r-lightSDF);
    half bangsShadow = 1.0-SAMPLE_TEXTURE2D(_BangsShadowTexture, sampler_BangsShadowTexture, bangsShadowCoord).r;
    return sdfShadow*bangsShadow;
}

half3 ShadeRimLight(ToonInputData inputData, ToonSurfaceData surfaceData, half shadowMask, half rimMask, Light light)
{
    half3 L = light.direction;
    half3 V = inputData.viewDirWS;
    half3 H = normalize(L+V);
    half VoH = dot(V, H);
    half fresnel = F_Schlick(0.0, VoH);
    //fresnel = smoothstep(RIM_LIGHT_FRESNEL_MIN_THRESHOLD, RIM_LIGHT_FRESNEL_MAX_THRESHOLD, fresnel);
    return light.color*light.distanceAttenuation*fresnel*rimMask*shadowMask*surfaceData.rimLightIntensity;
}

ShadowLightResult ShadeShadowLight(ToonInputData inputData, ToonSurfaceData surfaceData, AmbientOcclusionFactor aoFactor, half rimMask, Light light)
{
    ShadowLightResult result = (ShadowLightResult)0;
    
    half3 N = inputData.normalWS;
    half3 L = light.direction;
    half NoL = dot(N,L);

#if defined(FACE_MAT)
    result.shadowMask = CalculateFaceShadow(surfaceData.faceSDF, surfaceData.flipFaceSDF, inputData.forwardWS, inputData.upwardWS, inputData.rightWS, L, inputData.bangsShadowCoord)
        *light.shadowAttenuation*aoFactor.directAmbientOcclusion;
#elif defined(HAIR_MAT)
    half hairShadowMask = 1.0-surfaceData.hairMask.g;
    result.shadowMask = (NoL*0.5+0.5)*light.shadowAttenuation;
    result.shadowMask = smoothstep(HAIR_SHADOW_MASK_MIN_THRESHOLD, HAIR_SHADOW_MASK_MAX_THRESHOLD, result.shadowMask-hairShadowMask);
#else
    result.shadowMask = smoothstep(SHADOW_MIN_THRESHOLD, SHADOW_MAX_THRESHOLD, NoL)*light.shadowAttenuation*aoFactor.directAmbientOcclusion;
#endif
    
    result.Li = surfaceData.emission;
    result.Li += ShadeBSDF(inputData, surfaceData, result.shadowMask, light);
    result.Li += ShadeRimLight(inputData, surfaceData, result.shadowMask, rimMask, light);
    
    return result;
}

half3 ShadeAdditionalLight(ToonInputData inputData, ToonSurfaceData surfaceData, half shadowMask, half rimMask, Light light)
{
    half3 Li = 0.0;
    Li += ShadeBSDF(inputData, surfaceData, shadowMask, light);
    Li += ShadeRimLight(inputData, surfaceData, shadowMask, rimMask, light);
    return Li;
}

half3 ShadeGI(ToonInputData inputData, ToonSurfaceData surfaceData, AmbientOcclusionFactor aoFactor, half shadowMask)
{
    half3 Li = 0.0;
    
    half3 reflectVector = reflect(-inputData.viewDirWS, inputData.normalWS);
    half NoV = saturate(dot(inputData.normalWS, inputData.viewDirWS));
    half fresnelTerm = Pow4(1.0 - NoV);
    
    Li += surfaceData.albedo*inputData.bakedGI;
// #if defined(METALLIC_MAT)
//     half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, inputData.positionWS, brdfData.perceptualRoughness, 1.0h, inputData.normalizedScreenSpaceUV);
//     Li += indirectSpecular*EnvironmentBRDFSpecular(brdfData, fresnelTerm)*shadowMask;
// #endif
    
    return Li*aoFactor.indirectAmbientOcclusion;
}

half4 ToonShading(ToonInputData inputData, ToonSurfaceData surfaceData)
{
    half3 Li = 0.0;

    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData.normalizedScreenSpaceUV, surfaceData.occlusion);
    half rimMask = CalculateRimMask(inputData);
    
    Light mainLight = GetMainLightNoToon(inputData.shadowCoord, inputData.positionWS, shadowMask);
    #if defined(_SCREEN_SPACE_OCCLUSION) && !defined(_SURFACE_TYPE_TRANSPARENT)
    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_AMBIENT_OCCLUSION))
    {
        mainLight.color *= aoFactor.directAmbientOcclusion;
    }
    #endif
    
    ShadowLightResult shadowLightResult = ShadeShadowLight(inputData, surfaceData, aoFactor, rimMask, mainLight);
    Li += shadowLightResult.Li;
    
    Li += ShadeGI(inputData, surfaceData, aoFactor, shadowLightResult.shadowMask);
    
    uint pixelLightCount = GetAdditionalLightsCount();
    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
        int i = GetPerObjectLightIndex(lightIndex);
        light.shadowAttenuation = AdditionalLightRealtimeShadow(i, inputData.positionWS, light.direction);
        Li += ShadeAdditionalLight(inputData, surfaceData, shadowLightResult.shadowMask, rimMask, light);
    LIGHT_LOOP_END
    
    half alpha = GetBSDFAlpha(inputData, surfaceData);
    
    return half4(Li, alpha);
}

#endif
