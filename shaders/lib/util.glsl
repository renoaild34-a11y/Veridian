
#ifndef UTIL_GLSL
#define UTIL_GLSL

const float PI    = 3.14159265359;
const float TAU   = 6.28318530718;
const float RPI   = 0.31830988618;   

float saturate(float x){ return clamp(x, 0.0, 1.0); }
vec2  saturate(vec2  x){ return clamp(x, 0.0, 1.0); }
vec3  saturate(vec3  x){ return clamp(x, 0.0, 1.0); }

float luma(vec3 c){ return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

float maxc(vec3 c){ return max(c.r, max(c.g, c.b)); }

vec3 saturation(vec3 c, float s){ return mix(vec3(luma(c)), c, s); }


vec3 toLinear(vec3 c){ return pow(c, vec3(2.2)); }
vec3 toSRGB(vec3 c){ return pow(c, vec3(1.0 / 2.2)); }


float hash11(float p){ p = fract(p * 0.1031); p *= p + 33.33; p *= p + p; return fract(p); }

float hash12(vec2 p){
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float hash13(vec3 p){
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}


float valueNoise2(vec2 p){
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash12(i);
    float b = hash12(i + vec2(1, 0));
    float c = hash12(i + vec2(0, 1));
    float d = hash12(i + vec2(1, 1));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}


float valueNoise3(vec3 p){
    vec3 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float n000 = hash13(i + vec3(0,0,0));
    float n100 = hash13(i + vec3(1,0,0));
    float n010 = hash13(i + vec3(0,1,0));
    float n110 = hash13(i + vec3(1,1,0));
    float n001 = hash13(i + vec3(0,0,1));
    float n101 = hash13(i + vec3(1,0,1));
    float n011 = hash13(i + vec3(0,1,1));
    float n111 = hash13(i + vec3(1,1,1));
    return mix(mix(mix(n000,n100,f.x), mix(n010,n110,f.x), f.y),
               mix(mix(n001,n101,f.x), mix(n011,n111,f.x), f.y), f.z);
}


float fbm3(vec3 p){
    float s = 0.0, a = 0.5, fr = 1.0;
    for(int i = 0; i < 4; i++){
        s  += a * valueNoise3(p * fr);
        fr *= 2.03; a *= 0.5;
    }
    return s;
}
float fbm3hi(vec3 p){
    float s = 0.0, a = 0.5, fr = 1.0;
    for(int i = 0; i < 3; i++){
        s  += a * valueNoise3(p * fr);
        fr *= 2.03; a *= 0.5;
    }
    return s;
}


vec3 encodeNormal(vec3 n){ return n * 0.5 + 0.5; }
vec3 decodeNormal(vec3 e){ return normalize(e * 2.0 - 1.0); }


float ditherIGN(vec2 coord, float frame){
    coord += frame * 5.588238;
    return fract(52.9829189 * fract(dot(coord, vec2(0.06711056, 0.00583715))));
}

#endif 
