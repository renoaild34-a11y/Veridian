#version 120
#include "lib/settings.glsl"
#include "lib/util.glsl"
#include "lib/space.glsl"
#include "lib/sky.glsl"
#include "lib/shadows.glsl"
#include "lib/water.glsl"
#include "lib/ssr.glsl"



varying vec2 texcoord;

uniform sampler2D colortex0;   
uniform sampler2D colortex1;   
uniform sampler2D colortex2;   
uniform sampler2D depthtex0;   
uniform sampler2D depthtex1;   
uniform sampler2D shadowtex0;
#ifdef DISTANT_HORIZONS
uniform sampler2D dhDepthTex0;
uniform mat4 dhProjectionInverse;
#endif

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform float frameTimeCounter;
uniform int   frameCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;
uniform int   isEyeInWater;    
uniform int   heldItemId;
uniform int   heldItemId2;


float computeSSAO(vec2 uv, vec3 vpos, vec3 vnorm){
#if SSAO_ENABLED == 0
    return 1.0;
#endif
    float occ = 0.0;
    float rad = SSAO_RADIUS;
    vec3 up = abs(vnorm.y) < 0.99 ? vec3(0,1,0) : vec3(1,0,0);
    vec3 tang = normalize(cross(up, vnorm));
    vec3 bitang = cross(vnorm, tang);

    for(int i = 0; i < SSAO_SAMPLES; i++){
        float f = (float(i) + 0.5) / float(SSAO_SAMPLES);
        float a = hash12(gl_FragCoord.xy + float(i) * 1.37) * TAU;
        float r = sqrt(f);
        vec3 d = vec3(cos(a) * r, sin(a) * r, f);
        vec3 samp = vpos + (tang * d.x + bitang * d.y + vnorm * d.z) * rad;

        vec4 cp = gbufferProjection * vec4(samp, 1.0);
        if(cp.w <= 0.0) continue;
        vec2 suv = (cp.xy / cp.w) * 0.5 + 0.5;
        if(suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) continue;

        float sd = texture2D(depthtex0, suv).r;
        vec3 svpos = screenToView(suv, sd, gbufferProjectionInverse);
        float rangeCheck = smoothstep(0.0, 1.0, rad / max(abs(vpos.z - svpos.z), 1e-4));
        occ += (svpos.z >= samp.z + 0.02 ? 1.0 : 0.0) * rangeCheck;
    }
    return saturate(1.0 - (occ / float(SSAO_SAMPLES)) * SSAO_STRENGTH);
}


float volumetricLight(vec3 worldFrag){
#if VL_ENABLED == 0
    return 0.0;
#endif
    float len = min(length(worldFrag), 80.0);
    vec3 dir = normalize(worldFrag);
    float stepLen = len / float(VL_STEPS);
    float dither = ditherIGN(gl_FragCoord.xy, mod(float(frameCounter), 64.0));

    float accum = 0.0;
    for(int i = 0; i < VL_STEPS; i++){
        float t = (float(i) + dither) * stepLen;
        vec3 wp = dir * t;
        vec3 sp = worldToShadowScreen(wp, shadowModelView, shadowProjection);
        float lit = 1.0;
        if(sp.x > 0.0 && sp.x < 1.0 && sp.y > 0.0 && sp.y < 1.0)
            lit = step(sp.z - 0.0006, texture2D(shadowtex0, sp.xy).r);
        accum += lit;
    }
    return accum / float(VL_STEPS);
}

vec3 sourceColorFromMatId(float matId){
#if COLORED_LIGHTS_ENABLED == 0
    return vec3(0.0);
#endif
    float warm = 1.0 - step(0.5, abs(matId - 2.0));
    float red  = 1.0 - step(0.5, abs(matId - 3.0));
    float soul = 1.0 - step(0.5, abs(matId - 4.0));
    float aqua = 1.0 - step(0.5, abs(matId - 5.0));
    return vec3(1.0, 0.52, 0.18) * 1.25 * warm +
           vec3(1.0, 0.04, 0.01) * 1.05 * red +
           vec3(0.05, 0.85, 1.0) * 1.35 * soul +
           vec3(0.10, 0.95, 1.0) * 1.20 * aqua;
}

