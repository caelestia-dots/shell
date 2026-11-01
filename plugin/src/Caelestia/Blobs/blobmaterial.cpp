#include "blobmaterial.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <functional>
#include <numbers>

namespace caelestia::blobs {

using Qt::StringLiterals::operator""_s;

static_assert(sizeof(decltype(BlobRectData::excludeMask)) == sizeof(float),
    "BlobMaterial packs excludeMask into a float slot via memcpy");

QSGMaterialType* BlobMaterial::type() const {
    static QSGMaterialType s_type;
    return &s_type;
}

QSGMaterialShader* BlobMaterial::createShader(QSGRendererInterface::RenderMode mode) const {
    Q_UNUSED(mode);
    return new BlobMaterialShader;
}

int BlobMaterial::compare(const QSGMaterial* other) const {
    // std::less gives a total order for unrelated pointers, the built-in < does not
    const QSGMaterial* self = this;
    if (std::less<>{}(self, other))
        return -1;
    if (std::less<>{}(other, self))
        return 1;
    return 0;
}

BlobMaterialShader::BlobMaterialShader() {
    setShaderFileName(VertexStage, u":/shaders/blob.vert.qsb"_s);
    setShaderFileName(FragmentStage, u":/shaders/blob.frag.qsb"_s);
}

namespace {

// GLSL smoothstep
float smoothstepf(float edge0, float edge1, float x) {
    if (std::abs(edge1 - edge0) < 1e-6f)
        return x < edge0 ? 0.0f : 1.0f;
    const float t = std::clamp((x - edge0) / (edge1 - edge0), 0.0f, 1.0f);
    return t * t * (3.0f - 2.0f * t);
}

// Border terms of one rect against the inverted border. They depend only on the rect and the
// frame, never on the pixel, so they are computed once per frame here rather than per fragment
// in blob.frag. The formulas mirror the shader's, which is what the reference images check.
struct BorderTerms {
    float xProx, yProx;                      // How close the rect is to the left/right and top/bottom border
    float topPen, botPen, leftPen, rightPen; // How far the rect pushes into each border
};

BorderTerms borderTerms(const BlobRectData& r, const float inner[4], const float outer[4], float smoothFactor) {
    const float cx = r.cx + r.offsetX;
    const float cy = r.cy + r.offsetY;
    const float shx = r.screenHalfX;
    const float shy = r.screenHalfY;

    const float innerLeft = inner[0] - inner[2];
    const float innerRight = inner[0] + inner[2];
    const float innerTop = inner[1] - inner[3];
    const float innerBot = inner[1] + inner[3];
    const float outerLeft = outer[0] - outer[2];
    const float outerRight = outer[0] + outer[2];
    const float outerTop = outer[1] - outer[3];
    const float outerBot = outer[1] + outer[3];

    const float distY0 = (cy + shy) - innerTop;
    const float distY1 = innerBot - (cy - shy);
    const float distX0 = (cx + shx) - innerLeft;
    const float distX1 = innerRight - (cx - shx);

    BorderTerms t{};
    t.yProx = 1.0f - std::min(smoothstepf(0.0f, smoothFactor, distY0), smoothstepf(0.0f, smoothFactor, distY1));
    t.xProx = 1.0f - std::min(smoothstepf(0.0f, smoothFactor, distX0), smoothstepf(0.0f, smoothFactor, distX1));

    // Sink onset (see blob.frag): half the gap-closing distance of the circular blend
    const float preOff = smoothFactor * (2.0f - std::numbers::sqrt2_v<float>)*0.5f;
    t.topPen = std::clamp(innerTop - (cy + shy) - preOff, 0.0f, innerTop - outerTop);
    t.botPen = std::clamp((cy - shy) - innerBot - preOff, 0.0f, outerBot - innerBot);
    t.leftPen = std::clamp(innerLeft - (cx + shx) - preOff, 0.0f, innerLeft - outerLeft);
    t.rightPen = std::clamp((cx - shx) - innerRight - preOff, 0.0f, outerRight - innerRight);
    return t;
}

} // namespace

bool BlobMaterialShader::updateUniformData(RenderState& state, QSGMaterial* newMaterial, QSGMaterial* oldMaterial) {
    Q_UNUSED(oldMaterial);
    auto* mat = static_cast<BlobMaterial*>(newMaterial);
    QByteArray* buf = state.uniformData();
    Q_ASSERT(buf->size() >= k_uniformSize);

    if (state.isMatrixDirty()) {
        const QMatrix4x4 m = state.combinedMatrix();
        memcpy(buf->data(), m.constData(), 64);
    }
    if (state.isOpacityDirty()) {
        const float opacity = state.opacity();
        memcpy(buf->data() + 64, &opacity, 4);
    }

    // Padded rect (offset 68)
    memcpy(buf->data() + 68, &mat->m_paddedX, 4);
    memcpy(buf->data() + 72, &mat->m_paddedY, 4);
    memcpy(buf->data() + 76, &mat->m_paddedW, 4);
    memcpy(buf->data() + 80, &mat->m_paddedH, 4);

    // Smooth factor (offset 84)
    memcpy(buf->data() + 84, &mat->m_smoothFactor, 4);

    // Rect count (offset 88)
    memcpy(buf->data() + 88, &mat->m_rectCount, 4);

    // My index (offset 92)
    memcpy(buf->data() + 92, &mat->m_myIndex, 4);

    // Color as vec4 (offset 96, 16 bytes)
    const float color[4] = {
        mat->m_color.redF(),
        mat->m_color.greenF(),
        mat->m_color.blueF(),
        mat->m_color.alphaF(),
    };
    memcpy(buf->data() + 96, color, 16);

    // Has inverted (offset 112)
    memcpy(buf->data() + 112, &mat->m_hasInverted, 4);

    // Inverted radius (offset 116)
    memcpy(buf->data() + 116, &mat->m_invertedRadius, 4);

    // Padding at 120-127 (skip)

    // Inverted outer (offset 128, 16 bytes)
    memcpy(buf->data() + 128, mat->m_invertedOuter, 16);

    // Inverted inner (offset 144, 16 bytes)
    memcpy(buf->data() + 144, mat->m_invertedInner, 16);

    // Rect data (offset 160, each rect = 7 vec4s = 112 bytes, see blob.frag)
    const int count = qMin(mat->m_rectCount, k_maxRects);
    for (int i = 0; i < count; ++i) {
        const auto& r = mat->m_rects[i];
        const int base = 160 + i * k_rectStride;
        // Pack excludeMask into props.x via bit-cast (read in shader with floatBitsToInt)
        float maskAsFloat;
        memcpy(&maskAsFloat, &r.excludeMask, sizeof(float));
        const float d0[4] = { r.cx, r.cy, r.hw, r.hh };
        const float d1[4] = { maskAsFloat, r.offsetX, r.offsetY, r.minEig };
        const float d3[4] = { r.screenHalfX, r.screenHalfY, 0.0f, 0.0f };
        memcpy(buf->data() + base, d0, 16);
        memcpy(buf->data() + base + 16, d1, 16);
        memcpy(buf->data() + base + 32, r.invDeform, 16);
        memcpy(buf->data() + base + 48, d3, 16);
        memcpy(buf->data() + base + 64, r.radius, 16);

        const BorderTerms t = borderTerms(r, mat->m_invertedInner, mat->m_invertedOuter, mat->m_smoothFactor);
        const float border[4] = { t.xProx, t.yProx, t.topPen, t.botPen };
        const float sides[4] = { t.leftPen, t.rightPen, 0.0f, 0.0f };
        memcpy(buf->data() + base + 80, border, 16);
        memcpy(buf->data() + base + 96, sides, 16);
    }

    return true;
}

} // namespace caelestia::blobs
