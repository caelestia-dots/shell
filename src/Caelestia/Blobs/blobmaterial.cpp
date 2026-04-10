#include "blobmaterial.hpp"

#include <cstring>

QSGMaterialType* BlobMaterial::type() const {
    static QSGMaterialType s_type;
    return &s_type;
}

QSGMaterialShader* BlobMaterial::createShader(QSGRendererInterface::RenderMode) const {
    return new BlobMaterialShader;
}

int BlobMaterial::compare(const QSGMaterial* other) const {
    if (this < other)
        return -1;
    if (this > other)
        return 1;
    return 0;
}

BlobMaterialShader::BlobMaterialShader() {
    setShaderFileName(VertexStage, QStringLiteral(":/shaders/blob.vert.qsb"));
    setShaderFileName(FragmentStage, QStringLiteral(":/shaders/blob.frag.qsb"));
}

bool BlobMaterialShader::updateUniformData(RenderState& state, QSGMaterial* newMaterial, QSGMaterial* oldMaterial) {
    Q_UNUSED(oldMaterial);
    auto* mat = static_cast<BlobMaterial*>(newMaterial);
    QByteArray* buf = state.uniformData();
    Q_ASSERT(buf->size() >= 1440);

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
        static_cast<float>(mat->m_color.redF()),
        static_cast<float>(mat->m_color.greenF()),
        static_cast<float>(mat->m_color.blueF()),
        static_cast<float>(mat->m_color.alphaF()),
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

    // Rect data (offset 160, each rect = 5 vec4s = 80 bytes)
    const int count = qMin(mat->m_rectCount, 16);
    for (int i = 0; i < count; ++i) {
        const auto& r = mat->m_rects[i];
        const int base = 160 + i * 80;
        const float d0[4] = { r.cx, r.cy, r.hw, r.hh };
        const float d1[4] = { 0.0f, r.offsetX, r.offsetY, r.minEig };
        const float d3[4] = { r.screenHalfX, r.screenHalfY, 0.0f, 0.0f };
        memcpy(buf->data() + base, d0, 16);
        memcpy(buf->data() + base + 16, d1, 16);
        memcpy(buf->data() + base + 32, r.invDeform, 16);
        memcpy(buf->data() + base + 48, d3, 16);
        memcpy(buf->data() + base + 64, r.radius, 16);
    }

    return true;
}
