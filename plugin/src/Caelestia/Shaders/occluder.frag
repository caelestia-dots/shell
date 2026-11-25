#version 440
// Derived from Hyprland's rounding.glsl, BSD-3-Clause, (c) 2022-2026 vaxerski.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    vec2  fullSize;
    float radius;
    float roundingPower;
    vec4  value; // alpha always 0: blending would scale the rgb bitmask
};

float pnorm(vec2 v, float p) {
    return pow(pow(v.x, p) + pow(v.y, p), 1.0 / p);
}

void main() {
    vec2 original = qt_TexCoord0 * fullSize;

    vec2 mirrored = original - fullSize * 0.5;
    mirrored *= vec2(lessThan(mirrored, vec2(0.0))) * -2.0 + 1.0;

    vec2 inner = mirrored - (fullSize * 0.5 - radius) + vec2(1.0) / fullSize;

    // hard edge: a partial weight would corrupt the bitmask
    if (min(inner.x, inner.y) > 0.0 && radius > 0.0 && pnorm(inner, roundingPower) > radius)
        discard;

    fragColor = value;
}
