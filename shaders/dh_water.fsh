#version 120

#include "lib/settings.glsl"
#include "lib/util.glsl"
#include "lib/sky.glsl"



varying vec2 texcoord;
varying vec4 vColor;
varying vec3 worldNormal;
varying vec3 worldPos;

uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;

void main(){
#if DH_WATER_ENABLED == 0
    discard;
#endif

    vec3 nW = normalize(worldNormal);
    if(nW.y < 0.35) discard;

    vec3 viewDirW = normalize(-worldPos);
    vec3 sunDirW  = normalize(mat3(gbufferModelViewInverse) * sunPosition);

    vec3 reflDir = reflect(-viewDirW, nW);
    vec3 reflection = atmosphere(reflDir, sunDirW);

    float fresnel = 0.02 + 0.98 * pow(1.0 - saturate(dot(viewDirW, nW)), 5.0);
    vec3 waterTint = vec3(0.05, 0.18, 0.26);

    
    float dist = length(worldPos);
    float distFade = 1.0 - smoothstep(32.0, 128.0, dist);

    vec3 color = mix(waterTint, reflection, fresnel);
    float alpha = saturate(0.55 + fresnel * 0.35) * distFade;

    gl_FragData[0] = vec4(color, alpha);
    gl_FragData[1] = vec4(encodeNormal(nW), 1.0);
    gl_FragData[2] = vec4(0.9, 0.3, 0.0, 0.5);
}
