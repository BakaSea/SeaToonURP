Shader "SeaToon/SeaToonShellFur"
{
    Properties
    {
        [Header(Base Color)]
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [HDR][MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)
        
        [Header(Ramp)]
        _RampColor("Ramp Color", Color) = (0.6117647, 0.6117647, 0.6274511, 1)

        [Header(Alpha Clipping)]
        [Toggle(_ALPHATEST_ON)] _ALPHATEST_ON("Enable", Float) = 0
        _Cutoff("Cutoff", Range(0.0, 1.0)) = 0.5

        [Header(Normal)]
        _BumpScale("Bump Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}
        
        [Header(Shell)]
        // 每个材质独立的层数和间距参数
        _ShellCount("Shell Count", Integer) = 16
        _ShellDistance("Shell Distance", Float) = 0.005

        [Header(Fur)]
        // 毛发高度图：白色=有毛发(高度满)，黑色=无毛发
        _FurNoiseMap("Fur Noise Map", 2D) = "white" {}
        _FurUVOffset("Fur Noise UV Offset", Vector) = (1, 0, 0, 0)
        _FurDensity("Fur Density", Range(1.0, 100.0)) = 30.0
        _FurOcclusionPower("Fur Occlusion Power", Range(0.0, 5.0)) = 1.5
        
        [Header(PBR)]
        _SpecularColor("Specular Color", Color) = (1, 1, 1)
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.0
        _Anisotropy("Anisotropy", Range(-1.0, 1.0)) = 0.0
        [Toggle(_THREADMAP_ON)] _THREADMAP_ON("Use Thread Map", Float) = 0
        _ThreadMap("Thread Map", 2D) = "black" {}
        _ThreadAOStrength("Thread AO Strength", Range(0.0, 1.0)) = 1.0
        _ThreadNormalStrength("Thread Normal Strength", Range(0.0, 1.0)) = 1.0
        _ThreadSmoothnessScale("Thread Smoothness Scale", Range(0.0, 1.0)) = 1.0
        
        [Header(Emission)]
        [HDR] _EmissionColor("Emission Color", Color) = (0, 0, 0)
        _EmissionMap("Emission Map", 2D) = "white" {}

        [Header(Occlusion)]
        _OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap("Occlusion Map", 2D) = "white" {}

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
        #define SHELL_FUR_MAT

        ENDHLSL

        Pass
        {
            Name "ShellFur"
            Tags
            {
                "LightMode" = "ShellFur"
            }

            Blend One Zero
            ZWrite On
            Cull Back
            ZTest LEqual

            HLSLPROGRAM

            #pragma vertex LitForwardVertex
            #pragma fragment LitForwardFragment
            
            #pragma shader_feature_local _NORMALMAP
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_LAYERS
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _FORWARD_PLUS

            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer

            #include "../SeaToonLitForwardPass.hlsl"

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
            #pragma multi_compile_fragment _ _MAIN_LIGHT_NO_TOON_SHADOWS

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
