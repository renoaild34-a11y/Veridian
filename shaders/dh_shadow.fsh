#version 120
varying vec2 texcoord;
varying vec4 vColor;
uniform sampler2D texture;
void main(){
    
    
    discard;

    vec4 c = texture2D(texture, texcoord) * vColor;
    if(c.a < 0.1) discard;
    gl_FragColor = c;
}
