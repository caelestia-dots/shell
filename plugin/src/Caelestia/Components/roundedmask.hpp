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

namespace caelestia::components {

class RoundedMaskNode;

class RoundedMask : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQuickItem* source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(qreal radius READ radius WRITE setRadius NOTIFY radiusChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)

public:
    explicit RoundedMask(QQuickItem* parent = nullptr);

    [[nodiscard]] QQuickItem* source() const;
    void setSource(QQuickItem* source);

    [[nodiscard]] qreal radius() const;
    void setRadius(qreal radius);

    [[nodiscard]] QColor color() const;
    void setColor(const QColor& color);

signals:
    void sourceChanged();
    void radiusChanged();
    void colorChanged();

protected:
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data) override;
    void geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) override;
    void releaseResources() override;

private slots:
    void invalidateSceneGraph();

private:
    void watchProvider(QSGTextureProvider* provider);

    QPointer<QQuickItem> m_source;
    qreal m_radius = 0;
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
    // radius, width, height in device pixels; laid out as in the shader's uniform block
    float m_params[3] = {};
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

} // namespace caelestia::components
