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
    float p = progress;
    float intensity = sin(p * 3.14159);
    vec2 c = qt_TexCoord0 - vec2(0.5);
    vec2 dir = c * intensity * 0.15;
    vec3 oldc = vec3(
        texture(from, qt_TexCoord0 + dir).r,
        texture(from, qt_TexCoord0).g,
        texture(from, qt_TexCoord0 - dir).b
    );
    vec3 newc = vec3(
        texture(to, qt_TexCoord0 + dir).r,
        texture(to, qt_TexCoord0).g,
        texture(to, qt_TexCoord0 - dir).b
    );
    vec3 mixed = mix(oldc, newc, smoothstep(0.4, 0.6, p));
    vec3 bloom = vec3(0.0);
    for (int i = 1; i <= 4; i++) {
        float r = float(i) * 0.01 * intensity;
        bloom += texture(to, qt_TexCoord0 + vec2(r, 0.0)).rgb;
        bloom += texture(to, qt_TexCoord0 - vec2(r, 0.0)).rgb;
        bloom += texture(to, qt_TexCoord0 + vec2(0.0, r)).rgb;
        bloom += texture(to, qt_TexCoord0 - vec2(0.0, r)).rgb;
    }
    bloom /= 16.0;
    mixed = mix(mixed, mixed + bloom * 0.5, intensity);
    fragColor = vec4(mixed, 1.0);
}

void main() {
    transitionMain();
    fragColor *= qt_Opacity;
}
