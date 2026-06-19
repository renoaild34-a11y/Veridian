#version 120

#include "lib/settings.glsl"
#include "lib/util.glsl"
#include "lib/space.glsl"
#include "lib/shadows.glsl"
#include "lib/lighting.glsl"
#include "lib/water.glsl"
#include "lib/sky.glsl"



varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 worldNormal;
varying vec3 worldPos;
varying vec3 viewPos;
varying float isWater;

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D depthtex1;       
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;
uniform int heldItemId;
uniform int heldItemId2;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;

void main(){
    vec4 tex = texture2D(texture, texcoord) * vColor;
    if(tex.a < 0.05) discard;

    vec2 screenUV = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    float opaqueDepth = texture2D(depthtex1, screenUV).r;
    if(isWater > 0.5 && opaqueDepth < gl_FragCoord.z - 0.00001) discard;

    float waterSurface = isWater * step(0.35, worldNormal.y);
    if(isWater > 0.5 && waterSurface < 0.5) discard;

    vec3 sunDirW   = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    vec3 lightDirW = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    vec3 viewDirW  = normalize(-worldPos);
    float dayAmt   = saturate(sunDirW.y * 1.4 + 0.18);

    vec3 nW = normalize(worldNormal);
    if(waterSurface > 0.5){
        vec3 wave = waterNormal(cameraPosition.xz + worldPos.xz, frameTimeCounter * 6.0, WATER_WAVE_HEIGHT * 18.0);
        nW = normalize(vec3(wave.x, 1.0, wave.z));
    }

    
    vec3 shadowVis = vec3(1.0);
#if SHADOWS_ENABLED == 1
    if(lmcoord.y > 0.01){
        vec3 sp = worldToShadowScreen(worldPos + nW * 0.06, shadowModelView, shadowProjection);
        shadowVis = shadowVisibility(shadowtex0, shadowtex1, shadowcolor0, sp,
                                     hash12(gl_FragCoord.xy) * 6.2831853);
    }
#endif

    vec3 ambientLight = toLinear(texture2D(lightmap, lmcoord).rgb);
    vec3 sunCol = mix(vec3(1.0, 0.52, 0.28), vec3(1.0, 0.95, 0.85), dayAmt);

    vec3 outColor;
    float outAlpha;

    if(waterSurface > 0.5){
        
        vec3  floorView  = screenToView(screenUV, opaqueDepth, gbufferProjectionInverse);
        float waterDepth = max(0.0, distance(viewPos, floorView));
        float depthFade  = 1.0 - exp(-waterDepth * 0.24 * WATER_ABSORPTION);

        
        float foamDepth = exp(-waterDepth * 4.0);
        float foamNoise = (valueNoise2(worldPos.xz * 0.8 + frameTimeCounter * 0.08) * 0.5 + 0.5) * 0.7
                        + (valueNoise2(worldPos.xz * 2.5 + frameTimeCounter * 0.15) * 0.5 + 0.5) * 0.3;
        float foam = saturate(foamDepth * 2.5 - foamNoise * 1.4);
        foam = saturate(foam * 1.5);

        vec3 reflDir    = reflect(-viewDirW, nW);
        vec3 reflection = atmosphere(reflDir, sunDirW);

        float fresnel = 0.02 + 0.98 * pow(1.0 - saturate(dot(viewDirW, nW)), 5.0);

        
        
        vec3 shallowTint = toLinear(vec3(0.025, 0.105, 0.125));
        vec3 deepTint    = toLinear(vec3(0.002, 0.018, 0.035));
        vec3 bodyTint = mix(shallowTint, deepTint, depthFade) * ambientLight * mix(0.78, 0.38, depthFade);

        vec3  h = normalize(lightDirW + viewDirW);
        float spec = pow(saturate(dot(nW, h)), 550.0) * 7.5 * dayAmt;
        float reflectAmt = saturate(fresnel * 1.45 + 0.10);

        vec3 heldCol = heldLightColor(heldItemId, heldItemId2);
        float nearTorch = pow(saturate(1.0 - length(worldPos) / 12.0), 2.0) * saturate(max(heldCol.r, max(heldCol.g, heldCol.b)) / 3.2);
        vec3 torchReflect = heldCol * nearTorch * (0.08 + 0.50 * fresnel);

        vec3 foamColor = vec3(0.85, 0.92, 1.0) * foam * (0.4 + 0.6 * dayAmt);
        outColor = mix(bodyTint, reflection, reflectAmt) + sunCol * spec * shadowVis + torchReflect + foamColor;
        
        
        
        outAlpha = saturate(0.55 + depthFade * 0.35 + fresnel * 0.25 + foam * 0.3);
    } else {
        Material m;
        m.albedo = toLinear(tex.rgb); m.normalW = nW; m.lm = lmcoord;
        m.smoothness = 0.4; m.reflectance = 0.1; m.emissive = 0.0;
        outColor = calcLighting(m, ambientLight, viewDirW, lightDirW, sunDirW, shadowVis);
        outColor = applyHeldLight(outColor, m, worldPos, heldItemId, heldItemId2);
        outAlpha = tex.a;
    }

    gl_FragData[0] = vec4(outColor, outAlpha);
    gl_FragData[1] = vec4(encodeNormal(nW), lmcoord.y);
    gl_FragData[2] = vec4(waterSurface > 0.5 ? 0.9 : 0.0,
                          waterSurface > 0.5 ? 0.3 : 0.0,
                          0.0,
                          waterSurface > 0.5 ? 0.5 : 0.0);
}
