#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;        // device pixels
    float ringWidth;  // device pixels
    float gap;        // device pixels, between ring and triangle
    float hue;        // degrees, triangle hue
    float cornerRadius; // device pixels, mask only
};

const float PI = 3.14159265358979;
const float SQRT3 = 1.73205080756888;

vec3 oklchToLinear(float l, float c, float h) {
    float rad = h * PI / 180.0;
    float a = c * cos(rad);
    float b = c * sin(rad);

    float l_ = l + 0.3963377774 * a + 0.2158037573 * b;
    float m_ = l - 0.1055613458 * a - 0.0638541728 * b;
    float s_ = l - 0.0894841775 * a - 1.2914855480 * b;
    l_ = l_ * l_ * l_;
    m_ = m_ * m_ * m_;
    s_ = s_ * s_ * s_;

    return vec3(
        4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_,
        -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_,
        -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_);
}

bool inGamut(vec3 rgb) {
    return all(greaterThanEqual(rgb, vec3(0.0))) && all(lessThanEqual(rgb, vec3(1.0)));
}

float maxChroma(float l, float h) {
    float lo = 0.0;
    float hi = 0.4;
    for (int i = 0; i < 16; ++i) {
        float mid = (lo + hi) * 0.5;
        if (inGamut(oklchToLinear(l, mid, h)))
            lo = mid;
        else
            hi = mid;
    }
    return lo;
}

vec3 toSrgb(vec3 v) {
    v = clamp(v, 0.0, 1.0);
    return mix(v * 12.92, 1.055 * pow(v, vec3(1.0 / 2.4)) - 0.055, step(0.0031308, v));
}

// Exact signed distance to a triangle (Inigo Quilez), negative inside
float sdTriangle(vec2 p, vec2 p0, vec2 p1, vec2 p2) {
    vec2 e0 = p1 - p0, e1 = p2 - p1, e2 = p0 - p2;
    vec2 v0 = p - p0, v1 = p - p1, v2 = p - p2;
    vec2 pq0 = v0 - e0 * clamp(dot(v0, e0) / dot(e0, e0), 0.0, 1.0);
    vec2 pq1 = v1 - e1 * clamp(dot(v1, e1) / dot(e1, e1), 0.0, 1.0);
    vec2 pq2 = v2 - e2 * clamp(dot(v2, e2) / dot(e2, e2), 0.0, 1.0);
    float s = sign(e0.x * e2.y - e0.y * e2.x);
    vec2 d = min(min(vec2(dot(pq0, pq0), s * (v0.x * e0.y - v0.y * e0.x)),
                     vec2(dot(pq1, pq1), s * (v1.x * e1.y - v1.y * e1.x))),
                 vec2(dot(pq2, pq2), s * (v2.x * e2.y - v2.y * e2.x)));
    return -sqrt(d.x) * sign(d.y);
}

void main() {
    // Centered, y up, in device pixels
    vec2 p = (qt_TexCoord0 - 0.5) * size * vec2(1.0, -1.0);
    // Keep the antialiased edge inside the item, the quad clips anything beyond it
    float outer = min(size.x, size.y) * 0.5 - 1.0;
    float inner = outer - ringWidth;
    float r = length(p);

    float ringMask = smoothstep(inner - 0.5, inner + 0.5, r) * (1.0 - smoothstep(outer - 0.5, outer + 0.5, r));
    float ringHue = degrees(atan(p.y, p.x));
    vec3 ringRgb = oklchToLinear(0.72, 0.11, ringHue);

    // Equilateral triangle inscribed in the circle inside the gap, tip to the right
    float tr = inner - gap;
    vec2 tip = vec2(tr, 0.0);
    vec2 top = vec2(-tr * 0.5, tr * SQRT3 * 0.5);
    vec2 bottom = vec2(-tr * 0.5, -tr * SQRT3 * 0.5);
    // Mask against the triangle inset by the corner radius, then grow it back out, which rounds the corners
    float ir = tr - 2.0 * cornerRadius;
    vec2 itip = vec2(ir, 0.0);
    vec2 itop = vec2(-ir * 0.5, ir * SQRT3 * 0.5);
    vec2 ibottom = vec2(-ir * 0.5, -ir * SQRT3 * 0.5);
    float d = sdTriangle(p, itop, itip, ibottom) - cornerRadius;
    float triMask = 1.0 - smoothstep(-0.5, 0.5, d);

    float l = clamp((p.y - bottom.y) / (tr * SQRT3), 0.0, 1.0);
    float rowWidth = tr * 1.5 * (1.0 - abs(2.0 * l - 1.0));
    float f = rowWidth > 0.0 ? clamp((p.x - top.x) / rowWidth, 0.0, 1.0) : 0.0;
    vec3 triRgb = oklchToLinear(l, f * maxChroma(l, hue), hue);

    vec4 ring = vec4(toSrgb(ringRgb), 1.0) * ringMask;
    vec4 tri = vec4(toSrgb(triRgb), 1.0) * triMask;
    fragColor = (ring + tri * (1.0 - ring.a)) * qt_Opacity;
}
