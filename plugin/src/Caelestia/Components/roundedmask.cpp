#include "roundedmask.hpp"

#include <qimage.h>
#include <qquickwindow.h>
#include <qsggeometry.h>

#include <algorithm>
#include <cstring>

namespace caelestia::components {

using Qt::StringLiterals::operator""_s;

RoundedMask::RoundedMask(QQuickItem* parent)
    : QQuickItem(parent) {
    setFlag(ItemHasContents);
}

QQuickItem* RoundedMask::source() const {
    return m_source;
}

void RoundedMask::setSource(QQuickItem* source) {
    if (m_source == source)
        return;

    m_source = source;
    emit sourceChanged();
    update();
}

qreal RoundedMask::topLeftRadius() const {
    return m_topLeftRadius;
}

void RoundedMask::setTopLeftRadius(qreal radius) {
    if (updateRadius(m_topLeftRadius, radius))
        emit topLeftRadiusChanged();
}

qreal RoundedMask::topRightRadius() const {
    return m_topRightRadius;
}

void RoundedMask::setTopRightRadius(qreal radius) {
    if (updateRadius(m_topRightRadius, radius))
        emit topRightRadiusChanged();
}

qreal RoundedMask::bottomRightRadius() const {
    return m_bottomRightRadius;
}

void RoundedMask::setBottomRightRadius(qreal radius) {
    if (updateRadius(m_bottomRightRadius, radius))
        emit bottomRightRadiusChanged();
}

qreal RoundedMask::bottomLeftRadius() const {
    return m_bottomLeftRadius;
}

void RoundedMask::setBottomLeftRadius(qreal radius) {
    if (updateRadius(m_bottomLeftRadius, radius))
        emit bottomLeftRadiusChanged();
}

bool RoundedMask::updateRadius(qreal& member, qreal radius) {
    if (qFuzzyCompare(member + 1.0, radius + 1.0))
        return false;

    member = radius;
    update();
    return true;
}

QColor RoundedMask::color() const {
    return m_color;
}

void RoundedMask::setColor(const QColor& color) {
    if (m_color == color)
        return;

    m_color = color;
    emit colorChanged();
    update();
}

void RoundedMask::geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) {
    QQuickItem::geometryChange(newGeometry, oldGeometry);
    if (newGeometry.size() != oldGeometry.size())
        update();
}

void RoundedMask::releaseResources() {
    m_node = nullptr;
}

void RoundedMask::invalidateSceneGraph() {
    m_node = nullptr;
}

void RoundedMask::watchProvider(QSGTextureProvider* provider) {
    if (m_provider == provider)
        return;

    if (m_provider)
        QObject::disconnect(m_provider, nullptr, this, nullptr);

    m_provider = provider;
    if (!m_provider)
        return;

    QObject::connect(m_provider, &QSGTextureProvider::textureChanged, this, &QQuickItem::update);
    // Emitted on the render thread by the provider's cleanup job; drop the texture before it is rendered again
    QObject::connect(
        m_provider, &QObject::destroyed, this,
        [this] {
            m_provider = nullptr;
            if (m_node) {
                static_cast<RoundedMaskMaterial*>(m_node->material())->m_texture = nullptr;
                m_node->markDirty(QSGNode::DirtyMaterial);
            }
            update();
        },
        Qt::DirectConnection);
}

QSGNode* RoundedMask::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data) {
    Q_UNUSED(data);

    auto* const provider = m_source && m_source->isTextureProvider() ? m_source->textureProvider() : nullptr;
    watchProvider(provider);

    auto* const texture = provider ? provider->texture() : nullptr;
    if (!texture || width() <= 0 || height() <= 0) {
        delete oldNode;
        m_node = nullptr;
        return nullptr;
    }

    auto* node = static_cast<RoundedMaskNode*>(oldNode);
    if (!node)
        node = new RoundedMaskNode;
    m_node = node;

    QSGGeometry::updateTexturedRectGeometry(node->geometry(), boundingRect(), QRectF(0, 0, 1, 1));
    node->markDirty(QSGNode::DirtyGeometry);

    const auto dpr = static_cast<float>(window()->effectiveDevicePixelRatio());
    auto* const material = static_cast<RoundedMaskMaterial*>(node->material());
    if (!material->m_fallback) {
        QImage blank(1, 1, QImage::Format_RGBA8888_Premultiplied);
        blank.fill(Qt::transparent);
        material->m_fallback.reset(window()->createTextureFromImage(blank));
    }
    material->m_texture = texture;
    material->m_size[0] = static_cast<float>(width()) * dpr;
    material->m_size[1] = static_cast<float>(height()) * dpr;
    const auto maxRadius = static_cast<float>(std::min(width(), height()) / 2);
    const auto clampRadius = [&](qreal radius) {
        return std::clamp(static_cast<float>(radius), 0.0f, maxRadius) * dpr;
    };
    material->m_radii[0] = clampRadius(m_topLeftRadius);
    material->m_radii[1] = clampRadius(m_topRightRadius);
    material->m_radii[2] = clampRadius(m_bottomRightRadius);
    material->m_radii[3] = clampRadius(m_bottomLeftRadius);
    const auto alpha = m_color.alphaF();
    material->m_color[0] = m_color.redF() * alpha;
    material->m_color[1] = m_color.greenF() * alpha;
    material->m_color[2] = m_color.blueF() * alpha;
    material->m_color[3] = alpha;
    node->markDirty(QSGNode::DirtyMaterial);

    return node;
}

