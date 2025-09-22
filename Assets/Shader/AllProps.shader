Shader "Unlit/AllProps"
{
    Properties
    {
         _myColor ("Sample Color", Color) = (1,1,1,1) 
         _myRange ("Sample Range", Range(0,5)) = 1 
         _myTex ("Sample Texture", 2D) = "white" {}
         _myCube ("Sample Cube", CUBE) = "" {} 
         _myFloat ("Sample Float", Float) = 0.5 
        _myVector("Sample Vector", Vector) = (0.5,1,1,1)
    }

    SubShader
    {
         Tags { "RenderType"="Opaque" "Queue"="Geometry" "RenderPipeline"="UniversalRenderPipeline" }
         LOD 200

         Pass
         {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex   vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv0        : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS  : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;
                float2 uv          : TEXCOORD2;
            };

            TEXTURE2D(_myTex);
            SAMPLER(sampler_myTex);

            TEXTURECUBE(_myCube);
            SAMPLER(sampler_myCube);

            CBUFFER_START(UnityPerMaterial)
                float4 _myColor;
                float4 _myTex_ST;
                float4 _myVector;
                float  _myRange;
                float  _myFloat;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 nrmWS = TransformObjectToWorldNormal(IN.normalOS);

                OUT.positionWS  = posWS;
                OUT.normalWS    = nrmWS;
                OUT.positionHCS = TransformWorldToHClip(posWS);
                OUT.uv = TRANSFORM_TEX(IN.uv0, _myTex);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                half3 texCol = SAMPLE_TEXTURE2D(_myTex, sampler_myTex, IN.uv).rgb;
                half3 albedo = texCol * _myRange * _myColor.rgb;

                float3 N = SafeNormalize(IN.normalWS);
                float3 V = SafeNormalize(GetWorldSpaceViewDir(IN.positionWS));

                Light mainLight = GetMainLight();
                float   NdotL   = saturate(dot(N, mainLight.direction));
                half3   diffuse = albedo * mainLight.color.rgb * NdotL;

                half3 ambient = SampleSH(N) * albedo;

                float3 R  = reflect(-V,N);
                half3 env = SAMPLE_TEXTURECUBE(_myCube, sampler_myCube, R).rgb;

                env *= _myFloat;
                env *= _myVector.xyz;

                half3 color = diffuse + ambient + env;

                return half4(color, 1);
            }
            ENDHLSL
        }
    }

    FallBack Off
}