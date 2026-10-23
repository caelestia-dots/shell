#pragma once

#include <qcolor.h>
#include <qpointer.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qscopedpointer.h>
#include <qsgmaterial.h>
#include <qsgmaterialshader.h>
#include <qsgnode.h>
#include <qsgtexture.h>
#include <qsgtextureprovider.h>

namespace caelestia::shell::components {

class RoundedMaskNode;

class RoundedMask : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQuickItem* source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(qreal topLeftRadius READ topLeftRadius WRITE setTopLeftRadius NOTIFY topLeftRadiusChanged)
    Q_PROPERTY(qreal topRightRadius READ topRightRadius WRITE setTopRightRadius NOTIFY topRightRadiusChanged)
    Q_PROPERTY(
        qreal bottomRightRadius READ bottomRightRadius WRITE setBottomRightRadius NOTIFY bottomRightRadiusChanged)
    Q_PROPERTY(qreal bottomLeftRadius READ bottomLeftRadius WRITE setBottomLeftRadius NOTIFY bottomLeftRadiusChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)

public:
    explicit RoundedMask(QQuickItem* parent = nullptr);

    [[nodiscard]] QQuickItem* source() const;
    void setSource(QQuickItem* source);

    [[nodiscard]] qreal topLeftRadius() const;
    void setTopLeftRadius(qreal radius);

    [[nodiscard]] qreal topRightRadius() const;
    void setTopRightRadius(qreal radius);

    [[nodiscard]] qreal bottomRightRadius() const;
    void setBottomRightRadius(qreal radius);

    [[nodiscard]] qreal bottomLeftRadius() const;
    void setBottomLeftRadius(qreal radius);

    [[nodiscard]] QColor color() const;
    void setColor(const QColor& color);

signals:
    void sourceChanged();
    void topLeftRadiusChanged();
    void topRightRadiusChanged();
    void bottomRightRadiusChanged();
    void bottomLeftRadiusChanged();
    void colorChanged();

protected:
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data) override;
    void geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) override;
    void releaseResources() override;

private slots:
    void invalidateSceneGraph();

private:
    void watchProvider(QSGTextureProvider* provider);
    bool updateRadius(qreal& member, qreal radius);

    QPointer<QQuickItem> m_source;
    qreal m_topLeftRadius = 0;
    qreal m_topRightRadius = 0;
    qreal m_bottomRightRadius = 0;
    qreal m_bottomLeftRadius = 0;
    QColor m_color = Qt::transparent;
    // Render-thread state: the provider and node live and die on the render thread
    QSGTextureProvider* m_provider = nullptr;
    RoundedMaskNode* m_node = nullptr;
};

class RoundedMaskMaterial : public QSGMaterial {
public:
    [[nodiscard]] QSGMaterialType* type() const override;
    [[nodiscard]] QSGMaterialShader* createShader(QSGRendererInterface::RenderMode mode) const override;
    int compare(const QSGMaterial* other) const override;

    QSGTexture* m_texture = nullptr;
    QScopedPointer<QSGTexture> m_fallback;
    // device pixels; laid out as in the shader's uniform block
    float m_size[2] = {};
    float m_radii[4] = {};
    float m_color[4] = {};
};

class RoundedMaskMaterialShader : public QSGMaterialShader {
public:
    RoundedMaskMaterialShader();

    bool updateUniformData(RenderState& state, QSGMaterial* newMaterial, QSGMaterial* oldMaterial) override;
    void updateSampledImage(RenderState& state, int binding, QSGTexture** texture, QSGMaterial* newMaterial,
        QSGMaterial* oldMaterial) override;
};

class RoundedMaskNode : public QSGGeometryNode {
public:
    RoundedMaskNode();

    void preprocess() override;
};

} // namespace caelestia::shell::components
