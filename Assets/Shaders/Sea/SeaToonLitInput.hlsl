#ifndef SEA_TOON_LIT_INPUT_INCLUDED
#define SEA_TOON_LIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

struct ToonSurfaceData
{
    half3 albedo;
    half3 rampColor;
    half alpha;
    half3 emission;
    half occlusion;
    half3 normalTS;
    half rimLightIntensity;
#if defined(METALLIC_MAT) || defined(SKIN_MAT)
    half metallic;
    half3 specular;
    half smoothness;
#endif
#if defined(FACE_MAT)
    half4 faceSDF;
    half4 flipFaceSDF;
#endif
#if defined(HAIR_MAT)
    half4 hairMask;
    float2 hairUV;
    half smoothness;
    half specularShift;
    half specularWidth;
    half bangsAlpha;
#endif
#if defined(SILK_MAT) || defined(SHELL_FUR_MAT) || defined(FUR_CONTOUR_MAT)
    half3 specularColor;
    half smoothness;
    half anisotropy;
#endif
#if defined(COTTON_MAT)
    half3 specularColor;
    half smoothness;
#endif
};

struct ToonInputData
{
    float3 positionWS;
    float4 positionCS;
    half3 normalWS;
    half3 tangentWS;
    half3 bitangentWS;
    half3 viewDirWS;
    float4 shadowCoord;
    half fogCoord;
    float2 normalizedScreenSpaceUV;
    half4 shadowMask;
    float2 rimUV;
#if defined(HAIR_MAT)
    half3 upwardWS;
#endif
#if defined(FACE_MAT)
    half3 forwardWS;
    half3 upwardWS;
    half3 rightWS;
    float2 bangsShadowCoord;
#endif
    half3x3 tangentToWorld;
};

TEXTURE2D(_NormalMap);          SAMPLER(sampler_NormalMap);
TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);

#if defined(METALLIC_MAT) || defined(SKIN_MAT) || defined(SHELL_FUR_MAT) || defined(FUR_CONTOUR_MAT)
TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
#endif

#if defined(FACE_MAT)
TEXTURE2D(_FaceSDF);            SAMPLER(sampler_FaceSDF);
#endif

#if defined(HAIR_MAT)
TEXTURE2D(_HairMaskMap);        SAMPLER(sampler_HairMaskMap);
TEXTURE2D(_HairUVMap);          SAMPLER(sampler_HairUVMap);
TEXTURE2D(_HairNoiseMap);       SAMPLER(sampler_HairNoiseMap);
#endif

#if defined(SHELL_FUR_MAT)
int _ShellIndex;
TEXTURE2D(_FurNoiseMap);        SAMPLER(sampler_FurNoiseMap);
#endif

#if defined(_THREADMAP_ON)
TEXTURE2D(_ThreadMap);          SAMPLER(sampler_ThreadMap);
#endif

float3 _LightDirection;
float3 _LightPosition;
TEXTURE2D(_BangsShadowTexture); SAMPLER(sampler_BangsShadowTexture);
TEXTURE2D(_EyeBrowMaskTexture); SAMPLER(sampler_EyeBrowMaskTexture);

CBUFFER_START(UnityPerMaterial)

float4 _BaseMap_ST;
half4 _BaseColor;

half4 _RampColor;

half _Cutoff;

half _BumpScale;

half4 _EmissionColor;

half _OcclusionStrength;

half _OutlineWidth;
half4 _OutlineColor;

half _RimLightWidth;
half _RimLightIntensity;

#if defined(METALLIC_MAT) || defined(SKIN_MAT)
half _Smoothness;
half _Metallic;
#endif

#if defined(HAIR_MAT)
half _SpecularIntensity;
half _SpecularShift;
half _SpecularWidth;
half _HairNoiseStrength;
half _BangsAlpha;
#endif

#if defined(SILK_MAT) || defined(SHELL_FUR_MAT) || defined(FUR_CONTOUR_MAT)
half4 _SpecularColor;
half _Smoothness;
half _Anisotropy;
#endif

#if defined(COTTON_MAT)
half4 _SpecularColor;
half _Smoothness;
#endif

#if defined(SHELL_FUR_MAT)
int _ShellCount;        // 该材质的Shell层数
float _ShellDistance;   // 相邻Shell层之间的距离
half _FurDensity;       // 噪声图采样密度，控制毛发疏密
half4 _FurUVOffset;
half _FurOcclusionPower;
#endif

//#if defined(_THREADMAP_ON)
float4 _ThreadMap_ST;
half _ThreadAOStrength;
half _ThreadNormalStrength;
half _ThreadSmoothnessScale;
//#endif

CBUFFER_END

void AlphaClip(float2 uv)
{
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    AlphaDiscard(albedoAlpha.a, _Cutoff);
}



#endif
