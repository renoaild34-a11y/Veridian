
#ifndef TONEMAP_GLSL
#define TONEMAP_GLSL
#include "settings.glsl"
#include "util.glsl"

vec3 tonemapReinhard(vec3 x){ return x / (1.0 + x); }

vec3 tonemapACES(vec3 x){
    const float a = 2.51, b = 0.03, c = 2.43, d = 0.59, e = 0.14;
    return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
}


vec3 tonemapUchimura(vec3 x){
    const float P = 1.0, a = 1.0, m = 0.22, l = 0.4, c = 1.33, b = 0.0;
    float l0 = (P - m) * l / a;
    float S0 = m + l0, S1 = m + a * l0;
    float C2 = a * P / (P - S1);
    float CP = -C2 / P;
    vec3 w0 = vec3(1.0 - smoothstep(0.0, m, x));
    vec3 w2 = vec3(step(m + l0, x));
    vec3 w1 = vec3(1.0 - w0 - w2);
    vec3 T = vec3(m * pow(x / m, vec3(c)) + b);
    vec3 L = vec3(m + a * (x - m));
    vec3 Sx = vec3(P - (P - S1) * exp(CP * (x - S0)));
    return T * w0 + L * w1 + Sx * w2;
}

vec3 applyTonemap(vec3 c){
#if TONEMAP == 0
    return tonemapReinhard(c);
#elif TONEMAP == 2
    return tonemapUchimura(c);
#else
    return tonemapACES(c);
#endif
}


vec3 applyVibrance(vec3 c, float v){
    float mx = maxc(c);
    float avg = (c.r + c.g + c.b) / 3.0;
    float amt = (mx - avg) * (-3.0 * v);
    return mix(c, vec3(mx), amt);
}

vec3 colorGrade(vec3 c){
    c *= EXPOSURE;
    c = applyTonemap(c);

    
    c *= mix(vec3(0.92, 0.97, 1.08), vec3(1.08, 0.99, 0.90),
             WHITE_BALANCE * 0.5 + 0.5);

    c = saturation(c, SATURATION);
    c = applyVibrance(c, VIBRANCE);
    c = saturate((c - 0.5) * CONTRAST + 0.5);
    return c;
}

#endif 
