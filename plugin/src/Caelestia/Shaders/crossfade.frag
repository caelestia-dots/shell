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

void main() {
    vec4 a = texture(from, qt_TexCoord0);
    vec4 b = texture(to, qt_TexCoord0);
    fragColor = mix(a, b, progress) * qt_Opacity;
}
