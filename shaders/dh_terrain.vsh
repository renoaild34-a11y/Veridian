#version 120

#include "lib/settings.glsl"

varying vec2 texcoord;
varying vec4 vColor;
varying vec3 worldNormal;
varying vec3 worldPos;

uniform mat4 dhProjection;
uniform mat4 gbufferModelViewInverse;

void main(){
    vec4 vp = gl_ModelViewMatrix * gl_Vertex;
    gl_Position = dhProjection * vp;

    worldPos = (gbufferModelViewInverse * vp).xyz;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
    vColor   = gl_Color;

    vec3 vn = normalize(gl_NormalMatrix * gl_Normal);
    worldNormal = normalize(mat3(gbufferModelViewInverse) * vn);
}