QSGMaterialType* RoundedMaskMaterial::type() const {
    static QSGMaterialType s_type;
    return &s_type;
}

QSGMaterialShader* RoundedMaskMaterial::createShader(QSGRendererInterface::RenderMode mode) const {
    Q_UNUSED(mode);
    return new RoundedMaskMaterialShader;
}

int RoundedMaskMaterial::compare(const QSGMaterial* other) const {
    const auto* const o = static_cast<const RoundedMaskMaterial*>(other);
    if (m_texture != o->m_texture)
        return m_texture < o->m_texture ? -1 : 1;

    const auto fuzzyEqual = [](float a, float b) {
        return qFuzzyCompare(a + 1.0f, b + 1.0f);
    };
    if (!std::ranges::equal(m_size, o->m_size, fuzzyEqual) || !std::ranges::equal(m_radii, o->m_radii, fuzzyEqual) ||
        !std::ranges::equal(m_color, o->m_color, fuzzyEqual))
        return this < other ? -1 : 1;
    return 0;
}

RoundedMaskMaterialShader::RoundedMaskMaterialShader() {
    setShaderFileName(VertexStage, u":/shaders/roundedmask.vert.qsb"_s);
    setShaderFileName(FragmentStage, u":/shaders/roundedmask.frag.qsb"_s);
}

bool RoundedMaskMaterialShader::updateUniformData(
    RenderState& state, QSGMaterial* newMaterial, QSGMaterial* oldMaterial) {
    Q_UNUSED(oldMaterial);
    auto* const mat = static_cast<RoundedMaskMaterial*>(newMaterial);
    QByteArray* const buf = state.uniformData();
    Q_ASSERT(buf->size() >= 112);

    if (state.isMatrixDirty()) {
        const QMatrix4x4 m = state.combinedMatrix();
        std::memcpy(buf->data(), m.constData(), 64);
    }
    if (state.isOpacityDirty()) {
        const float opacity = state.opacity();
        std::memcpy(buf->data() + 64, &opacity, 4);
    }

    std::memcpy(buf->data() + 72, mat->m_size, 8);
    std::memcpy(buf->data() + 80, mat->m_radii, 16);
    std::memcpy(buf->data() + 96, mat->m_color, 16);
    return true;
}

void RoundedMaskMaterialShader::updateSampledImage(
    RenderState& state, int binding, QSGTexture** texture, QSGMaterial* newMaterial, QSGMaterial* oldMaterial) {
    Q_UNUSED(oldMaterial);
    if (binding != 1)
        return;

    const auto* const mat = static_cast<const RoundedMaskMaterial*>(newMaterial);
    auto* const tex = mat->m_texture ? mat->m_texture : mat->m_fallback.data();
    tex->commitTextureOperations(state.rhi(), state.resourceUpdateBatch());
    *texture = tex;
}

RoundedMaskNode::RoundedMaskNode() {
    auto* const geometry = new QSGGeometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), 4);
    geometry->setDrawingMode(QSGGeometry::DrawTriangleStrip);
    setGeometry(geometry);
    setFlag(OwnsGeometry);

    auto* const material = new RoundedMaskMaterial;
    material->setFlag(QSGMaterial::Blending);
    setMaterial(material);
    setFlag(OwnsMaterial);
    setFlag(UsePreprocess);
}

void RoundedMaskNode::preprocess() {
    auto* const texture = qobject_cast<QSGDynamicTexture*>(static_cast<RoundedMaskMaterial*>(material())->m_texture);
    if (texture && texture->updateTexture())
        markDirty(DirtyMaterial);
}

} // namespace caelestia::components
