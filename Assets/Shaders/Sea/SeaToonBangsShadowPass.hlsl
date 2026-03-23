#ifndef SEA_TOON_HAIR_BANGS_SHADOW_PASS_INCLUDED
#define SEA_TOON_HAIR_BANGS_SHADOW_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

#include "SeaToonLitInput.hlsl"

struct Attributes
{
    float3 positionOS   : POSITION;
    float2 uv           : TEXCOORD0;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv           : TEXCOORD0;
    float4 positionCS   : SV_POSITION;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings BangsShadowVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    output.positionCS = TransformObjectToHClip(input.positionOS);
    
    return output;
}

half BangsShadowFragment(Varyings input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    AlphaClip(input.uv);

#if defined(_FRONT_HAIR)
    return 1;
#else
    return 0;
#endif
}

#endif
