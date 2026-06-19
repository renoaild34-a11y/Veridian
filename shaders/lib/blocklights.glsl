#ifndef BLOCKLIGHTS_GLSL
#define BLOCKLIGHTS_GLSL
#include "settings.glsl"
#include "util.glsl"
#include "shadows.glsl"

float cl_blockMask(float id, float target){
    return 1.0 - step(0.5, abs(id - target));
}

vec3 cl_blockEmissionColor(float id){
    float warm = cl_blockMask(id, 10010.0);
    float red  = cl_blockMask(id, 10011.0);
    float soul = cl_blockMask(id, 10012.0);
    float aqua = cl_blockMask(id, 10013.0);
    return vec3(1.0, 0.55, 0.18) * warm +
           vec3(1.0, 0.03, 0.01) * red +
           vec3(0.07, 0.82, 1.0) * soul +
           vec3(0.12, 0.95, 1.0) * aqua;
}

float cl_blockEmissionMask(float id){
    vec3 c = cl_blockEmissionColor(id);
    return step(0.01, max(c.r, max(c.g, c.b)));
}

vec3 applyPlacedBlockLights(vec3 baseColor, vec3 worldPos, vec3 normalW,
                            vec2 lmcoord, sampler2D scolor1,
                            mat4 shadowMV, mat4 shadowProj){
#if COLORED_LIGHTS_ENABLED == 0
    return vec3(0.0);
#endif

    
    
    
    float blockLight = smoothstep(0.05, 0.82, lmcoord.x);
    if(blockLight <= 0.001) return vec3(0.0);

    vec3 sp = worldToShadowScreen(worldPos + normalW * 0.04, shadowMV, shadowProj);
    if(sp.x < 0.0 || sp.x > 1.0 || sp.y < 0.0 || sp.y > 1.0 || sp.z > 1.0)
        return vec3(0.0);

    vec2 texel = vec2(1.0 / float(shadowMapResolution));
    vec3 sum = vec3(0.0);
    float weightSum = 0.0;

    
    
    
    
    for(int i = 0; i < 16; i++){
        float fi = float(i) + 0.5;
        float a = fi * 2.39996323;
        float r = sqrt(fi / 16.0);
        vec2 off = vec2(cos(a), sin(a)) * r * texel * 90.0;
        vec4 src = texture2D(scolor1, sp.xy + off);
        float mask = src.a;
        if(mask <= 0.01) continue;

        float distFade = pow(saturate(1.0 - r), 1.8);
        float normalFade = 0.55 + 0.45 * saturate(normalW.y * 0.5 + 0.5);
        float w = mask * distFade * normalFade;
        sum += src.rgb * w;
        weightSum += w;
    }

    if(weightSum <= 0.0) return vec3(0.0);

    vec3 lightCol = sum / weightSum;
    float strength = 0.42 * blockLight * saturate(weightSum * 0.75);

    float luma = dot(baseColor, vec3(0.2126, 0.7152, 0.0722));
    vec3 receiver = mix(vec3(luma), sqrt(max(baseColor, vec3(0.0))), 0.45);
    return (receiver * lightCol + lightCol * 0.06) * strength;
}

#endif 
