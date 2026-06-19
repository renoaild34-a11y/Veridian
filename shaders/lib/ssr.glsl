
#ifndef SSR_GLSL
#define SSR_GLSL
#include "settings.glsl"
#include "util.glsl"


vec4 screenSpaceReflection(vec3 vpos, vec3 vnorm, vec3 vdir,
                           sampler2D colorTex, sampler2D depthTex,
                           mat4 proj, float dither){
    vec3 refl = normalize(reflect(vdir, vnorm));

    float stepSize = 0.55;
    vec3  ray = vpos;
    vec2  hitUV = vec2(-1.0);
    float thickness = 0.6;

    for(int i = 0; i < SSR_STEPS; i++){
        ray += refl * stepSize;
        stepSize *= 1.18;                       

        vec4 clip = proj * vec4(ray, 1.0);
        if(clip.w <= 0.0) break;
        vec3 ndc = clip.xyz / clip.w;
        vec2 uv = ndc.xy * 0.5 + 0.5;
        if(uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) break;

        float sceneDepth = texture2D(depthTex, uv).r;
        float rayDepth   = ndc.z * 0.5 + 0.5;

        if(rayDepth > sceneDepth && rayDepth - sceneDepth < thickness * 0.02){
            hitUV = uv;
            
            vec3 a = ray - refl * stepSize, b = ray;
            for(int r = 0; r < SSR_REFINE; r++){
                vec3 mid = (a + b) * 0.5;
                vec4 mc = proj * vec4(mid, 1.0);
                vec2 muv = (mc.xy / mc.w) * 0.5 + 0.5;
                float md = texture2D(depthTex, muv).r;
                float rd = (mc.z / mc.w) * 0.5 + 0.5;
                if(rd > md){ b = mid; hitUV = muv; } else { a = mid; }
            }
            break;
        }
    }

    if(hitUV.x < 0.0) return vec4(0.0);

    
    vec2 e = smoothstep(0.0, 0.12, hitUV) * smoothstep(0.0, 0.12, 1.0 - hitUV);
    float edge = e.x * e.y;
    return vec4(texture2D(colorTex, hitUV).rgb, edge);
}

#endif 
