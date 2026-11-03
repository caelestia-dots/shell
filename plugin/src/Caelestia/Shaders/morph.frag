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

const float strength = 0.15;

void transitionMain() {
    vec4 ca = texture(from, qt_TexCoord0);
    vec4 cb = texture(to, qt_TexCoord0);
    vec2 oa = (((ca.rg + ca.b) * 0.5) * 2.0 - 1.0);
    vec2 ob = (((cb.rg + cb.b) * 0.5) * 2.0 - 1.0);
    vec2 oc = mix(oa, ob, 0.5) * strength;
    float w0 = progress;
    float w1 = 1.0 - w0;
    fragColor = mix(texture(from, qt_TexCoord0 + oc * w0), texture(to, qt_TexCoord0 - oc * w1), progress);
}

void main() {
    transitionMain();
    fragColor *= qt_Opacity;
}
