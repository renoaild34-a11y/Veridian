#version 120
#include "lib/settings.glsl"
#include "lib/util.glsl"
#include "lib/space.glsl"
#include "lib/sky.glsl"
#include "lib/clouds.glsl"



varying vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
#ifdef DISTANT_HORIZONS
uniform sampler2D dhDepthTex0;
#endif

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform float frameTimeCounter;
uniform int   frameCounter;

void main(){
    vec3  scene = texture2D(colortex0, texcoord).rgb;
    float depth = texture2D(depthtex0, texcoord).r;

    bool isSky = depth >= 1.0;
#ifdef DISTANT_HORIZONS
    float dhDepth = texture2D(dhDepthTex0, texcoord).r;
    isSky = isSky && dhDepth >= 1.0;
#endif

    if(!isSky){
        gl_FragData[0] = vec4(scene, 1.0);   
        return;
    }

    
    vec3 viewDir  = screenToView(texcoord, 1.0, gbufferProjectionInverse);
    vec3 dir      = normalize(mat3(gbufferModelViewInverse) * viewDir);
    vec3 sunDir   = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    float dayAmt  = saturate(sunDir.y * 1.4 + 0.18);

    vec3 sky = atmosphere(dir, sunDir);
    sky += starField(dir, frameTimeCounter, dayAmt);
    sky += moonDisc(dir, sunDir);

    float dither = ditherIGN(gl_FragCoord.xy, mod(float(frameCounter), 64.0));
    float transmittance;
    vec3 clouds = renderClouds(dir, sunDir, cameraPosition, frameTimeCounter,
                               dayAmt, dither, transmittance);

    vec3 result = sky * transmittance + clouds;
    gl_FragData[0] = vec4(result, 1.0);
}
