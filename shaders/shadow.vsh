#version 120
#include "lib/settings.glsl"
#include "lib/shadows.glsl"
#include "lib/blocklights.glsl"

varying vec2 texcoord;
varying vec4 vColor;
varying float isLeafShadow;
varying float shadowBlockId;

attribute vec2 mc_Entity;

void main(){
    
    vec4 clip = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);
    clip.xyz = distortShadowClip(clip.xyz);   
    gl_Position = clip;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
    vColor   = gl_Color;
    shadowBlockId = mc_Entity.x;
    isLeafShadow = 1.0 - step(0.5, abs(mc_Entity.x - 10001.0));
}
