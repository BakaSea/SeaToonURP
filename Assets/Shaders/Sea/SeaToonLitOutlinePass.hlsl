#ifndef SEA_TOON_LIT_OUTLINE_PASS_INCLUDED
#define SEA_TOON_LIT_OUTLINE_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

#include "SeaToonCore.hlsl"
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
    float3 positionWS           : TEXCOORD1;
    float4 positionCS           : SV_POSITION;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

float3 TransformPositionWSToOutlineWS(float3 positionWS, float3 normalWS)
{
    return positionWS+normalWS*_OutlineWidth*OUTLINE_WIDTH_SCALING_FACTOR;
}

Varyings OutlineVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
    
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    output.positionWS = TransformPositionWSToOutlineWS(vertexInput.positionWS, normalWS);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    
    return output;
}

half4 OutlineFragment(Varyings input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    AlphaClip(input.uv);
    
#if defined(HAIR_MAT)
    float4 positionCS = TransformWorldToHClip(input.positionWS);
    float2 uv = positionCS.xy/positionCS.w;
    uv = uv*0.5+0.5;
    uv.y = 1.0-uv.y;
    half mask = SAMPLE_TEXTURE2D(_EyeBrowMaskTexture, sampler_EyeBrowMaskTexture, uv).r;
    AlphaDiscard(1.0-mask, _Cutoff);
#endif
    
    return _OutlineColor;
}

#endif
