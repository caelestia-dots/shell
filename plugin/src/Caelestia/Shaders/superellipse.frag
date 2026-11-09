#version 440
// Derived from Hyprland's rounding.glsl and border.glsl, BSD-3-Clause, (c) 2022-2026 vaxerski.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    vec2  fullSize;       // item size, border included
    float radius;         // inner radius R
    float radiusOuter;    // R + thick - correction
    float roundingPower;
    float thick;
    vec4  fillColor;      // premultiplied
    vec4  borderColor;    // premultiplied
    vec2  screenSize;
    vec2  itemPos;        // item origin in screen space
    float ownIndex;       // stacking index, lower is above
    float hovered;
};

layout(binding = 1) uniform sampler2D occlusion; // bit (i % 8) of rgb channel (i / 8) set where window i covers, 24 windows max

const float SMOOTHING_CONSTANT = 3.1415926535897932 / 5.34665792551;

float pnorm(vec2 v, float p) {
    return pow(pow(v.x, p) + pow(v.y, p), 1.0 / p);
}

int bitsBelow(float channel, int limit) {
    int bits = int(channel * 255.0 + 0.5);
    int count = 0;
    for (int b = 0; b < 8; ++b)
        if (b < limit && (bits & (1 << b)) != 0)
            ++count;
    return count;
}

// coverage: 1 inside the curve, 0 outside, smooth across one pixel
float coverage(float dist, float r) {
    return 1.0 - smoothstep(0.0, 1.0, (dist - r + SMOOTHING_CONSTANT) / (SMOOTHING_CONSTANT * 2.0));
}

void main() {
    vec2 original = qt_TexCoord0 * fullSize;

    vec2 mirrored = original - fullSize * 0.5;
    mirrored *= vec2(lessThan(mirrored, vec2(0.0))) * -2.0 + 1.0;

    vec2 inner = mirrored - (fullSize * 0.5 - thick - radius) + vec2(1.0) / fullSize;
    vec2 outer = mirrored - (fullSize * 0.5 - radiusOuter)    + vec2(1.0) / fullSize;

    float insideFill   = 1.0;
    float insideBorder = 1.0;

    if (min(inner.x, inner.y) > 0.0 && radius > 0.0)
        insideFill = coverage(pnorm(inner, roundingPower), radius);
    else
        insideFill = step(thick, min(min(original.x, fullSize.x - original.x), min(original.y, fullSize.y - original.y)));

    if (min(outer.x, outer.y) > 0.0 && radiusOuter > 0.0)
        insideBorder = coverage(pnorm(outer, roundingPower), radiusOuter);

    if (insideBorder <= 0.0)
        discard;

    vec4 texel = texture(occlusion, (itemPos + original) / screenSize);
    int own = int(ownIndex + 0.5);
    int above = bitsBelow(texel.r, own) + bitsBelow(texel.g, own - 8) + bitsBelow(texel.b, own - 16);
    vec4 border = borderColor * pow(mix(0.2, 0.5, hovered), float(above));
    vec4 fill = fillColor * pow(0.8, float(above));

    fragColor = mix(border, fill, insideFill) * insideBorder * qt_Opacity;
}
