#include "oklchwheel.hpp"

#include <qquickwindow.h>
#include <qsggeometry.h>

#include <algorithm>
#include <cstring>

namespace caelestia::shell::components {

using Qt::StringLiterals::operator""_s;

OklchWheel::OklchWheel(QQuickItem* parent)
    : QQuickItem(parent) {
    setFlag(ItemHasContents);
}

qreal OklchWheel::ringWidth() const {
    return m_ringWidth;
}

void OklchWheel::setRingWidth(qreal ringWidth) {
    if (updateReal(m_ringWidth, ringWidth))
        emit ringWidthChanged();
}

qreal OklchWheel::gap() const {
    return m_gap;
}

void OklchWheel::setGap(qreal gap) {
    if (updateReal(m_gap, gap))
        emit gapChanged();
}

qreal OklchWheel::hue() const {
    return m_hue;
}

void OklchWheel::setHue(qreal hue) {
    if (updateReal(m_hue, hue))
        emit hueChanged();
}

qreal OklchWheel::cornerRadius() const {
    return m_cornerRadius;
}

void OklchWheel::setCornerRadius(qreal cornerRadius) {
    if (updateReal(m_cornerRadius, cornerRadius))
        emit cornerRadiusChanged();
}

qreal OklchWheel::outerRadius() const {
    return m_outerRadius;
}

qreal OklchWheel::ringLightness() {
    return k_ringLightness;
}

qreal OklchWheel::ringChroma() {
    return k_ringChroma;
}

bool OklchWheel::updateReal(qreal& member, qreal value) {
    if (qFuzzyCompare(member + 1.0, value + 1.0))
        return false;

    member = value;
    update();
    return true;
}

void OklchWheel::geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) {
    QQuickItem::geometryChange(newGeometry, oldGeometry);
    if (newGeometry.size() == oldGeometry.size())
        return;

    // Inset by 1px so the antialiased edge stays inside the item
    const auto radius = std::min(newGeometry.width(), newGeometry.height()) / 2 - 1;
    if (!qFuzzyCompare(m_outerRadius + 1.0, radius + 1.0)) {
        m_outerRadius = radius;
        emit outerRadiusChanged();
    }
    update();
}

QSGNode* OklchWheel::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data) {
    Q_UNUSED(data);

    if (width() <= 0 || height() <= 0) {
        delete oldNode;
        return nullptr;
    }

    auto* node = static_cast<QSGGeometryNode*>(oldNode);
    if (!node) {
        node = new QSGGeometryNode;
        auto* const geometry = new QSGGeometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), 4);
        geometry->setDrawingMode(QSGGeometry::DrawTriangleStrip);
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);

        auto* const material = new OklchWheelMaterial;
        material->setFlag(QSGMaterial::Blending);
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);
    }

    QSGGeometry::updateTexturedRectGeometry(node->geometry(), boundingRect(), QRectF(0, 0, 1, 1));
    node->markDirty(QSGNode::DirtyGeometry);

    const auto dpr = static_cast<float>(window()->effectiveDevicePixelRatio());
    auto* const material = static_cast<OklchWheelMaterial*>(node->material());
    material->m_size[0] = static_cast<float>(width()) * dpr;
    material->m_size[1] = static_cast<float>(height()) * dpr;
    material->m_ringWidth = static_cast<float>(m_ringWidth) * dpr;
    material->m_gap = static_cast<float>(m_gap) * dpr;
    material->m_hue = static_cast<float>(m_hue);
    material->m_cornerRadius = static_cast<float>(m_cornerRadius) * dpr;
    material->m_outerRadius = static_cast<float>(m_outerRadius) * dpr;
    material->m_ringLightness = static_cast<float>(k_ringLightness);
    material->m_ringChroma = static_cast<float>(k_ringChroma);
    node->markDirty(QSGNode::DirtyMaterial);

    return node;
}

QSGMaterialType* OklchWheelMaterial::type() const {
    static QSGMaterialType s_type;
    return &s_type;
}

QSGMaterialShader* OklchWheelMaterial::createShader(QSGRendererInterface::RenderMode mode) const {
    Q_UNUSED(mode);
    return new OklchWheelMaterialShader;
}

int OklchWheelMaterial::compare(const QSGMaterial* other) const {
    const auto* const o = static_cast<const OklchWheelMaterial*>(other);
    const auto fuzzyEqual = [](float a, float b) {
        return qFuzzyCompare(a + 1.0f, b + 1.0f);
    };
    if (!std::ranges::equal(m_size, o->m_size, fuzzyEqual) || !fuzzyEqual(m_ringWidth, o->m_ringWidth) ||
        !fuzzyEqual(m_gap, o->m_gap) || !fuzzyEqual(m_hue, o->m_hue) ||
        !fuzzyEqual(m_cornerRadius, o->m_cornerRadius) || !fuzzyEqual(m_outerRadius, o->m_outerRadius))
        return this < other ? -1 : 1;
    return 0;
}

OklchWheelMaterialShader::OklchWheelMaterialShader() {
    setShaderFileName(VertexStage, u":/shaders/oklchwheel.vert.qsb"_s);
    setShaderFileName(FragmentStage, u":/shaders/oklchwheel.frag.qsb"_s);
}

bool OklchWheelMaterialShader::updateUniformData(
    RenderState& state, QSGMaterial* newMaterial, QSGMaterial* oldMaterial) {
    QByteArray* const buf = state.uniformData();
    Q_ASSERT(buf->size() >= 108);
    bool changed = false;

    if (state.isMatrixDirty()) {
        const QMatrix4x4 m = state.combinedMatrix();
        std::memcpy(buf->data(), m.constData(), 64);
        changed = true;
    }
    if (state.isOpacityDirty()) {
        const float opacity = state.opacity();
        std::memcpy(buf->data() + 64, &opacity, 4);
        changed = true;
    }

    if (!oldMaterial || newMaterial->compare(oldMaterial) != 0) {
        const auto* const mat = static_cast<OklchWheelMaterial*>(newMaterial);
        std::memcpy(buf->data() + 72, mat->m_size, 8);
        std::memcpy(buf->data() + 80, &mat->m_ringWidth, 4);
        std::memcpy(buf->data() + 84, &mat->m_gap, 4);
        std::memcpy(buf->data() + 88, &mat->m_hue, 4);
        std::memcpy(buf->data() + 92, &mat->m_cornerRadius, 4);
        std::memcpy(buf->data() + 96, &mat->m_outerRadius, 4);
        std::memcpy(buf->data() + 100, &mat->m_ringLightness, 4);
        std::memcpy(buf->data() + 104, &mat->m_ringChroma, 4);
        changed = true;
    }
    return changed;
}

} // namespace caelestia::shell::components
