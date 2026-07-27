#pragma once

#include <qcolor.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qquickpainteditem.h>

namespace caelestia::internal {

class CircularBuffer;

class SparklineItem : public QQuickPaintedItem {
    Q_OBJECT
    QML_ELEMENT
    Q_MOC_INCLUDE("circularbuffer.hpp")

    Q_PROPERTY(CircularBuffer* line1 READ line1 WRITE setLine1 NOTIFY line1Changed)
    Q_PROPERTY(CircularBuffer* line2 READ line2 WRITE setLine2 NOTIFY line2Changed)
    Q_PROPERTY(QColor line1Color READ line1Color WRITE setLine1Color NOTIFY line1ColorChanged)
    Q_PROPERTY(QColor line2Color READ line2Color WRITE setLine2Color NOTIFY line2ColorChanged)
    Q_PROPERTY(qreal line1FillAlpha READ line1FillAlpha WRITE setLine1FillAlpha NOTIFY line1FillAlphaChanged)
    Q_PROPERTY(qreal line2FillAlpha READ line2FillAlpha WRITE setLine2FillAlpha NOTIFY line2FillAlphaChanged)
    Q_PROPERTY(qreal maxValue READ maxValue WRITE setMaxValue NOTIFY maxValueChanged)
    Q_PROPERTY(qreal slideProgress READ slideProgress WRITE setSlideProgress NOTIFY slideProgressChanged)
    Q_PROPERTY(int historyLength READ historyLength WRITE setHistoryLength NOTIFY historyLengthChanged)
    Q_PROPERTY(qreal lineWidth READ lineWidth WRITE setLineWidth NOTIFY lineWidthChanged)

public:
    explicit SparklineItem(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    [[nodiscard]] CircularBuffer* line1() const;
    void setLine1(CircularBuffer* buffer);

    [[nodiscard]] CircularBuffer* line2() const;
    void setLine2(CircularBuffer* buffer);

    [[nodiscard]] QColor line1Color() const;
    void setLine1Color(const QColor& color);

    [[nodiscard]] QColor line2Color() const;
    void setLine2Color(const QColor& color);

    [[nodiscard]] qreal line1FillAlpha() const;
    void setLine1FillAlpha(qreal alpha);

    [[nodiscard]] qreal line2FillAlpha() const;
    void setLine2FillAlpha(qreal alpha);

    [[nodiscard]] qreal maxValue() const;
    void setMaxValue(qreal value);

    [[nodiscard]] qreal slideProgress() const;
    void setSlideProgress(qreal progress);

    [[nodiscard]] int historyLength() const;
    void setHistoryLength(int length);

    [[nodiscard]] qreal lineWidth() const;
    void setLineWidth(qreal width);

signals:
    void line1Changed();
    void line2Changed();
    void line1ColorChanged();
    void line2ColorChanged();
    void line1FillAlphaChanged();
    void line2FillAlphaChanged();
    void maxValueChanged();
    void slideProgressChanged();
    void historyLengthChanged();
    void lineWidthChanged();

private:
    void drawLine(QPainter* painter, CircularBuffer* buffer, const QColor& color, qreal fillAlpha);
    void connectBuffer(CircularBuffer* buffer);

    CircularBuffer* m_line1 = nullptr;
    CircularBuffer* m_line2 = nullptr;
    QColor m_line1Color;
    QColor m_line2Color;
    qreal m_line1FillAlpha = 0.15;
    qreal m_line2FillAlpha = 0.2;
    qreal m_maxValue = 1024.0;
    qreal m_slideProgress = 0.0;
    int m_historyLength = 30;
    qreal m_lineWidth = 2.0;
};

} // namespace caelestia::internal
