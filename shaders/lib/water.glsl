
#ifndef WATER_GLSL
#define WATER_GLSL
#include "settings.glsl"
#include "util.glsl"

float waterHeight(vec2 p, float t){
    
    vec2 q = p * 0.55;
    vec2 warp = vec2(valueNoise2(q), valueNoise2(q * 1.37)) - 0.5;
    q += warp * 1.35;

    
    float h = 0.0;
    h += (valueNoise2(q * 1.20) - 0.5) * 0.18;
    h += (valueNoise2(q * 2.35) - 0.5) * 0.09;
    h += (valueNoise2(q * 4.80) - 0.5) * 0.04;

    
    
    h += sin(dot(p, vec2( 0.62, 0.78)) * 0.55 + t * 0.60) * 0.18;
    h += sin(dot(p, vec2(-0.91, 0.41)) * 0.70 + t * 0.80) * 0.14;
    h += sin(dot(p, vec2( 0.33,-0.94)) * 0.45 + t * 0.50) * 0.12;
    h += sin(dot(p, vec2(-0.77,-0.64)) * 0.80 + t * 0.90) * 0.10;
    h += sin(dot(p, vec2( 0.98, 0.20)) * 0.60 + t * 0.70) * 0.08;
    h += sin(dot(p, vec2(-0.26, 0.97)) * 0.50 + t * 0.55) * 0.06;
    return h;
}


vec3 waterNormal(vec2 worldXZ, float t, float strength){
#if WATER_WAVES == 0
    return vec3(0.0, 1.0, 0.0);
#endif
    float e = 0.25;
    float h  = waterHeight(worldXZ, t);
    float hx = waterHeight(worldXZ + vec2(e, 0.0), t);
    float hz = waterHeight(worldXZ + vec2(0.0, e), t);
    vec2 grad = vec2(h - hx, h - hz) / e;
    return normalize(vec3(grad.x * strength, 1.0, grad.y * strength));
}

#endif 
