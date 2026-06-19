#version 120
#include "lib/settings.glsl"
#include "lib/water.glsl"

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 worldNormal;
varying vec3 worldPos;
varying vec3 viewPos;
varying float isWater;

attribute vec2 mc_Entity;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

void main(){
    float waterId = 1.0 - step(0.5, abs(mc_Entity.x - 10000.0));

    vec4 vp = gl_ModelViewMatrix * gl_Vertex;
    vec3 wp = (gbufferModelViewInverse * vp).xyz;

    vec3 vn = normalize(gl_NormalMatrix * gl_Normal);
    vec3 wn = normalize(mat3(gbufferModelViewInverse) * vn);

#if WATER_WAVES == 1
    
    
    
    if(waterId > 0.5 && wn.y > 0.55){
        float h = waterHeight(cameraPosition.xz + wp.xz, frameTimeCounter * 8.0);
        wp.y += h * WATER_WAVE_HEIGHT * 4.0;
        vp = gbufferModelView * vec4(wp, 1.0);
    }
#endif

    viewPos = vp.xyz;
    gl_Position = gl_ProjectionMatrix * vp;

    worldPos = wp;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
    vColor   = gl_Color;

    worldNormal = wn;

    
    
    
    
    isWater = waterId;
}
