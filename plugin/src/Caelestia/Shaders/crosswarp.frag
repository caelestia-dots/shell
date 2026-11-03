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
    float x = progress;
    x = smoothstep(0.0, 1.0, (x * 2.0 + qt_TexCoord0.x - 1.0));
    fragColor = mix(
        texture(from, (qt_TexCoord0 - 0.5) * (1.0 - x) + 0.5),
        texture(to, (qt_TexCoord0 - 0.5) * x + 0.5),
        x
    );
}

void main() {
    transitionMain();
    fragColor *= qt_Opacity;
}
