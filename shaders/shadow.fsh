#version 120
#include "lib/settings.glsl"
#include "lib/blocklights.glsl"


varying vec2 texcoord;
varying vec4 vColor;
varying float isLeafShadow;
varying float shadowBlockId;
uniform sampler2D texture;

void main(){
#if LEAF_SHADOWS_ENABLED == 0
    
    
    
    if(isLeafShadow > 0.5) discard;
#endif

    vec4 c = texture2D(texture, texcoord) * vColor;
    if(c.a < 0.1) discard;
    
    gl_FragData[0] = c;

    vec3 emit = cl_blockEmissionColor(shadowBlockId);
    float mask = cl_blockEmissionMask(shadowBlockId);
    gl_FragData[1] = vec4(emit, mask);
}
