#ifndef SEA_TOON_LIT_COMMON_INCLUDED
#define SEA_TOON_LIT_COMMON_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#include "SeaToonCore.hlsl"
#include "SeaToonLitInput.hlsl"
#include "SeaToonLighting.hlsl"

struct Attributes
{
    float3 positionOS           : POSITION;
    half3 normalOS              : NORMAL;
    half4 tangentOS             : TANGENT;
    float2 uv                   : TEXCOORD0;
    float2 staticLightmapUV     : TEXCOORD1;
    float2 dynamicLightmapUV    : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                   : TEXCOORD0;
    float3 positionWS           : TEXCOORD1;
    float3 normalWS             : TEXCOORD2;
    half4 tangentWS             : TEXCOORD3;
    float4 shadowCoord          : TEXCOORD4;
    half fogFactor              : TEXCOORD5;
    float2 rimUV                : TEXCOORD6;
    DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 7);
#ifdef DYNAMICLIGHTMAP_ON
    float2 dynamicLightmapUV    : TEXCOORD8; // Dynamic lightmap UVs
#endif
#if defined(HAIR_MAT)
    half3 upwardWS              : TEXCOORD9;
#endif
#if defined(FACE_MAT)
    half3 forwardWS             : TEXCOORD9;
    half3 upwardWS              : TEXCOORD10;
    float2 bangsShadowCoord     : TEXCOORD11;
#endif
#if defined(SHELL_FUR_MAT)
    half shellLayer             : TEXCOORD12;
#endif
#if defined(_THREADMAP_ON)
    float2 threadUV             : TEXCOORD13;
#endif
    float4 positionCS           : SV_POSITION;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings LitForwardVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    float3 positionOS = input.positionOS;
#if defined(SHELL_FUR_MAT)
    output.shellLayer = (half)_ShellIndex / max((half)(_ShellCount - 1), 1.0);
    positionOS = input.positionOS + input.normalOS * _ShellDistance * _ShellCount * output.shellLayer;
#endif
    
    VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS);
#if defined(_RADIAL_TANGENT)
    half3 tangent = normalize(cross(input.normalOS, half3(0, 1, 0)));
#else
    half3 tangent = input.tangentOS;
#endif
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, half4(tangent, 1));
    
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    output.positionWS = vertexInput.positionWS;
    output.normalWS = normalInput.normalWS;
    output.positionCS = vertexInput.positionCS;
    output.fogFactor = ComputeFogFactor(output.positionCS.z);

    float3 rimPositionOS = positionOS+input.normalOS;
    VertexPositionInputs rimPositions = GetVertexPositionInputs(rimPositionOS);
    float2 rimPositionNDC = rimPositions.positionNDC.xy/rimPositions.positionNDC.w;
    float2 rimPositionSS = rimPositionNDC*_ScreenParams.xy;

    float2 positionNDC = vertexInput.positionNDC.xy/vertexInput.positionNDC.w;
    float2 positionSS = positionNDC*_ScreenParams.xy;
    float2 rimDir = normalize(rimPositionSS-positionSS);
    rimPositionSS = positionSS+_RimLightWidth*RIM_LIGHT_WIDTH_SCALING_FACTOR*rimDir;
    output.rimUV = rimPositionSS/_ScreenParams.xy;
    
    output.shadowCoord = GetShadowCoord(vertexInput);
    
#if defined(_RADIAL_TANGENT)
    real sign = 1;
#else
    real sign = input.tangentOS.w*GetOddNegativeScale();
#endif
    half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
    output.tangentWS = tangentWS;

    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
#if defined(DYNAMICLIGHTMAP_ON)
    output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

#if defined(HAIR_MAT)
    output.upwardWS = TransformObjectToWorldDir(float3(0, 1, 0));
#endif
    
#if defined(FACE_MAT)
    output.forwardWS = TransformObjectToWorldDir(float3(0, 0, 1));
    output.upwardWS = TransformObjectToWorldDir(float3(0, 1, 0));
    float4 bangsShadowPositionCS = TransformWorldToHClip(output.positionWS+_LightDirection*BANGS_SHADOW_EXTEND_LENGTH);
    output.bangsShadowCoord = bangsShadowPositionCS.xy/bangsShadowPositionCS.w*0.5+0.5;
    output.bangsShadowCoord.y = 1.0-output.bangsShadowCoord.y;
#endif

#if defined(_THREADMAP_ON)
    output.threadUV = TRANSFORM_TEX(input.uv, _ThreadMap);
#endif
    
    return output;
}

ToonSurfaceData InitializeSurfaceData(Varyings input)
{
    float2 uv = input.uv;
    ToonSurfaceData output;

    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    output.albedo = albedoAlpha.rgb*_BaseColor.rgb;
    output.rampColor = _RampColor.rgb;
    output.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
    
    output.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    output.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));

    half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
    output.occlusion = LerpWhiteTo(occ, _OcclusionStrength);
    
    output.rimLightIntensity = _RimLightIntensity;

