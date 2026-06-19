
#ifndef SPACE_GLSL
#define SPACE_GLSL


vec3 screenToView(vec2 uv, float depth, mat4 projInverse){
    vec4 ndc = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 v = projInverse * ndc;
    return v.xyz / v.w;
}


vec3 viewToWorld(vec3 viewPos, mat4 mvInverse){
    return (mvInverse * vec4(viewPos, 1.0)).xyz;
}

vec3 viewToWorldDir(vec3 v, mat4 mvInverse){
    return normalize(mat3(mvInverse) * v);
}


float linearizeDepth(float d, float near, float far){
    return (2.0 * near * far) / (far + near - (d * 2.0 - 1.0) * (far - near));
}

#endif 
