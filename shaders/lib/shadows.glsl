
#ifndef SHADOWS_GLSL
#define SHADOWS_GLSL
#include "settings.glsl"
#include "util.glsl"


const int   shadowMapResolution        = 2048;   
const float shadowDistance             = 160.0;  
const float shadowDistanceRenderMul    = 1.0;
const bool  shadowHardwareFiltering     = false;

const float SHADOW_MAP_BIAS = 0.85;   


vec3 distortShadowClip(vec3 pos){
    float len = length(pos.xy);
    float factor = len * SHADOW_MAP_BIAS + (1.0 - SHADOW_MAP_BIAS);
    return vec3(pos.xy / factor, pos.z * 0.5);
}


vec3 worldToShadowScreen(vec3 worldPos, mat4 shadowMV, mat4 shadowProj){
    vec3 sc = (shadowProj * (shadowMV * vec4(worldPos, 1.0))).xyz;
    sc = distortShadowClip(sc);
    return sc * 0.5 + 0.5;
}

float pcf(sampler2D stex, vec3 sp, float angle){
    float texel = 1.0 / float(shadowMapResolution);
    float radius = SHADOW_SOFTNESS * texel;
    float s = sin(angle), c = cos(angle);
    mat2 rot = mat2(c, -s, s, c);

    float lit = 0.0;
    float invN = 1.0 / float(SHADOW_FILTER_SAMPLES);
    for(int i = 0; i < SHADOW_FILTER_SAMPLES; i++){
        
        float fi = (float(i) + 0.5) * invN;
        float r = sqrt(fi);
        float a = fi * 6.2831853 * 3.0;
        vec2 offs = rot * (vec2(cos(a), sin(a)) * r) * radius;
        float occ = texture2D(stex, sp.xy + offs).r;
        lit += step(sp.z - SHADOW_BIAS, occ);
    }
    return lit * invN;
}


vec3 shadowVisibility(sampler2D stex0, sampler2D stex1, sampler2D scolor,
                      vec3 sp, float angle){
    if(sp.x < 0.0 || sp.x > 1.0 || sp.y < 0.0 || sp.y > 1.0 || sp.z > 1.0)
        return vec3(1.0);                      

    float opaque = pcf(stex1, sp, angle);
#if COLORED_SHADOWS == 1
    float all = pcf(stex0, sp, angle);
    vec3  tint = texture2D(scolor, sp.xy).rgb;
    vec3  colored = mix(tint, vec3(1.0), all); 
    return opaque * colored;
#else
    return vec3(opaque);
#endif
}

#endif 
