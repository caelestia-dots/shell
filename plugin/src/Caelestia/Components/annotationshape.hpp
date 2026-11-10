#pragma once

#include <qcolor.h>
#include <qfont.h>
#include <qimage.h>
#include <qpainterpath.h>
#include <qpen.h>
#include <qpoint.h>
#include <qrect.h>
#include <qstring.h>

#include <memory>

class QPainter;

namespace caelestia::shell::components::annotation {

struct Style {
    QColor color;
    qreal width = 4.0;
    bool fill = false;
    bool rounded = true;
    QFont font;
    bool textBackground = true;
    QColor textBackgroundColor = QColor(0, 0, 0, 170);
    qreal textPadding = 6.0;
    qreal textRadius = 8.0;
    qreal effectStrength = 0.5;
};

class Shape {
public:
    explicit Shape(Style style);
    virtual ~Shape() = default;

    virtual void render(QPainter& painter) const = 0;
    [[nodiscard]] virtual QRectF bounds() const = 0;
    [[nodiscard]] virtual bool hitTest(const QPointF& point) const;
    virtual void translate(const QPointF& delta) = 0;
    virtual void update(const QPointF& point, bool constrain) = 0;
    [[nodiscard]] virtual std::shared_ptr<Shape> clone() const = 0;
    [[nodiscard]] virtual bool isEmpty() const;

    [[nodiscard]] const Style& style() const;

protected:
    [[nodiscard]] virtual QPainterPath outline() const;
    [[nodiscard]] QPen pen() const;

    Style m_style;
};

class Stroke : public Shape {
public:
    Stroke(Style style, const QPointF& start, bool highlighter);

    void render(QPainter& painter) const override;
    [[nodiscard]] QRectF bounds() const override;
    void translate(const QPointF& delta) override;
    void update(const QPointF& point, bool constrain) override;
    [[nodiscard]] std::shared_ptr<Shape> clone() const override;

protected:
    [[nodiscard]] QPainterPath outline() const override;

private:
    [[nodiscard]] QPainterPath dot() const;
    [[nodiscard]] QPainterPath path() const;
    [[nodiscard]] qreal width() const;

    QList<QPointF> m_points;
    bool m_highlighter;
};

class Line : public Shape {
public:
    Line(Style style, const QPointF& start, bool arrow);

    void render(QPainter& painter) const override;
    [[nodiscard]] QRectF bounds() const override;
    void translate(const QPointF& delta) override;
    void update(const QPointF& point, bool constrain) override;
    [[nodiscard]] std::shared_ptr<Shape> clone() const override;
    [[nodiscard]] bool isEmpty() const override;

protected:
    [[nodiscard]] QPainterPath outline() const override;

private:
    [[nodiscard]] QPainterPath head() const;

    QPointF m_start;
    QPointF m_end;
    bool m_arrow;
};

class RectShape : public Shape {
public:
    enum class Kind : quint8 {
        Rect,
        Ellipse,
        Blur,
        Pixelate,
    };

    RectShape(Style style, const QPointF& start, Kind kind);

    void render(QPainter& painter) const override;
    [[nodiscard]] QRectF bounds() const override;
    [[nodiscard]] bool hitTest(const QPointF& point) const override;
    void translate(const QPointF& delta) override;
    void update(const QPointF& point, bool constrain) override;
    [[nodiscard]] std::shared_ptr<Shape> clone() const override;
    [[nodiscard]] bool isEmpty() const override;

    [[nodiscard]] bool isEffect() const;
    void renderEffect(QPainter& painter, const QImage& base, const QImage& above, const QPoint& deviceOffset) const;

protected:
    [[nodiscard]] QPainterPath outline() const override;

private:
    [[nodiscard]] QRectF rect() const;

    QPointF m_start;
    QPointF m_end;
    Kind m_kind;
};

class Text : public Shape {
public:
    Text(Style style, const QPointF& pos);

    void render(QPainter& painter) const override;
    [[nodiscard]] QRectF bounds() const override;
    [[nodiscard]] bool hitTest(const QPointF& point) const override;
    void translate(const QPointF& delta) override;
    void update(const QPointF& point, bool constrain) override;
    [[nodiscard]] std::shared_ptr<Shape> clone() const override;
    [[nodiscard]] bool isEmpty() const override;

    [[nodiscard]] QPointF pos() const;
    [[nodiscard]] QString text() const;
    void setText(const QString& text);

private:
    [[nodiscard]] QRectF textRect() const;

    QPointF m_pos;
    QString m_text;
};

class Counter : public Shape {
public:
    Counter(Style style, const QPointF& pos, int number);

    void render(QPainter& painter) const override;
    [[nodiscard]] QRectF bounds() const override;
    [[nodiscard]] bool hitTest(const QPointF& point) const override;
    void translate(const QPointF& delta) override;
    void update(const QPointF& point, bool constrain) override;
    [[nodiscard]] std::shared_ptr<Shape> clone() const override;

    [[nodiscard]] int number() const;

private:
    [[nodiscard]] qreal radius() const;

    QPointF m_pos;
    int m_number;
};

} // namespace caelestia::shell::components::annotation
