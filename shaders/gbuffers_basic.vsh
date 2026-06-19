#version 120
varying vec4 vColor;
varying vec2 lmcoord;
void main(){
    gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);
    vColor  = gl_Color;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
}