vec3 inferVisibleLightColor(vec3 c){
#if COLORED_LIGHTS_ENABLED == 0
    return vec3(0.0);
#endif
    
    
    
    
    float mx = max(c.r, max(c.g, c.b));
    float mn = min(c.r, min(c.g, c.b));
    float chroma = mx - mn;
    
    
    
    float bright = smoothstep(0.22, 1.15, mx) * smoothstep(0.05, 0.45, chroma);

    vec3 n = c / max(mx, 1e-4);
    float cyan = smoothstep(0.15, 0.70, min(n.g, n.b) - n.r);
    float red  = smoothstep(0.15, 0.70, n.r - max(n.g, n.b));
    float warm = smoothstep(0.05, 0.55, min(n.r, n.g) - n.b) * smoothstep(0.00, 0.55, n.r - n.g + 0.18);

    vec3 outCol = vec3(0.0);
    outCol += vec3(0.05, 0.90, 1.0) * cyan;
    outCol += vec3(1.0, 0.04, 0.01) * red;
    outCol += vec3(1.0, 0.52, 0.18) * warm;
    return outCol * bright * 1.35;
}

vec3 screenSpaceColoredBlockLight(vec2 uv, vec3 baseColor, vec3 viewPos){
#if COLORED_LIGHTS_ENABLED == 0
    return vec3(0.0);
#endif
    vec2 aspect = vec2(viewWidth / max(viewHeight, 1.0), 1.0);
    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
    vec3 accum = vec3(0.0);
    float total = 0.0;

    for(int i = 0; i < 16; i++){
        float a = (float(i) + 0.5) * 0.3926990817;
        vec2 dir = vec2(cos(a), sin(a));
        for(int j = 1; j <= 12; j++){
            float fj = float(j);
            vec2 suv = uv + dir * texel * (fj * 24.0);
            if(suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) continue;

            float matId = texture2D(colortex2, suv).a;
            vec3 srcCol = sourceColorFromMatId(matId);
            vec3 srcScene = texture2D(colortex0, suv).rgb;
            srcCol = max(srcCol, inferVisibleLightColor(srcScene));
            float srcAmt = max(srcCol.r, max(srcCol.g, srcCol.b));
            if(srcAmt <= 0.0) continue;

            
            
            
            float depthGap = abs(texture2D(depthtex0, suv).r - texture2D(depthtex0, uv).r);
            float zFade = 1.0 - smoothstep(0.002, 0.080, depthGap);
            zFade = max(zFade, 0.35);
            float r = fj / 12.0;
            float falloff = pow(saturate(1.0 - r), 1.25) * zFade;
            accum += srcCol * falloff;
            total += falloff;
        }
    }

    if(total <= 0.0) return vec3(0.0);
    vec3 lightCol = accum / total;
    float intensity = saturate(total * 0.55);

    
    
    
    float luma = dot(baseColor, vec3(0.2126, 0.7152, 0.0722));
    vec3 receiver = mix(vec3(luma), sqrt(max(baseColor, vec3(0.0))), 0.30);
    return (receiver * lightCol + lightCol * 0.08) * intensity;
}

