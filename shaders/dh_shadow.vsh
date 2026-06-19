#version 120

#include "lib/settings.glsl"
#include "lib/shadows.glsl"

varying vec2 texcoord;
varying vec4 vColor;

void main(){
    vec4 clip = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);
    clip.xyz = distortShadowClip(clip.xyz);
    gl_Position = clip;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
    vColor   = gl_Color;
}
