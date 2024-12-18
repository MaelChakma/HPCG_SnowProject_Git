Shader "Particles/SnowParticleShader"
{
Properties {
    _MainTex ("Main Particle Texture", 2D) = "white" {}
    _TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
    _SwitchDistance ("Distance to switch between detailed and far",  Range(0.000000,20.000000)) = 6.000000
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

            // ------------------------------------------------- Vertex shader

            sampler2D _MainTex;
            fixed4 _TintColor;
            
            struct appdata_t {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
                float4 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                float4 projPos : TEXCOORD1;
                float4 random : TEXCOORD2;
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
                o.texcoord = TRANSFORM_TEX(v.texcoord0.xy,_MainTex);
                o.random = float4(v.texcoord0.zw,v.texcoord1.xy);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            // ------------------------------------------------- Distance functions

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
            float sdHyberbola( in float2 p, in float k, in float he) // k in (0,inf)
            {
                p = abs(p);
                p = float2(p.x-p.y,p.x+p.y)/sqrt(2);

                float x2 = p.x*p.x/16.0;
                float y2 = p.y*p.y/16.0;
                float r = k*(4.0*k - p.x*p.y)/12.0;
                float q = (x2 - y2)*k*k;
                float h = q*q + r*r*r;
                float u;
                if( h<0.0 )
                {
                    float m = sqrt(-r);
                    u = m*cos( acos(q/(r*m))/3.0 );
                }
                else
                {
                    float m = pow(sqrt(h)-q,1.0/3.0);
                    u = (m - r/m)/2.0;
                }
                float w = sqrt( u + x2 );
                float b = k*p.y - x2*p.x*2.0;
                float t = p.x/4.0 - w + sqrt( 2.0*x2 - u + b/w/4.0 );
                t = max(t,sqrt(he*he*0.5+k)-he/sqrt(2.0));
                float d = length( p-float2(t,k/t) );
                return p.x*p.y < k ? d : -d;
            }

            // ---------------------------------------------------- Drawing functions

            float2 rotate(float2 uvIn, float degAngle)
            {
                const float PI = 3.14159;
                float radAngle = degAngle * PI * 2 * -1/360;
                float sine, cosine;
                sincos(radAngle, sine, cosine);
                return float2(cosine * uvIn.x + sine * uvIn.y, cosine * uvIn.y - sine * uvIn.x);
            }

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
                float d = sdHexagram(rotate(uv,30), radius);
                if(!isFilled){ d = abs(d);}
                d =step(d,width);
                return d;
            }   

            float createHyperbola(in float2 uv, in float width, in float angle, in float spacing, in float length)
            {

                float d = sdHyberbola(rotate(uv,angle),spacing,length);
                d = abs(d);
                d = step(d,width);
                return d;
            }

            float createHyperbolaStar(in float2 uv, in float width, in float spacing, in float length)
            {
                float d = createHyperbola(uv,width,0,spacing,length);
                d += createHyperbola(uv,width,60,spacing,length);
                d += createHyperbola(uv,width,120,spacing,length);
                return d;
            }

            float createRandomSnowflake(in float2 uv, in float4 random)
            {
                float d = 0;
                float minWidth = 0.01;
                float maxWidth = 0.035;
                float minScale = 0.1;
                float maxScale = 0.6;

                // Segment star
                float baseStarWidth = lerp(minWidth,maxWidth, random.x);
                float baseStarScale = lerp(minScale,maxScale, random.y);
                d += createSegmentStar(uv, baseStarWidth, baseStarScale);
                // Second thicker and smaller star
                if(baseStarScale > maxScale/2)
                {
                    float width = lerp(baseStarWidth*1.3,maxWidth, random.z);
                    float scale = lerp(0.1, baseStarScale*0.95, random.w);
                    d += createSegmentStar(uv, width, scale);
                }



                // Hexagon
                float baseHexagonWidth = 0;
                float baseHexagonScale = 0;
                if(random.z < 0.5)
                {
                    baseHexagonWidth = lerp(minWidth,maxWidth/2, random.x);
                    baseHexagonScale = lerp(minScale,maxScale/5, random.y);
                    d += createHexagon(uv, baseHexagonWidth, baseHexagonScale, random.w > 0.5 ? true : false);
                    // Second hexagon
                    if(random.x < 0.5)
                    {
                        float width = baseHexagonWidth;
                        float scale = lerp(baseHexagonScale,baseStarScale*0.9, random.w);
                        d += createHexagon(uv, width, scale, false);
                    }
                } 
                else if (random.z > 0.7)
                {
                    // Hexagram
                    float baseHexagramWidth = lerp(minWidth,maxWidth/2, random.x);
                    float baseHexagramScale = lerp(minScale,maxScale/5, random.y);
                    d += createHexagram(uv, baseHexagramWidth, baseHexagramScale, random.w > 0.5 ? true : false);
                    // Second hexagram
                    if(random.x < 0.5)
                    {
                        float width = baseHexagramWidth;
                        float scale = lerp(baseHexagramScale,baseStarScale*0.9, random.w);
                        d += createHexagram(uv, width, scale, false);
                    }
                }
                
                // Hyperbola star
                float minBranchSpacing = 0.01;
                float maxBranchSpacing = 0.15;
                float minBranchLength = 0.05;
                float maxBranchLength = 0.1;
                if(random.w < 0.9)
                {
                    float baseHyperbolaWidth = lerp(minWidth,maxWidth/2, random.x);
                    float baseHyperbolaSpacing = baseStarScale/9;
                    float baseHyperbolaLength = lerp(minBranchLength,maxBranchLength, random.y);
                    d += createHyperbolaStar(uv, baseHyperbolaWidth, baseHyperbolaSpacing, baseHyperbolaLength);
                    // Second hyperbola star
                    if(random.x < 0.5)
                    {
                        float width = baseHyperbolaWidth;
                        float spacing = baseHyperbolaSpacing/2;
                        float length = baseHyperbolaLength*2;
                        d += createHyperbolaStar(uv, width, spacing, length);
                    }
                }

                return d;
                // d += createSegmentStar(uv,width, 1.0f);
                // d += createHexagon(uv, width, scale, false);
                // d += createHexagon(uv, width, scale/6, false);
                // d += createHexagon(uv, width/3, scale*0.8, false);
                // d += createHexagram(uv, width, scale/2, false);
                // d += createHexagram(uv, width/2, scale/3, false);
                // d += createHyperbolaStar(uv,width,0.3,0.3);
                // d += createHyperbolaStar(uv,width,0.1,0.3);
            }



            // ------------------------------------------------------ Fragment shader

            sampler2D_float _CameraDepthTexture;
            float _InvFade;
            
            fixed4 frag (v2f i) : SV_Target
            {

                float partZ = i.projPos.z;
                float blend = clamp(partZ-_SwitchDistance,0,1);

                fixed4 col = i.color;
                float colMult;

                float zDiff = _SwitchDistance-partZ;

                if(zDiff <= 0)
                {
                    // Display the main Texture
                    colMult = tex2D(_MainTex, i.texcoord);
                }
                else 
                {
                    // Generate a snowflake
                    float2 uv = i.texcoord*2-1;
                    float d = 0.0f;
                    d += createRandomSnowflake(uv, i.random);
                    d = clamp(1,0,d);
                    colMult = d;

                    if(zDiff < 3)
                    {
                        fixed4 colMult2 = tex2D(_MainTex, i.texcoord);
                        colMult = lerp(colMult2,colMult,zDiff/3);
                    }

                }

                col = col*colMult;

                //fixed4 colA = tex2D(_MainTex, i.texcoords0);
                //fixed4 colB = tex2D(_FarTex, i.texcoords1);
                //fixed4 col = 2.0f * i.color * lerp(colA, colB, blend);

                
            
                UNITY_APPLY_FOG(i.fogCoord, col); 
                return col;
            }


            ENDCG 
        }
    }   
}
}