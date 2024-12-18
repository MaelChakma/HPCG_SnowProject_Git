Shader "Particles/SnowParticleShader"
{
Properties {
    _MainTex ("Main Particle Texture", 2D) = "white" {}
    _FarTex ("Far Particle Texture", 2D) = "white" {}
    _TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
    _SwitchDistance ("Distance to switch between detailed and far",  Range(0.000000,10.000000)) = 1.000000
}

Category {
    Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
    Blend SrcAlpha OneMinusSrcAlpha
    ColorMask RGB
    Cull Off Lighting Off ZWrite Off

    SubShader {
        Pass {
        
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_particles
            #pragma multi_compile_fog
            
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _FarTex;
            fixed4 _TintColor;
            
            struct appdata_t {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
                float2 texcoords0 : TEXCOORD0;
                float2 texcoords1 : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 texcoords0 : TEXCOORD0;
                float2 texcoords1 : TEXCOORD1;
                fixed blend : TEXCOORD2;
                float4 projPos : TEXCOORD4;
                UNITY_FOG_COORDS(3)
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            float4 _MainTex_ST;
            float4 _FarTex_ST;
            float _SwitchDistance;

            v2f vert (appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); 
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.projPos = ComputeScreenPos (o.vertex);
                COMPUTE_EYEDEPTH(o.projPos.z);
                o.color = v.color * _TintColor;
                o.texcoords0 = TRANSFORM_TEX(v.texcoords0,_MainTex);
                o.texcoords1 = TRANSFORM_TEX(v.texcoords1,_FarTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            // Distance functions

            float sdSegment( in float2 p, in float2 a, in float2 b )
            {
                float2 pa = p-a, ba = b-a;
                float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
                return length( pa - ba*h );
            }
            float sdHexagon( in float2 p, in float r )
            {
                const float3 k = float3(-0.866025404,0.5,0.577350269);
                p = abs(p);
                p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
                p -= float2(clamp(p.x, -k.z*r, k.z*r), r);
                return length(p)*sign(p.y);
            }
            float sdHexagram( in float2 p, in float r )
            {
                const float4 k = float4(-0.5,0.8660254038,0.5773502692,1.7320508076);
                p = abs(p);
                p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
                p -= 2.0*min(dot(k.yx,p),0.0)*k.yx;
                p -= float2(clamp(p.x,r*k.z,r*k.w),r);
                return length(p)*sign(p.y);
            }


            // Drawing functions

            float createSegment(in float2 uv,in float width, in float2 a, in float2 b)
            {
                float d = sdSegment(uv, a, b);
                d = step(d,width);
                return d;
            }            

            float createSegmentStar(in float2 uv, in float width, in float scale)
            {
                return clamp(0,1,
                    createSegment(uv,width,float2(1.0f,0.0f)*scale,float2(-1.0f,0.0f)*scale) + 
                    createSegment(uv,width,float2(0.5f,0.866f)*scale,float2(-0.5f,-0.866f)*scale) +
                    createSegment(uv,width,float2(0.5f,-0.866f)*scale,float2(-0.5f,0.866f)*scale) 
                    );
            }

            float createHexagon(in float2 uv,in float width, in float radius, in bool isFilled)
            {
                float d = sdHexagon(uv, radius);
                if(!isFilled){ d = abs(d);}
                d =step(d,width);
                return d;
            }   

            float createHexagram(in float2 uv,in float width, in float radius, in bool isFilled)
            {
                float d = sdHexagram(uv, radius);
                if(!isFilled){ d = abs(d);}
                d =step(d,width);
                return d;
            }   

            sampler2D_float _CameraDepthTexture;
            float _InvFade;
            
            fixed4 frag (v2f i) : SV_Target
            {

                float partZ = i.projPos.z;
                float blend = clamp(partZ-_SwitchDistance,0,1);
               
                //fixed4 colA = tex2D(_MainTex, i.texcoords0);
                //fixed4 colB = tex2D(_FarTex, i.texcoords1);
                //fixed4 col = 2.0f * i.color * lerp(colA, colB, blend);

                float2 uv = i.texcoords0*2-1;

                
                float width = 0.03f;
                float scale = 0.7f;
                float d = 0.0f;
                d += createSegmentStar(uv,width, scale);
                d += createHexagon(uv, width, scale/8, true);
                d += createHexagon(uv, width, scale/6, false);
                d += createHexagon(uv, width/3, scale*0.8, false);
                d += createHexagram(uv, width, scale/2, false);
                d += createHexagram(uv, width/2, scale/3, false);

                d = clamp(1,0,d);
                
                fixed4 col =  i.color * d;
            
                UNITY_APPLY_FOG(i.fogCoord, col); 
                return col;
            }


            ENDCG 
        }
    }   
}
}