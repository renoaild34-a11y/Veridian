
#ifndef CLOUDS_GLSL
#define CLOUDS_GLSL
#include "settings.glsl"
#include "util.glsl"

float cloudHG(float c, float g){
    float g2 = g * g;
    return (1.0 - g2) / (4.0 * PI * pow(max(1.0 + g2 - 2.0 * g * c, 1e-4), 1.5));
}


float cloudDensity(vec3 worldPos, float yLocal, vec2 wind){
    float h = saturate((yLocal - CLOUD_HEIGHT) / CLOUD_THICKNESS);
    float profile = smoothstep(0.0, 0.18, h) * smoothstep(1.0, 0.5, h);
    if(profile <= 0.0) return 0.0;

    vec3 p = worldPos * 0.0021;
    p.xz += wind;

    float base = fbm3(p);
    base -= 0.22 * fbm3hi(p * 4.3 + 11.0);    
    float d = saturate(base) * profile;
    d = smoothstep(CLOUD_COVERAGE, CLOUD_COVERAGE + 0.28, d);
    return d * CLOUD_DENSITY;
}

float cloudLightMarch(vec3 wp, float yLocal, vec3 sunDir, vec2 wind){
    float stepLen = CLOUD_THICKNESS / float(CLOUD_LIGHT_STEPS);
    float sum = 0.0;
    for(int i = 1; i <= CLOUD_LIGHT_STEPS; i++){
        float t = float(i) * stepLen;
        sum += cloudDensity(wp + sunDir * t, yLocal + sunDir.y * t, wind);
    }
    return exp(-sum * stepLen * 0.045);
}


vec3 renderClouds(vec3 dir, vec3 sunDir, vec3 cameraPos, float frameTime,
                  float dayAmt, float dither, out float transmittance){
    transmittance = 1.0;
    vec3 scatter = vec3(0.0);
#if CLOUDS_ENABLED == 0
    return scatter;
#endif
    if(dir.y < 0.02) return scatter;

    float tEnter  = CLOUD_HEIGHT / dir.y;
    float tExit   = (CLOUD_HEIGHT + CLOUD_THICKNESS) / dir.y;
    float stepLen = (tExit - tEnter) / float(CLOUD_STEPS);
    float t       = tEnter + stepLen * dither;   

    vec2 wind = vec2(frameTime * 0.006 * CLOUD_SPEED, frameTime * 0.002 * CLOUD_SPEED);

    float cosT  = dot(dir, sunDir);
    float phase = mix(cloudHG(cosT, 0.7), cloudHG(cosT, -0.2), 0.5);

    vec3 sunCol = mix(vec3(1.0, 0.5, 0.27), vec3(1.0, 0.97, 0.92), dayAmt) * 1.8;
    vec3 ambCol = mix(vec3(0.30, 0.36, 0.5), vec3(0.8, 0.86, 1.0), saturate(sunDir.y + 0.3));

    for(int i = 0; i < CLOUD_STEPS; i++){
        if(transmittance < 0.02) break;
        float yLocal   = dir.y * t;
        vec3  worldPos = cameraPos + dir * t;
        float d = cloudDensity(worldPos, yLocal, wind);
        if(d > 0.0){
            float lightT = cloudLightMarch(worldPos, yLocal, sunDir, wind);
            float powder = 1.0 - exp(-d * 2.0);          
            vec3 col = ambCol * 0.55 + sunCol * lightT * phase * powder;
            float a = 1.0 - exp(-d * stepLen * 0.07);
            scatter += transmittance * a * col;
            transmittance *= (1.0 - a);
        }
        t += stepLen;
    }
    return scatter;
}

#endif 
