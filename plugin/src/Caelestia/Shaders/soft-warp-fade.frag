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

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void transitionMain() {
    float p = progress;
    float strength = sin(p * 3.14159) * 0.025;
    vec2 warp = vec2(
        noise(qt_TexCoord0 * 3.0 + vec2(0.0, p * 0.5)),
        noise(qt_TexCoord0 * 3.0 + vec2(p * 0.5, 0.0))
    ) - 0.5;
    vec2 uvWarped = qt_TexCoord0 + warp * strength;
    vec4 a = texture(from, uvWarped);
    vec4 b = texture(to, uvWarped);
    float t = smoothstep(0.05, 0.95, p);
    t = t * t * (3.0 - 2.0 * t);
    fragColor = mix(a, b, t);
}

void main() {
    transitionMain();
    fragColor *= qt_Opacity;
}
