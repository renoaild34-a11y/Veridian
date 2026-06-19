#version 120
#include "lib/settings.glsl"
#include "lib/util.glsl"
#include "lib/tonemap.glsl"

varying vec2 texcoord;
uniform sampler2D colortex0;   
uniform sampler2D colortex4;   

void main(){
    vec3 color = texture2D(colortex0, texcoord).rgb;

#if BLOOM_ENABLED == 1
    vec3 bloom = texture2D(colortex4, texcoord).rgb;
    color += bloom * BLOOM_STRENGTH;
#endif

    color = colorGrade(color);     
    color = toSRGB(color);         

    gl_FragColor = vec4(saturate(color), 1.0);
}
