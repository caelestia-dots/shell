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
    for (int i = 0; i < 5; i++) {
        v += amp * noise(p);
        p *= 2.1;
        amp *= 0.5;
    }
    return v;
}

void transitionMain() {
    float p = progress;
    float blob = fbm(qt_TexCoord0 * 3.5);
    float fingers = fbm(qt_TexCoord0 * 14.0);
    float distortion = (blob - 0.5) * 0.5 + (fingers - 0.5) * 0.18;
    vec2 c = qt_TexCoord0 - vec2(0.5);
    c.x *= 1.7777;
    float d = length(c);
    float splashDist = d + distortion;
    float boundary = p * 1.7 - 0.15;
    float diff = splashDist - boundary;
    float reveal = smoothstep(0.04, -0.04, diff);
    float edgeOuter = smoothstep(0.16, 0.02, diff);
    float edgeInner = smoothstep(0.02, -0.04, diff);
    float edge = edgeOuter * (1.0 - edgeInner);
    vec4 a = texture(from, qt_TexCoord0);
    vec4 b = texture(to, qt_TexCoord0);
    vec4 mixed = mix(a, b, reveal);
    vec3 ink = vec3(0.03, 0.01, 0.06);
    mixed.rgb = mix(mixed.rgb, ink, edge * 0.95);
    float fingersPre = smoothstep(0.25, 0.05, diff) * (1.0 - reveal);
    mixed.rgb = mix(mixed.rgb, ink, fingersPre * fingers * 0.4);
    fragColor = mixed;
}

void main() {
    transitionMain();
    fragColor *= qt_Opacity;
}
