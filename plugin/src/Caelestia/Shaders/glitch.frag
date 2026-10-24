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
    vec2 p = qt_TexCoord0;
    vec2 block = floor(p.xy / vec2(16.0));
    vec2 uvNoise = block / vec2(64.0);
    uvNoise += floor(vec2(progress) * vec2(1200.0, 3500.0)) / vec2(64.0);
    vec2 dist = progress > 0.0 ? (fract(uvNoise) - 0.5) * 0.3 * (1.0 - progress) : vec2(0.0);
    vec2 red = p + dist * 0.2;
    vec2 green = p + dist * 0.3;
    vec2 blue = p + dist * 0.5;
    fragColor = vec4(
        mix(texture(from, red), texture(to, red), progress).r,
        mix(texture(from, green), texture(to, green), progress).g,
        mix(texture(from, blue), texture(to, blue), progress).b,
        1.0
    );
}

void main() {
    transitionMain();
    fragColor *= qt_Opacity;
}
