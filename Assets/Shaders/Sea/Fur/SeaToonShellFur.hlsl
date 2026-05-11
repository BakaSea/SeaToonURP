#ifndef SEA_TOON_SHELL_FUR_INCLUDED
#define SEA_TOON_SHELL_FUR_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#include "../SeaToonCore.hlsl"
#include "../SeaToonLitInput.hlsl"

// 由ShellFurPass每次迭代通过SetGlobalInteger设置的当前层索引
int _ShellIndex;

TEXTURE2D(_FurNoiseMap);    SAMPLER(sampler_FurNoiseMap);

// 每个材质独立的参数，不同材质可以有不同的层数和间距
CBUFFER_START(ShellFurPerMaterial)
    int _ShellCount;        // 该材质的Shell层数
    float _ShellDistance;   // 相邻Shell层之间的距离
    float4 _FurNoiseMap_ST;
    half4 _FurColor;
    half4 _FurRampColor;
    half _FurDensity;       // 噪声图采样密度，越大毛发越细密
    half _FurThickness;     // 毛发粗细基准值
    half _FurOcclusionPower;
    half3 _FurGravity;      // 毛发弯曲方向和强度
CBUFFER_END

struct FurAttributes
{
    float3 positionOS       : POSITION;
    half3 normalOS          : NORMAL;
    half4 tangentOS         : TANGENT;
    float2 uv              : TEXCOORD0;
    float2 staticLightmapUV : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct FurVaryings
{
    float2 uv              : TEXCOORD0;
    float3 positionWS      : TEXCOORD1;
    float3 normalWS        : TEXCOORD2;
    float4 shadowCoord     : TEXCOORD3;
    half fogFactor         : TEXCOORD4;
    half shellLayer        : TEXCOORD5;  // 归一化后的层位置 [0,1]
    DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 6);
    float4 positionCS      : SV_POSITION;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

// 将当前Shell索引归一化到[0,1]，0为根部，1为尖端
half ShellLayer()
{
    return (half)_ShellIndex / max((half)(_ShellCount - 1), 1.0);
}

// 计算当前Shell层顶点沿法线方向的偏移
// layer^2的弯曲因子使毛发尖端弯曲更大，模拟重力下的自然下垂
float3 ShellOffset(half3 normalOS, half layer)
{
    // 沿法线方向均匀拉伸
    float3 offset = normalOS * _ShellDistance * _ShellCount * layer;
    // 重力弯曲：使用layer^2曲线，越靠近尖端弯曲越明显
    float3 gravityOS = TransformWorldToObjectNormal(normalize(_FurGravity));
    half bendFactor = layer * layer;
    offset += gravityOS * length(_FurGravity) * bendFactor * _ShellDistance * _ShellCount;
    return offset;
}

FurVaryings ShellFurVertex(FurAttributes input)
{
    FurVaryings output = (FurVaryings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    half layer = ShellLayer();
    output.shellLayer = layer;

    // 将顶点沿法线方向偏移，生成当前Shell层的几何体
    float3 positionOS = input.positionOS + ShellOffset(input.normalOS, layer);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    output.positionWS = vertexInput.positionWS;
    output.normalWS = normalInput.normalWS;
    output.positionCS = vertexInput.positionCS;
    output.fogFactor = ComputeFogFactor(output.positionCS.z);
    output.shadowCoord = GetShadowCoord(vertexInput);

    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    return output;
}

half4 ShellFurFragment(FurVaryings input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    // 当全局迭代索引超出该材质的层数时，丢弃像素
    // 这样不同材质可以有不同的_ShellCount，Pass只需按最大层数迭代
    if (_ShellIndex >= _ShellCount)
        discard;

    half layer = input.shellLayer;

    // 用噪声图控制毛发分布，_FurDensity决定采样频率（即毛发粗细密度）
    float2 furUV = input.uv * _FurDensity;
    half noise = SAMPLE_TEXTURE2D(_FurNoiseMap, sampler_FurNoiseMap, furUV).r;

    // 毛发逐层变细：(1-layer)^2 使得根部粗、尖端细，曲线柔和自然
    half thinning = 1.0 - layer;
    thinning = thinning * thinning;
    half threshold = _FurThickness * thinning;

    // 噪声值低于阈值的像素被丢弃，形成毛发间的缝隙
    // 第0层（根部）保留完整表面作为底色
    if (_ShellIndex > 0 && noise < threshold)
        discard;

    half3 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).rgb * _FurColor.rgb;

    // AO遮蔽：根部较暗，尖端较亮，模拟毛发内部光线衰减
    // 第0层不施加遮蔽（它是实体表面）
    half occlusion = pow(saturate(layer), _FurOcclusionPower);
    occlusion = lerp(1.0, occlusion, step(1, _ShellIndex));

    half3 normalWS = NormalizeNormalPerPixel(input.normalWS);
    half3 bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, normalWS);

    Light mainLight = GetMainLight(input.shadowCoord);
    half3 L = mainLight.direction;
    half NoL = dot(normalWS, L);
    half shadowMask = smoothstep(SHADOW_MIN_THRESHOLD, SHADOW_MAX_THRESHOLD, NoL) * mainLight.shadowAttenuation;

    half3 diffuse = ToonDiffuse(albedo, _FurRampColor.rgb, shadowMask);
    half3 color = diffuse * mainLight.color * mainLight.distanceAttenuation;
    color += albedo * bakedGI;
    color *= occlusion;

    color = MixFog(color, input.fogFactor);

    // 使用smoothstep让毛发边缘柔和过渡，避免硬边
    half alpha = (_ShellIndex == 0) ? 1.0 : smoothstep(0.0, threshold, noise);

    return half4(color, alpha);
}

#endif
