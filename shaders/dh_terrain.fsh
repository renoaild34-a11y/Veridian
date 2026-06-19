#version 120
#include "lib/settings.glsl"
#include "lib/util.glsl"
#include "lib/shadows.glsl"
#include "lib/lighting.glsl"



varying vec2 texcoord;
varying vec4 vColor;
varying vec3 worldNormal;
varying vec3 worldPos;

uniform sampler2D texture;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;

void main(){
    vec4 tex = texture2D(texture, texcoord);
    vec3 rawColor = tex.rgb * vColor.rgb;
    vec3 albedo = toLinear(rawColor);
    float alpha = tex.a * vColor.a;
    if(alpha < 0.1) discard;

#if DH_TERRAIN_WATER_FIX == 1
    
    
    
    
    
    float blueDominant = step(rawColor.r * 1.35 + 0.04, rawColor.b) *
                         step(rawColor.g * 1.08 + 0.02, rawColor.b) *
                         step(0.20, rawColor.b) *
                         step(0.08, rawColor.g);
    if(blueDominant > 0.5 && worldNormal.y > 0.25) discard;
#endif

    vec3 sunDirW   = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    vec3 lightDirW = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    vec3 viewDirW  = normalize(-worldPos);

    
    vec2 lm = vec2(0.0, 1.0);

    vec3 shadowVis = vec3(1.0);
#if SHADOWS_ENABLED == 1
    if(length(worldPos.xz) < shadowDistance){
        vec3 sp = worldToShadowScreen(worldPos + normalize(worldNormal) * 0.06, shadowModelView, shadowProjection);
        shadowVis = shadowVisibility(shadowtex0, shadowtex1, shadowcolor0, sp,
                                     hash12(gl_FragCoord.xy) * 6.2831853);
    }
#endif

    vec3 ambientLight = daySkyAmbient(sunDirW);

    Material m;
    m.albedo = albedo; m.normalW = normalize(worldNormal); m.lm = lm;
    m.smoothness = 0.0; m.reflectance = 0.0; m.emissive = 0.0;

    vec3 color = calcLighting(m, ambientLight, viewDirW, lightDirW, sunDirW, shadowVis);

    gl_FragData[0] = vec4(color, alpha);
    gl_FragData[1] = vec4(encodeNormal(m.normalW), lm.y);
    gl_FragData[2] = vec4(0.0);
}
