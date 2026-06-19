#version 120
#include "lib/settings.glsl"
#include "lib/util.glsl"
#include "lib/shadows.glsl"
#include "lib/lighting.glsl"
#include "lib/blocklights.glsl"



varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 worldNormal;
varying vec3 worldPos;
varying float blockId;

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform int heldItemId;
uniform int heldItemId2;

float blockMask(float id, float target){
    return 1.0 - step(0.5, abs(id - target));
}

vec3 blockEmissionColor(float id){
    float warm = blockMask(id, 10010.0);
    float red  = blockMask(id, 10011.0);
    float soul = blockMask(id, 10012.0);
    float aqua = blockMask(id, 10013.0);
    return vec3(1.0, 0.55, 0.18) * 3.4 * warm +
           vec3(1.0, 0.03, 0.01) * 1.5 * red +
           vec3(0.10, 0.65, 1.0) * 1.9 * soul +
           vec3(0.20, 0.95, 1.0) * 1.8 * aqua;
}

float blockEmissionId(float id){
    return blockMask(id, 10010.0) * 2.0 +
           blockMask(id, 10011.0) * 3.0 +
           blockMask(id, 10012.0) * 4.0 +
           blockMask(id, 10013.0) * 5.0;
}

void main(){
    vec4 tex = texture2D(texture, texcoord);
    vec3 albedo = toLinear(tex.rgb) * toLinear(vColor.rgb);
    float alpha = tex.a * vColor.a;
    if(alpha < 0.1) discard;

    vec3 sunDirW   = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    vec3 lightDirW = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    vec3 viewDirW  = normalize(-worldPos);

    vec3 shadowVis = vec3(1.0);
#if SHADOWS_ENABLED == 1
    if(lmcoord.y > 0.01){
        vec3 sp = worldToShadowScreen(worldPos + normalize(worldNormal) * 0.06, shadowModelView, shadowProjection);
        shadowVis = shadowVisibility(shadowtex0, shadowtex1, shadowcolor0, sp,
                                     hash12(gl_FragCoord.xy) * 6.2831853);
    }
#endif

    vec3 ambientLight = toLinear(texture2D(lightmap, lmcoord).rgb);

    Material m;
    m.albedo = albedo; m.normalW = normalize(worldNormal); m.lm = lmcoord;
    m.smoothness = 0.0; m.reflectance = 0.0; m.emissive = 0.0;

    vec3 color = calcLighting(m, ambientLight, viewDirW, lightDirW, sunDirW, shadowVis);
    color = applyHeldLight(color, m, worldPos, heldItemId, heldItemId2);
    color += applyPlacedBlockLights(color, worldPos, m.normalW, lmcoord, shadowcolor1, shadowModelView, shadowProjection);

    float outMatId = 0.0;
#if COLORED_LIGHTS_ENABLED == 1
    vec3 emitCol = blockEmissionColor(blockId);
    float emitAmt = max(emitCol.r, max(emitCol.g, emitCol.b));
    if(emitAmt > 0.0){
        color += albedo * emitCol + emitCol * 0.18;
        m.emissive = saturate(emitAmt / 3.4);
        outMatId = blockEmissionId(blockId);
    }
#endif

    gl_FragData[0] = vec4(color, alpha);
    gl_FragData[1] = vec4(encodeNormal(m.normalW), lmcoord.y);
    gl_FragData[2] = vec4(m.smoothness, m.reflectance, m.emissive, outMatId);
}
