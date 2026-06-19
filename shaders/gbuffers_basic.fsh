#version 120
#include "lib/util.glsl"



varying vec4 vColor;
varying vec2 lmcoord;
uniform sampler2D lightmap;

void main(){
    if(vColor.a < 0.01) discard;
    vec3 col = toLinear(vColor.rgb) * texture2D(lightmap, lmcoord).rgb;
    gl_FragData[0] = vec4(col, vColor.a);
    gl_FragData[1] = vec4(0.5, 0.5, 1.0, lmcoord.y);
    gl_FragData[2] = vec4(0.0);
}
