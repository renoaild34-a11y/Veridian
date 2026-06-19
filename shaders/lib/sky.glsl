
#ifndef SKY_GLSL
#define SKY_GLSL
#include "settings.glsl"
#include "util.glsl"


const vec3  RAYLEIGH_COEFF = vec3(5.8e-3, 13.5e-3, 33.1e-3) * 28.0;
const float MIE_COEFF      = 4.0e-3 * 210.0;

float rayleighPhase(float c){ return 0.75 * (1.0 + c * c); }
float miePhase(float c, float g){
    float g2 = g * g;
    return (1.0 - g2) / (4.0 * PI * pow(max(1.0 + g2 - 2.0 * g * c, 1e-4), 1.5));
}


vec3 atmosphere(vec3 dir, vec3 sunDir){
    float up      = saturate(dir.y * 0.5 + 0.5);
    float cosT    = dot(dir, sunDir);
    float sunUp   = sunDir.y;
    float dayAmt  = saturate(sunUp * 1.4 + 0.18);     
    float duskAmt = saturate(1.0 - abs(sunUp) * 3.0); 

    
    float zenith  = saturate(dir.y);
    float airmass = 1.0 / (zenith + 0.15);

    vec3  rayl = RAYLEIGH_COEFF * airmass;
    float mie  = MIE_COEFF * airmass;

    
    vec3 extinction = exp(-(rayl + mie) * 0.02);

    
    float rP = rayleighPhase(cosT);
    float mP = miePhase(cosT, 0.76);

    vec3 sunTint = mix(vec3(1.0, 0.45, 0.18), vec3(1.0, 0.96, 0.9), dayAmt);
    vec3 scatter = (RAYLEIGH_COEFF * rP + MIE_COEFF * mP * sunTint) * 0.9;

    vec3 sky = scatter * (1.0 - extinction);

    
    vec3 zenithCol  = vec3(0.10, 0.26, 0.62);
    vec3 horizonCol = vec3(0.62, 0.74, 0.92);
    sky += mix(horizonCol, zenithCol, pow(up, 0.6)) * 0.55 * dayAmt;

    
    sky += vec3(1.0, 0.42, 0.16) * pow(1.0 - up, 3.0) * duskAmt * 1.4;

    
    sky += sunTint * pow(saturate(cosT), 8.0) * 0.7 * dayAmt;
    sky += sunTint * smoothstep(0.9995, 0.99995, cosT) * 12.0;

    
    sky = mix(vec3(0.012, 0.016, 0.035), sky, dayAmt);
    sky += vec3(0.02, 0.03, 0.06) * (1.0 - dayAmt);      

    return max(sky, 0.0) * SKY_BRIGHTNESS;
}


vec3 starField(vec3 dir, float frameTime, float dayAmt){
#if STARS_ENABLED == 0
    return vec3(0.0);
#endif
    float night = saturate(1.0 - dayAmt * 2.0);
    if(night <= 0.0 || dir.y < -0.05) return vec3(0.0);
    vec3 q = floor(dir * 250.0);
    float h = hash13(q);
    float s = smoothstep(0.9985, 0.9998, h);
    float tw = 0.55 + 0.45 * sin(frameTime * 2.5 + h * 60.0);
    return vec3(s * tw) * night * vec3(0.9, 0.95, 1.0);
}


vec3 moonDisc(vec3 dir, vec3 sunDir){
#if MOON_ENABLED == 0
    return vec3(0.0);
#endif
    vec3 moonDir = normalize(-sunDir);
    float dayAmt = saturate(sunDir.y * 1.4 + 0.18);
    float vis = saturate(1.0 - dayAmt * 2.2) * smoothstep(-0.08, 0.18, moonDir.y);
    if(vis <= 0.0) return vec3(0.0);

    float c = dot(dir, moonDir);
    float radius = 0.032;
    float inner = cos(radius);
    float outer = cos(radius * 1.18);
    float disc = smoothstep(outer, inner, c);
    if(disc <= 0.0) return vec3(0.0);

    vec3 upRef = abs(moonDir.y) < 0.95 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
    vec3 right = normalize(cross(upRef, moonDir));
    vec3 up = cross(moonDir, right);
    vec2 p = vec2(dot(dir, right), dot(dir, up)) / max(radius, 1e-4);

    float limb = saturate(1.0 - dot(p, p));
    float shade = 0.82 + 0.18 * pow(limb, 0.35);

    
    shade -= 0.18 * smoothstep(0.22, 0.0, length(p - vec2(-0.28, 0.18)));
    shade -= 0.13 * smoothstep(0.18, 0.0, length(p - vec2( 0.22,-0.12)));
    shade -= 0.10 * smoothstep(0.14, 0.0, length(p - vec2( 0.02, 0.36)));
    shade -= 0.08 * smoothstep(0.10, 0.0, length(p - vec2(-0.05,-0.34)));

    vec3 moonCol = vec3(0.78, 0.84, 0.95) * shade;
    vec3 glow = vec3(0.30, 0.40, 0.75) * pow(saturate(c), 260.0) * 0.22;
    return (moonCol * disc * 2.4 + glow) * vis;
}

#endif 
