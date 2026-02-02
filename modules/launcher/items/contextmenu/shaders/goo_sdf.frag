#version 440
layout(location = 0) in vec2 vUv;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    vec2 sizePx;
    vec4 menuRectPx;
    vec4 subRectPx;
    float radiusPx;
    float smoothPxTop;
    float smoothPxBottom;

    vec4 fillColor;
    vec4 shadowColor;
    vec2 shadowOffsetPx;
    float shadowSoftPx;
} ubuf;

// distance to rounded rectangle (centered at origin)
float sdRoundRect(vec2 p, vec2 b, float r) {
    // b = half-size
    vec2 q = abs(p) - (b - vec2(r));
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// smooth union (goo)
float smin(float a, float b, float k) {
    // k in pixels-ish
    float h = clamp(0.5 + 0.5*(b - a)/k, 0.0, 1.0);
    return mix(b, a, h) - k*h*(1.0 - h);
}

vec4 premul(vec4 c) { return vec4(c.rgb * c.a, c.a); }

void main() {
    // local pixel coords in this effect item
    vec2 p = vUv * ubuf.sizePx;

    // menu rect SDF
    vec2 mPos = ubuf.menuRectPx.xy;
    vec2 mSize = ubuf.menuRectPx.zw;
    vec2 mCenter = mPos + mSize * 0.5;
    float dm = sdRoundRect(p - mCenter, mSize * 0.5, ubuf.radiusPx);

    // optional submenu rect SDF
    float d = dm;
    if (ubuf.subRectPx.z > 0.0 && ubuf.subRectPx.w > 0.0) {
        vec2 sPos = ubuf.subRectPx.xy;
        vec2 sSize = ubuf.subRectPx.zw;
        vec2 sCenter = sPos + sSize * 0.5;
        float ds = sdRoundRect(p - sCenter, sSize * 0.5, ubuf.radiusPx);

        // Interpolate smoothing based on Y position
        // Calculate merge point Y (where the shapes meet)
        float mergeY = (mCenter.y + sCenter.y) * 0.5;
        
        // Interpolate smoothing: top uses smoothPxTop, bottom uses smoothPxBottom
        float t = clamp((p.y - mergeY) / max(1.0, abs(mCenter.y - sCenter.y)), 0.0, 1.0);
        float smoothPx = mix(ubuf.smoothPxTop, ubuf.smoothPxBottom, t);
        
        // smooth union or hard union (straight line when smoothPx <= 0)
        if (smoothPx > 0.0) {
            d = smin(dm, ds, max(1.0, smoothPx));
        } else {
            d = min(dm, ds);
        }
    }

    // Fill alpha: inside shape => 1, outside => 0 with soft edge
    float edge = 1.0;
    float fillA = 1.0 - smoothstep(0.0, edge, d);

    // Shadow: evaluate SDF with an offset, soften more
    vec2 ps = p - ubuf.shadowOffsetPx;
    float dmS = sdRoundRect(ps - mCenter, mSize * 0.5, ubuf.radiusPx);
    float dS = dmS;
    if (ubuf.subRectPx.z > 0.0 && ubuf.subRectPx.w > 0.0) {
        vec2 sPos = ubuf.subRectPx.xy;
        vec2 sSize = ubuf.subRectPx.zw;
        vec2 sCenter = sPos + sSize * 0.5;
        float dsS = sdRoundRect(ps - sCenter, sSize * 0.5, ubuf.radiusPx);
        // Use same interpolated smoothing for shadow
        float mergeY = (mCenter.y + sCenter.y) * 0.5;
        float t = clamp((ps.y - mergeY) / max(1.0, abs(mCenter.y - sCenter.y)), 0.0, 1.0);
        float smoothPx = mix(ubuf.smoothPxTop, ubuf.smoothPxBottom, t);
        
        if (smoothPx > 0.0) {
            dS = smin(dmS, dsS, max(1.0, smoothPx));
        } else {
            dS = min(dmS, dsS);
        }
    }
    // Start shadow closer (-2px) but fade over longer distance (2x softness)
    float sh = 1.0 - smoothstep(-2.0, ubuf.shadowSoftPx * 2.0, dS);
    float shadowOnly = max(sh - fillA, 0.0);

    vec4 f = premul(ubuf.fillColor);
    vec4 s = premul(ubuf.shadowColor);

    vec4 outC = f * fillA + s * shadowOnly;
    fragColor = outC * ubuf.qt_Opacity;
}
