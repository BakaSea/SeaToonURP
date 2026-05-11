Shader "SeaToon/SeaToonShellFur"
{
    Properties
    {
        [Header(Base Color)]
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [HDR][MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)

        [Header(Shell)]
        // 每个材质独立的层数和间距参数
        _ShellCount("Shell Count", Integer) = 32
        _ShellDistance("Shell Distance", Float) = 0.005

        [Header(Fur)]
        // 毛发高度图：白色=有毛发(高度满)，黑色=无毛发
        _FurNoiseMap("Fur Height Map", 2D) = "white" {}
        _FurColor("Fur Color", Color) = (1, 1, 1, 1)
        _FurDensity("Fur Density", Range(1.0, 100.0)) = 30.0
        _FurOcclusionPower("Fur Occlusion Power", Range(0.0, 5.0)) = 1.5

        [Header(Ramp)]
        _RampColor("Ramp Color", Color) = (0.6117647, 0.6117647, 0.6274511, 1)
        _FurRampColor("Fur Ramp Color", Color) = (0.6117647, 0.6117647, 0.6274511, 1)

        [Header(Alpha Clipping)]
        [Toggle(_ALPHATEST_ON)] _ALPHATEST_ON("Enable", Float) = 0
        _Cutoff("Cutoff", Range(0.0, 1.0)) = 0.5

        [Header(Normal)]
        _BumpScale("Bump Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}

        [Header(Emission)]
        [HDR] _EmissionColor("Emission Color", Color) = (0, 0, 0)
        _EmissionMap("Emission Map", 2D) = "white" {}

        [Header(Occlusion)]
        _OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap("Occlusion Map", 2D) = "white" {}

        [Header(Outline)]
        _OutlineWidth("Outline Width", Range(0.0, 1.0)) = 0.1
        _OutlineColor("Outline Color", Color) = (0, 0, 0, 1)

        [Header(Rim Light)]
        _RimLightWidth("Rim Light Width", Range(0.0, 1.0)) = 0.2
        _RimLightIntensity("Rim Light Intensity", Range(0.0, 10.0)) = 5.0
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "Queue" = "Geometry"
        }
        LOD 100

        HLSLINCLUDE

        #pragma shader_feature_local_fragment _ALPHATEST_ON

        ENDHLSL

        // Shell Fur主Pass：由ShellFurPass逐层迭代绘制
        // LightMode = "ShellFur" 对应Pass中的ShaderTagId
        Pass
        {
            Name "ShellFur"
            Tags
            {
                "LightMode" = "ShellFur"
            }

            // 半透明混合，因为外层Shell的毛发间有空隙需要透过下层
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On
            Cull Back
            ZTest LEqual

            HLSLPROGRAM

            #pragma vertex ShellFurVertex
            #pragma fragment ShellFurFragment

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #pragma multi_compile_instancing

            #include "SeaToonShellFur.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "Outline"
            Tags
            {
                "LightMode" = "Outline"
            }

            Blend One Zero
            ZWrite On
            Cull Front
            ZTest LEqual

            HLSLPROGRAM

            #pragma vertex OutlineVertex
            #pragma fragment OutlineFragment

            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #pragma multi_compile_instancing

            #include "../SeaToonLitOutlinePass.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Off

            HLSLPROGRAM

            #pragma vertex ShadowCasterVertex
            #pragma fragment ShadowCasterFragment

            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #pragma multi_compile_instancing

            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #include "../SeaToonLitShadowCasterPass.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            ZWrite On
            ZTest LEqual
            ColorMask R
            Cull Off

            HLSLPROGRAM

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            ZWrite On
            ZTest LEqual
            ColorMask RGBA
            Cull Off

            HLSLPROGRAM

            #pragma vertex DepthNormalVertex
            #pragma fragment DepthNormalsFragment

            #pragma shader_feature_local _NORMALMAP

            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #pragma multi_compile_instancing

            #include "../SeaToonLitDepthNormalsPass.hlsl"

            ENDHLSL
        }

    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
