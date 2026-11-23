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
    float p = progress;
    float waveX = (qt_TexCoord0.x + qt_TexCoord0.y) * 0.5;
    float waveP = smoothstep(0.0, 1.0, p * 1.6 - waveX * 0.6);
    float bump = sin(waveP * 3.14159);
    float blocks = mix(800.0, 8.0, bump);
    vec2 q = floor(qt_TexCoord0 * blocks) / blocks + 0.5 / blocks;
    vec4 a = texture(from, q);
    vec4 b = texture(to, q);
    fragColor = mix(a, b, smoothstep(0.0, 1.0, waveP));
}

void main() {
    transitionMain();
    fragColor *= qt_Opacity;
}
