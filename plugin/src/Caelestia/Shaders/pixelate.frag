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
    float bump = 1.0 - abs(progress - 0.5) * 2.0;
    float blocks = mix(800.0, 12.0, bump);
    vec2 q = floor(qt_TexCoord0 * blocks) / blocks + 0.5 / blocks;
    vec4 a = texture(from, q);
    vec4 b = texture(to, q);
    fragColor = mix(a, b, smoothstep(0.0, 1.0, progress));
}

void main() {
    transitionMain();
    fragColor *= qt_Opacity;
}
