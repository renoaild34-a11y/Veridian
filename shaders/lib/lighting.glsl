
#ifndef LIGHTING_GLSL
#define LIGHTING_GLSL
#include "settings.glsl"
#include "util.glsl"

struct Material {
    vec3  albedo;      
    vec3  normalW;     
    vec2  lm;          
    float smoothness;  
    float reflectance; 
    float emissive;    
};


vec3 calcLighting(Material m, vec3 ambientLight, vec3 viewDirW,
                  vec3 lightDirW, vec3 sunDirW, vec3 shadowVis){
    float dayAmt   = saturate(sunDirW.y * 1.4 + 0.18);
    float nightAmt = saturate(-sunDirW.y * 1.4) * 0.25;
    float lightAmt = max(dayAmt, nightAmt);

    
    vec3 base = m.albedo * ambientLight * AMBIENT_STRENGTH;

    
    float ndl = saturate(dot(m.normalW, lightDirW));
    vec3 sunCol  = mix(vec3(1.0, 0.52, 0.28), vec3(1.0, 0.95, 0.85), dayAmt);
    vec3 moonCol = vec3(0.5, 0.62, 0.95);
    vec3 lightCol = mix(moonCol, sunCol, dayAmt) * SUNLIGHT_STRENGTH;

    
    vec3 direct = m.albedo * lightCol * ndl * shadowVis * lightAmt * m.lm.y;

    vec3 color = base + direct;

    
#if SPECULAR_ENABLED == 1
    vec3  h = normalize(lightDirW + viewDirW);
    float gloss = mix(24.0, 256.0, m.smoothness);
    float spec = pow(saturate(dot(m.normalW, h)), gloss) * (0.15 + m.reflectance);
    color += lightCol * spec * ndl * shadowVis * lightAmt * m.lm.y;
#endif

    
    color += m.albedo * m.emissive * 2.5;

    return color;
}

float itemIdMask(int id, float target){
    return 1.0 - step(0.5, abs(float(id) - target));
}

vec3 heldLightColorForId(int id){
#if HELD_LIGHT_ENABLED == 0
    return vec3(0.0);
#endif
    float warm = itemIdMask(id, 10002.0); 
    float red  = itemIdMask(id, 10003.0); 
    float soul = itemIdMask(id, 10004.0); 
    return vec3(1.0, 0.58, 0.24) * 3.2 * warm +
           vec3(1.0, 0.08, 0.02) * 0.75 * red +
           vec3(0.05, 0.95, 1.0) * 1.55 * soul;
}

vec3 heldLightColor(int heldItemId, int heldItemId2){
    return max(heldLightColorForId(heldItemId), heldLightColorForId(heldItemId2));
}

float heldLightAmount(int heldItemId, int heldItemId2){
    vec3 c = heldLightColor(heldItemId, heldItemId2);
    return max(c.r, max(c.g, c.b));
}

vec3 applyHeldLight(vec3 color, Material m, vec3 worldPos, int heldItemId, int heldItemId2){
#if HELD_LIGHT_ENABLED == 0
    return color;
#endif
    vec3 heldCol = heldLightColor(heldItemId, heldItemId2);
    float heldActive = max(heldCol.r, max(heldCol.g, heldCol.b));
    if(heldActive <= 0.0) return color;

    
    
    
    float d = length(worldPos);
    float range = mix(9.0, 15.0, saturate(heldActive / 3.0));
    float atten = pow(saturate(1.0 - d / range), 2.0) / (1.0 + d * d * 0.035);
    float facing = 0.35 + 0.65 * saturate(dot(normalize(m.normalW), normalize(-worldPos)));

    
    
    
    float luma = dot(m.albedo, vec3(0.2126, 0.7152, 0.0722));
    vec3 litSurface = mix(vec3(luma), sqrt(max(m.albedo, vec3(0.0))), 0.38);
    vec3 coloredLight = litSurface * heldCol + heldCol * 0.10;
    return color + coloredLight * atten * facing;
}


vec3 daySkyAmbient(vec3 sunDirW){
    float dayAmt = saturate(sunDirW.y * 1.4 + 0.18);
    vec3 dayCol   = vec3(0.95, 1.0, 1.05);
    vec3 nightCol = vec3(0.10, 0.13, 0.22);
    return mix(nightCol, dayCol, dayAmt);
}

#endif 
