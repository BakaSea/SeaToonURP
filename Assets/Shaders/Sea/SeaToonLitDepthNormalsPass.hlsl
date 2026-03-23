#ifndef SEA_TOON_LIT_DEPTH_NORMALS_PASS_INCLUDED
#define SEA_TOON_LIT_DEPTH_NORMALS_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

#include "SeaToonLitInput.hlsl"

struct Attributes
{
    float3 positionOS           : POSITION;
    half3 normalOS              : NORMAL;
    half4 tangentOS             : TANGENT;
    float2 uv                   : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                   : TEXCOORD0;
    float3 positionWS           : TEXCOORD1;
    float3 normalWS             : TEXCOORD2;
    half4 tangentWS             : TEXCOORD3;
    float4 positionCS           : SV_POSITION;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings DepthNormalVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    output.positionWS = vertexInput.positionWS;
    output.normalWS = normalInput.normalWS;
    
    real sign = input.tangentOS.w*GetOddNegativeScale();
    half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
    output.tangentWS = tangentWS;

    output.positionCS = TransformWorldToHClip(output.positionWS);

    return output;
}

void DepthNormalsFragment(Varyings input,
    out half4 outNormalWS: SV_Target0)
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    AlphaClip(input.uv);
    
    half3 normalTS = SampleNormal(input.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    float sgn = input.tangentWS.w;
    float3 bitangent = sgn*cross(input.normalWS.xyz, input.tangentWS.xyz);
    half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
    half3 normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
    normalWS = NormalizeNormalPerPixel(normalWS);
    outNormalWS = half4(normalWS, 0.0);
}

#endif
