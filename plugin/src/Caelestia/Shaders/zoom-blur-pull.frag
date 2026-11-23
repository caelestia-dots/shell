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

const float PI = 3.14159265358979;
const float strengthMax = 0.4;

float linearEase(float begin, float change, float duration, float time) {
    return change * time / duration + begin;
}

float exponentialEaseInOut(float begin, float change, float duration, float time) {
    if (time == 0.0) return begin;
    if (time == duration) return begin + change;
    time = time / (duration / 2.0);
    if (time < 1.0) return change / 2.0 * pow(2.0, 10.0 * (time - 1.0)) + begin;
    return change / 2.0 * (-pow(2.0, -10.0 * (time - 1.0)) + 2.0) + begin;
}

float sinusoidalEaseInOut(float begin, float change, float duration, float time) {
    return -change / 2.0 * (cos(PI * time / duration) - 1.0) + begin;
}

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 crossFade(vec2 uv, float dissolve) {
    return mix(texture(from, uv), texture(to, uv), dissolve);
}

void transitionMain() {
    vec2 texCoord = qt_TexCoord0;
    vec2 center = vec2(linearEase(0.25, 0.5, 1.0, progress), 0.5);
    float dissolve = exponentialEaseInOut(0.0, 1.0, 1.0, progress);
    float strength = sinusoidalEaseInOut(0.0, strengthMax, 0.5, progress);
    if (strength < 0.005) {
        fragColor = crossFade(texCoord, dissolve);
        return;
    }
    vec4 color = vec4(0.0);
    float total = 0.0;
    vec2 toCenter = center - texCoord;
    float offset = rand(qt_TexCoord0);
    for (float t = 0.0; t <= 12.0; t++) {
        float percent = (t + offset) / 12.0;
        float weight = 4.0 * (percent - percent * percent);
        color += crossFade(texCoord + toCenter * percent * strength, dissolve) * weight;
        total += weight;
    }
    fragColor = color / total;
}

void main() {
    transitionMain();
    fragColor *= qt_Opacity;
}