void main(){
    vec3  scene = texture2D(colortex0, texcoord).rgb;
    float depth = texture2D(depthtex0, texcoord).r;

    mat4 projInv = gbufferProjectionInverse;
    float usedDepth = depth;
    bool isSky = depth >= 1.0;
    bool isDH = false;

#ifdef DISTANT_HORIZONS
    float dhDepth = texture2D(dhDepthTex0, texcoord).r;
    if(depth >= 1.0 && dhDepth < 1.0){
        usedDepth = dhDepth;
        projInv = dhProjectionInverse;
        isSky = false; isDH = true;
    } else {
        isSky = isSky && dhDepth >= 1.0;
    }
#endif

    if(isSky){
        gl_FragData[0] = vec4(scene, 1.0);   
        return;
    }

    vec3 viewPos  = screenToView(texcoord, usedDepth, projInv);
    vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 worldDir = normalize(worldPos);
    float dist = length(viewPos);

    vec3 sunDirW   = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    vec3 lightDirW = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    float dayAmt = saturate(sunDirW.y * 1.4 + 0.18);

    
    
    
    float opaqueDepth = texture2D(depthtex1, texcoord).r;
    float linFront = linearizeDepth(usedDepth, near, far);
    float linBack  = linearizeDepth(opaqueDepth, near, far);
    bool waterVsSky   = (opaqueDepth >= 1.0) && (usedDepth < 1.0);
    bool waterVsFloor = (opaqueDepth < 1.0)  && (linBack - linFront > 0.12);
    float matIdHere = texture2D(colortex2, texcoord).a;
    bool waterTagged = (matIdHere > 0.5 && matIdHere < 1.5);
    bool isWaterPix = (!isDH) && waterTagged && (usedDepth < 1.0) && (waterVsSky || waterVsFloor);

    
#if SSR_ENABLED == 1
    if(isWaterPix){
        
        
        
        vec3 wave = waterNormal(cameraPosition.xz + worldPos.xz, frameTimeCounter * 6.0,
                                WATER_WAVE_HEIGHT * 12.0);
        vec3 wnW = normalize(vec3(wave.x, 1.0, wave.z));
        vec3 vn  = normalize(mat3(gbufferModelView) * wnW);
        vec3 vd  = normalize(viewPos);
        float dith = ditherIGN(gl_FragCoord.xy, mod(float(frameCounter), 64.0));
        vec4 hit = screenSpaceReflection(viewPos, vn, vd, colortex0, depthtex0,
                                         gbufferProjection, dith);
        if(hit.a > 0.0){
            float fres = 0.10 + 0.90 * pow(1.0 - saturate(dot(-vd, vn)), 3.0);
            scene = mix(scene, hit.rgb, saturate(hit.a * (0.28 + fres * 1.55)));
        }
    }
#endif

    
    if(!isDH && !isWaterPix && dist < 48.0){
        vec3 worldN = decodeNormal(texture2D(colortex1, texcoord).rgb);
        vec3 viewN  = normalize(mat3(gbufferModelView) * worldN);  
        float ao = computeSSAO(texcoord, viewPos, viewN);
        float fade = 1.0 - smoothstep(32.0, 48.0, dist);
        scene *= mix(1.0, ao, 0.6 * fade);
    }

    
#if COLORED_LIGHT_SPILL_SCREENSPACE == 1
    if(!isDH && !isWaterPix){
        scene += screenSpaceColoredBlockLight(texcoord, scene, viewPos);
    }
#endif

    
    float vl = volumetricLight(worldPos);
    float phase = 0.5 + 0.5 * pow(saturate(dot(worldDir, sunDirW)), 6.0);
    vec3 sunCol = mix(vec3(1.0,0.5,0.26), vec3(1.0,0.96,0.88), dayAmt);
    scene += sunCol * vl * phase * VL_STRENGTH * 0.08 * dayAmt;

    
#if FOG_ENABLED == 1
    
    float fogStart = 28.0;
    float fogAmt = 1.0 - exp(-max(dist - fogStart, 0.0) * 0.0016 * FOG_DENSITY);
  #ifdef DISTANT_HORIZONS
    #if DH_FOG_BLEND == 0
      if(isDH) fogAmt = 0.0;
    #endif
  #endif
    vec3 fogCol = atmosphere(worldDir, sunDirW);
    
    if(isEyeInWater == 0) scene = mix(scene, fogCol, saturate(fogAmt));
#endif

    
    if(isEyeInWater == 1){
        float wf = 1.0 - exp(-dist * 0.105 * WATER_ABSORPTION);
        vec3 underCol = toLinear(vec3(0.045, 0.175, 0.245)) * (0.65 + 0.45 * dayAmt);

        
        
        float caustic = sin(worldPos.x * 0.37 + frameTimeCounter * 0.85) *
                        sin(worldPos.z * 0.31 - frameTimeCounter * 0.72);
        caustic = pow(saturate(caustic * 0.5 + 0.5), 7.0);
        vec3 causticCol = vec3(0.025, 0.10, 0.13) * caustic * (1.0 - saturate(wf)) * dayAmt;
        float upScatter = pow(saturate(normalize(viewPos).y * 0.5 + 0.5), 2.0) * dayAmt;
        vec3 surfaceGlow = toLinear(vec3(0.16, 0.36, 0.46)) * upScatter * (1.0 - saturate(wf * 0.85));

        float warmHeld = max(1.0 - step(0.5, abs(float(heldItemId) - 10002.0)),
                             1.0 - step(0.5, abs(float(heldItemId2) - 10002.0)));
        float redHeld = max(1.0 - step(0.5, abs(float(heldItemId) - 10003.0)),
                            1.0 - step(0.5, abs(float(heldItemId2) - 10003.0)));
        float soulHeld = max(1.0 - step(0.5, abs(float(heldItemId) - 10004.0)),
                             1.0 - step(0.5, abs(float(heldItemId2) - 10004.0)));
        vec3 heldCol = vec3(1.0, 0.55, 0.22) * 1.8 * warmHeld +
                       vec3(1.0, 0.06, 0.02) * 0.38 * redHeld +
                       vec3(0.16, 0.65, 1.0) * 0.65 * soulHeld;
        float torchFog = pow(saturate(1.0 - dist / 11.0), 2.0);

        scene = mix(scene, underCol, saturate(wf * 0.62));
        scene += causticCol + surfaceGlow + heldCol * torchFog;
    }

    gl_FragData[0] = vec4(scene, 1.0);
}
