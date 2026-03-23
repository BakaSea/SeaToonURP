#ifndef SEA_TOON_LIT_SHADOW_CASTER_PASS_INCLUDED
#define SEA_TOON_LIT_SHADOW_CASTER_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#include "SeaToonLitInput.hlsl"

struct Attributes
{
    float3 positionOS           : POSITION;
    half3 normalOS              : NORMAL;
    float2 uv                   : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                   : TEXCOORD0;
    float4 shadowCoord          : TEXCOORD1;
    float4 positionCS           : SV_POSITION;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings ShadowCasterVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
    
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    
    output.shadowCoord = GetShadowCoord(vertexInput);
    
#if _CASTING_PUNCTUAL_LIGHT_SHADOW
    float3 lightDirectionWS = normalize(_LightPosition - vertexInput.positionWS);
#else
    float3 lightDirectionWS = _LightDirection;
#endif
    output.positionCS = TransformWorldToHClip(ApplyShadowBias(vertexInput.positionWS, normalWS, lightDirectionWS));
#if UNITY_REVERSED_Z
    output.positionCS.z = min(output.positionCS.z, UNITY_NEAR_CLIP_VALUE);
#else
    output.positionCS.z = max(output.positionCS.z, UNITY_NEAR_CLIP_VALUE);
#endif
    
    return output;
}

half4 ShadowCasterFragment(Varyings input) : SV_TARGET
{
    #if defined(_MAIN_LIGHT_NO_TOON_SHADOWS)
    discard;
    #endif
    AlphaClip(input.uv);
    return 0;
}

#endif
