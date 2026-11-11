#pragma once

#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qsgmaterial.h>
#include <qsgmaterialshader.h>
#include <qsgnode.h>

namespace caelestia::shell::components {

class OklchWheel : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(qreal ringWidth READ ringWidth WRITE setRingWidth NOTIFY ringWidthChanged)
    Q_PROPERTY(qreal gap READ gap WRITE setGap NOTIFY gapChanged)
    Q_PROPERTY(qreal hue READ hue WRITE setHue NOTIFY hueChanged)
    Q_PROPERTY(qreal cornerRadius READ cornerRadius WRITE setCornerRadius NOTIFY cornerRadiusChanged)

public:
    explicit OklchWheel(QQuickItem* parent = nullptr);

    [[nodiscard]] qreal ringWidth() const;
    void setRingWidth(qreal ringWidth);

    [[nodiscard]] qreal gap() const;
    void setGap(qreal gap);

    [[nodiscard]] qreal hue() const;
    void setHue(qreal hue);

    [[nodiscard]] qreal cornerRadius() const;
    void setCornerRadius(qreal cornerRadius);

signals:
    void ringWidthChanged();
    void gapChanged();
    void hueChanged();
    void cornerRadiusChanged();

protected:
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data) override;
    void geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) override;

private:
    bool updateReal(qreal& member, qreal value);

    qreal m_ringWidth = 16;
    qreal m_gap = 8;
    qreal m_hue = 0;
    qreal m_cornerRadius = 8;
};

class OklchWheelMaterial : public QSGMaterial {
public:
    [[nodiscard]] QSGMaterialType* type() const override;
    [[nodiscard]] QSGMaterialShader* createShader(QSGRendererInterface::RenderMode mode) const override;
    int compare(const QSGMaterial* other) const override;

    // Laid out as in the shader's uniform block, after the matrix and opacity
    float m_size[2] = {};
    float m_ringWidth = 0;
    float m_gap = 0;
    float m_hue = 0;
    float m_cornerRadius = 0;
};

class OklchWheelMaterialShader : public QSGMaterialShader {
public:
    OklchWheelMaterialShader();

    bool updateUniformData(RenderState& state, QSGMaterial* newMaterial, QSGMaterial* oldMaterial) override;
};

} // namespace caelestia::shell::components