#if defined(FACE_MAT)
    output.faceSDF = SAMPLE_TEXTURE2D(_FaceSDF, sampler_FaceSDF, uv);
    output.flipFaceSDF = SAMPLE_TEXTURE2D(_FaceSDF, sampler_FaceSDF, float2(1.0-uv.x, uv.y));
#endif
    
#if defined(METALLIC_MAT) || defined(SKIN_MAT)
    half4 specGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv);
    output.metallic = _Metallic*specGloss.r;
    output.specular = 0.0;
    output.smoothness = _Smoothness*specGloss.a;
#endif
    
#if defined(HAIR_MAT)
    output.hairMask = SAMPLE_TEXTURE2D(_HairMaskMap, sampler_HairMaskMap, uv);
    output.hairUV = SAMPLE_TEXTURE2D(_HairUVMap, sampler_HairUVMap, uv).rg;
    half hairNoise = SAMPLE_TEXTURE2D(_HairNoiseMap, sampler_HairNoiseMap, float2(output.hairUV.x, 0.5)).r*2.0-1.0;
    output.specularShift = _SpecularShift+hairNoise*_HairNoiseStrength;
    output.specularWidth = _SpecularWidth;
    output.bangsAlpha = _BangsAlpha;
#endif

#if defined(SILK_MAT) || defined(SHELL_FUR_MAT) || defined(FUR_CONTOUR_MAT)
    output.specularColor = _SpecularColor.rgb;
    output.smoothness = _Smoothness;
    output.anisotropy = _Anisotropy;
#endif
    
#if defined(COTTON_MAT)
    output.specularColor = _SpecularColor.rgb;
    output.smoothness = _Smoothness;
#endif

#if defined(_THREADMAP_ON)
    half4 thread = SAMPLE_TEXTURE2D(_ThreadMap, sampler_ThreadMap, input.threadUV);
    half3 threadNormal = UnpackNormalAG(thread, _ThreadNormalStrength);
    output.normalTS = BlendNormal(output.normalTS, threadNormal);
    half threadSmoothness = thread.b*2.0h-1.0h;
    output.smoothness = saturate(output.smoothness+threadSmoothness*_ThreadSmoothnessScale);
    output.occlusion *= thread.r;
#endif
    
    return output;
}

ToonInputData InitializeInputData(Varyings input, half3 normalTS)
{
    ToonInputData output = (ToonInputData)0;

    output.positionWS = input.positionWS;
    //output.positionCS = input.positionCS.xyz/input.positionCS.w;
    output.positionCS = TransformWorldToHClip(input.positionWS);
    output.viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);

    float sgn = input.tangentWS.w;
    float3 bitangent = sgn*cross(input.normalWS.xyz, input.tangentWS.xyz);
    half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
    output.tangentToWorld = tangentToWorld;
    output.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
    output.normalWS = NormalizeNormalPerPixel(output.normalWS);
    output.tangentWS = normalize(input.tangentWS.xyz);
    output.bitangentWS = normalize(bitangent);
    
    output.shadowCoord = input.shadowCoord;
    
    output.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactor);

    output.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    output.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
    
    output.rimUV = input.rimUV;

#if defined(HAIR_MAT)
    output.upwardWS = input.upwardWS;
#endif
#if defined(FACE_MAT)
    output.forwardWS = input.forwardWS;
    output.upwardWS = input.upwardWS;
    output.rightWS = normalize(cross(input.upwardWS, input.forwardWS));
    output.bangsShadowCoord = input.bangsShadowCoord;
#endif
    
    return output;
}

half4 LitForwardFragment(Varyings input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    
#if defined(SHELL_FUR_MAT)
    // 当全局迭代索引超出该材质的层数时，丢弃像素
    // 这样不同材质可以有不同的_ShellCount，Pass只需按最大层数迭代
    if (_ShellIndex >= _ShellCount)
        discard;

    half layer = input.shellLayer;

    // 采样毛发高度图：白色(1)=毛发高度满，黑色(0)=无毛发
    float2 furUV = input.uv * _FurDensity + _FurUVOffset.xy * layer;
    half furHeight = SAMPLE_TEXTURE2D(_FurNoiseMap, sampler_FurNoiseMap, furUV).r;

    // 核心裁剪逻辑：毛发高度 < 阈值 → 毛发在此处长不到这一层，丢弃
    // 使用layer^2作为阈值曲线：根部阈值小（毛发粗），尖端阈值快速增大（毛发细）
    // 例如 layer=0.5时阈值仅0.25，大部分像素存活；layer=0.9时阈值0.81，大量像素被裁剪
    // 这样产生柔和自然的"根粗尖细"过渡
    // 第0层（根部）保留完整表面作为底色
    half threshold = layer * layer;
    if (_ShellIndex > 0 && furHeight < threshold)
        discard;
#endif
    
    ToonSurfaceData surfaceData = InitializeSurfaceData(input);
    ToonInputData inputData = InitializeInputData(input, surfaceData.normalTS);
    
#if defined(SHELL_FUR_MAT)
    surfaceData.occlusion = pow(saturate(layer), _FurOcclusionPower);
#endif
    
    half4 color = ToonShading(inputData, surfaceData);
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    
    return color;
}

#endif