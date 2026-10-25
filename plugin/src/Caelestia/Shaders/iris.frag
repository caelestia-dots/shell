#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
};

layout(binding = 1) uniform sampler2D from;
layout(binding = 2) uniform sampler2D to;

void transitionMain() {
    vec2 c = qt_TexCoord0 - vec2(0.5);
    c.x *= 1.7777;
    float d = length(c);
    float r = progress * 1.2;
    float feather = 0.05;
    float t = smoothstep(r + feather, r - feather, d);
    float edge = exp(-abs(d - r) * 100.0);
    vec3 chrom = vec3(
        texture(to, qt_TexCoord0 + vec2(0.012, 0.0) * edge).r,
        texture(to, qt_TexCoord0).g,
        texture(to, qt_TexCoord0 - vec2(0.012, 0.0) * edge).b
    );
    vec4 a = texture(from, qt_TexCoord0);
    fragColor = mix(a, vec4(chrom, 1.0), t);
}

void main() {
    transitionMain();
    fragColor *= qt_Opacity;
}
