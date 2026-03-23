using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SeaToonLitShader : ShaderGUI
{
    public override void ValidateMaterial(Material material)
    {
        if (material.HasProperty("_BumpMap"))
        {
            CoreUtils.SetKeyword(material, ShaderKeywordStrings._NORMALMAP,  material.GetTexture("_BumpMap"));
        }
    }
}
