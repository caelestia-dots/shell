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

const bool direction = true;
const float lumaThreshold = 0.65;
const bool above = false;

float rand(vec2 co) { return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453); }

vec3 mod289v3(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }

vec2 mod289v2(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }

vec3 permute(vec3 x) { return mod289v3(((x * 34.0) + 1.0) * x); }

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
    vec2 i = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289v2(i);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

float luminance(vec4 color) { return color.r * 0.299 + color.g * 0.587 + color.b * 0.114; }

void transitionMain() {
    vec2 center = vec2(1.0, direction ? 1.0 : 0.0);
    vec2 p = qt_TexCoord0;
    if (progress == 0.0) { fragColor = texture(from, p); return; }
    if (progress == 1.0) { fragColor = texture(to, p); return; }
    float x = progress;
    float dist = distance(center, p) - progress * exp(snoise(vec2(p.x, 0.0)));
    float r = x - rand(vec2(p.x, 0.1));
    float m;
    if (above) {
        m = (dist <= r && luminance(texture(from, p)) > lumaThreshold) ? 1.0 : (progress * progress * progress);
    } else {
        m = (dist <= r && luminance(texture(from, p)) < lumaThreshold) ? 1.0 : (progress * progress * progress);
    }
    fragColor = mix(texture(from, p), texture(to, p), m);
}

void main() {
    transitionMain();
    fragColor *= qt_Opacity;
}
