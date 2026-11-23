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

vec2 hash2(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)),
                          dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

void transitionMain() {
    float scale = 14.0;
    vec2 p = qt_TexCoord0 * scale;
    vec2 g = floor(p);
    vec2 f = fract(p);
    float minDist = 100.0;
    vec2 cell = g;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 nb = vec2(float(x), float(y));
            vec2 q = nb + hash2(g + nb) - f;
            float d = dot(q, q);
            if (d < minDist) { minDist = d; cell = g + nb; }
        }
    }
    vec2 dir = normalize(hash2(cell) - 0.5 + vec2(0.0001));
    float seed = hash2(cell).x;
    float shardP = smoothstep(seed * 0.5, seed * 0.5 + 0.5, progress);
    vec2 displaced = qt_TexCoord0 - dir * shardP * 1.5;
    vec4 a = texture(from, displaced);
    vec4 b = texture(to, qt_TexCoord0);
    fragColor = mix(a, b, smoothstep(0.0, 0.5, shardP));
}

void main() {
    transitionMain();
    fragColor *= qt_Opacity;
}
