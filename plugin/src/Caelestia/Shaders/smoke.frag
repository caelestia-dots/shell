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

float fbm(vec2 p) {
    float v = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 6; i++) {
        v += amp * noise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return v;
}

vec2 warpR;

float warpedFbm(vec2 p, float t) {
    vec2 q = vec2(fbm(p), fbm(p + vec2(5.2, 1.3)));
    warpR = vec2(fbm(p + 6.0 * q + vec2(1.7, 9.2) + 0.25 * t),
                  fbm(p + 6.0 * q + vec2(8.3, 2.8) + 0.22 * t));
    return fbm(p + 5.0 * warpR);
}

void transitionMain() {
    float p = progress;
    vec2 uv = qt_TexCoord0;
    float t = p * 12.0;
    float fluid = warpedFbm(uv * 2.0, t);
    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));
    float visibility = (1.0 - dist) * 1.2 + fluid * 0.7;
    float revealProgress = p * 2.5 - 0.4;
    float revealMask = smoothstep(visibility - 0.4, visibility + 0.4, revealProgress);
    float distortStrength = sin(p * 3.14159) * 0.35;
    vec2 warpedUv = uv + (warpR - 0.5) * distortStrength;
    vec4 a = texture(from, warpedUv);
    vec4 b = texture(to, warpedUv);
    fragColor = mix(a, b, revealMask);
}

void main() {
    transitionMain();
    fragColor *= qt_Opacity;
}
