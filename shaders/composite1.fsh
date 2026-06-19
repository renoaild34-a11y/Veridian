#version 120

#include "lib/settings.glsl"
#include "lib/util.glsl"



varying vec2 texcoord;
uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;

void main(){
#if BLOOM_ENABLED == 0
    gl_FragData[0] = vec4(0.0);
    return;
#endif
    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
    float spread = 2.5;

    vec3 sum = vec3(0.0);
    for(int i = -4; i <= 4; i++){
        float fi = float(i);
        float wgt = exp(-fi * fi * 0.18);           
        vec2 o = vec2(texel.x * fi * spread, 0.0);
        sum += max(texture2D(colortex0, texcoord + o).rgb - 1.0, 0.0) * wgt;
    }
    sum /= 3.78;   
    gl_FragData[0] = vec4(sum, 1.0);
}
