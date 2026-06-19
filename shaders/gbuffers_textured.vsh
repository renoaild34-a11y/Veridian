#version 120
#include "lib/settings.glsl"

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 worldNormal;
varying vec3 worldPos;
varying float blockId;

attribute vec2 mc_Entity;

uniform mat4 gbufferModelViewInverse;

void main(){
    vec4 vp = gl_ModelViewMatrix * gl_Vertex;
    gl_Position = gl_ProjectionMatrix * vp;
    worldPos = (gbufferModelViewInverse * vp).xyz;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
    vColor   = gl_Color;
    blockId  = mc_Entity.x;
    vec3 vn = normalize(gl_NormalMatrix * gl_Normal);
    worldNormal = normalize(mat3(gbufferModelViewInverse) * vn);
}
