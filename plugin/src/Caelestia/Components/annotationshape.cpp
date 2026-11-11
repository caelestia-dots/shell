#include "annotationshape.hpp"

#include <qfontmetrics.h>
#include <qmath.h>
#include <qpainter.h>
#include <qpen.h>

#include <algorithm>

namespace caelestia::shell::components::annotation {

namespace {

constexpr qreal k_hitSlop = 8.0;

QPointF constrainTo45(const QPointF& start, const QPointF& point) {
    const auto d = point - start;
    const auto angle = qRound(qAtan2(d.y(), d.x()) / (M_PI / 4)) * (M_PI / 4);
    const auto len = std::hypot(d.x(), d.y());
    return start + QPointF(qCos(angle) * len, qSin(angle) * len);
}

QPointF constrainSquare(const QPointF& start, const QPointF& point) {
    const auto d = point - start;
    const auto side = std::max(qAbs(d.x()), qAbs(d.y()));
    return start + QPointF(std::copysign(side, d.x()), std::copysign(side, d.y()));
}

QRectF normalised(const QPointF& a, const QPointF& b) {
    return QRectF(a, b).normalized();
}

void boxBlur(QImage& image, int radius) {
    if (radius < 1 || image.isNull())
        return;

    const auto w = image.width();
    const auto h = image.height();
    const auto window = radius * 2 + 1;
    QImage tmp(image.size(), image.format());

    const auto pass = [&](const QImage& src, QImage& dst, bool horizontal) {
        const auto outer = horizontal ? h : w;
        const auto inner = horizontal ? w : h;
        for (int o = 0; o < outer; ++o) {
            struct {
                int alpha = 0;
                int red = 0;
                int green = 0;
                int blue = 0;
            } sum;

            const auto px = [&](int i) -> QRgb {
                i = std::clamp(i, 0, inner - 1);
                return horizontal ? reinterpret_cast<const QRgb*>(src.constScanLine(o))[i]
                                  : reinterpret_cast<const QRgb*>(src.constScanLine(i))[o];
            };
            const auto add = [&](QRgb c, int sign) {
                sum.alpha += sign * qAlpha(c);
                sum.red += sign * qRed(c);
                sum.green += sign * qGreen(c);
                sum.blue += sign * qBlue(c);
            };

            for (int i = -radius; i <= radius; ++i)
                add(px(i), 1);

            for (int i = 0; i < inner; ++i) {
                const auto out = qRgba(sum.red / window, sum.green / window, sum.blue / window, sum.alpha / window);
                if (horizontal)
                    reinterpret_cast<QRgb*>(dst.scanLine(o))[i] = out;
                else
                    reinterpret_cast<QRgb*>(dst.scanLine(i))[o] = out;

                add(px(i - radius), -1);
                add(px(i + radius + 1), 1);
            }
        }
    };

    for (int i = 0; i < 3; ++i) {
        pass(image, tmp, true);
        pass(tmp, image, false);
    }
}

} // namespace

Shape::Shape(Style style)
    : m_style(std::move(style)) {}

bool Shape::hitTest(const QPointF& point) const {
    QPainterPathStroker stroker;
    stroker.setWidth(std::max(m_style.width, k_hitSlop) + k_hitSlop);
    return stroker.createStroke(outline()).contains(point);
}

bool Shape::isEmpty() const {
    return false;
}

const Style& Shape::style() const {
    return m_style;
}

QPainterPath Shape::outline() const {
    QPainterPath path;
    path.addRect(bounds());
    return path;
}

QPen Shape::pen() const {
    QPen pen(m_style.color, m_style.width);
    pen.setCapStyle(Qt::RoundCap);
    pen.setJoinStyle(Qt::RoundJoin);
    return pen;
}

Stroke::Stroke(Style style, const QPointF& start, bool highlighter)
    : Shape(std::move(style))
    , m_points({ start })
    , m_path(start)
    , m_bounds(start, start)
    , m_highlighter(highlighter) {}

void Stroke::render(QPainter& painter) const {
    painter.save();
    painter.setOpacity(painter.opacity() * opacity());
    renderOpaque(painter);
    painter.restore();
}

void Stroke::renderOpaque(QPainter& painter) const {
    painter.save();
    const auto p = strokePen();

    if (m_points.size() == 1) {
        painter.setPen(Qt::NoPen);
        painter.setBrush(p.color());
        painter.drawPath(dot());
    } else {
        painter.setPen(p);
        painter.setBrush(Qt::NoBrush);
        painter.drawPath(path());
    }
    painter.restore();
}

QRectF Stroke::bounds() const {
    const auto m = width() / 2;
    return m_bounds.adjusted(-m, -m, m, m);
}

void Stroke::translate(const QPointF& delta) {
    for (auto& p : m_points)
        p += delta;
    m_path.translate(delta);
    m_segment.translate(delta);
    m_bounds.translate(delta);
}

void Stroke::update(const QPointF& point, bool constrain) {
    Q_UNUSED(constrain)
    m_segment = QPainterPath();
    if (QLineF(m_points.last(), point).length() <= 1.0)
        return;

    const auto count = m_points.size();
    m_points.append(point);
    extendBounds(point);
    if (count < 2)
        return;

    const auto& control = m_points[count - 1];
    const auto mid = (control + point) / 2;
    m_path.quadTo(control, mid);

    // Includes the previous segment so its flat end cap gets painted over
    const auto first = std::max<qsizetype>(count - 2, 1);
    m_segment = QPainterPath(first == 1 ? m_points.first() : (m_points[first - 1] + m_points[first]) / 2);
    for (auto i = first; i < count; ++i)
        m_segment.quadTo(m_points[i], (m_points[i] + m_points[i + 1]) / 2);
}

std::shared_ptr<Shape> Stroke::clone() const {
    return std::make_shared<Stroke>(*this);
}

QRectF Stroke::renderSegment(QPainter& painter) const {
    if (m_segment.isEmpty())
        return {};

    painter.save();
    painter.setPen(strokePen());
    painter.setBrush(Qt::NoBrush);
    painter.drawPath(m_segment);
    painter.restore();

    const auto m = width() / 2;
    return m_segment.controlPointRect().adjusted(-m, -m, m, m);
}

QPainterPath Stroke::outline() const {
    return m_points.size() == 1 ? dot() : path();
}

qreal Stroke::opacity() const {
    return m_highlighter ? 0.4 : 1.0;
}

bool Stroke::isFirstSegment() const {
    return !m_segment.isEmpty() && m_points.size() == 3;
}

QPen Stroke::strokePen() const {
    auto p = pen();
    p.setWidthF(width());
    if (m_highlighter)
        p.setCapStyle(Qt::FlatCap);
    return p;
}

QPainterPath Stroke::dot() const {
    const auto r = width() / 2;
    QPainterPath path;
    if (m_highlighter)
        path.addRect(QRectF(m_points.first() - QPointF(r / 2, r), QSizeF(r, width())));
    else
        path.addEllipse(m_points.first(), r, r);
    return path;
}

QPainterPath Stroke::path() const {
    auto path = m_path;
    if (m_points.size() > 1)
        path.lineTo(m_points.last());
    return path;
}

qreal Stroke::width() const {
    return m_highlighter ? m_style.width * 3 : m_style.width;
}

void Stroke::extendBounds(const QPointF& point) {
    m_bounds.setLeft(std::min(m_bounds.left(), point.x()));
    m_bounds.setTop(std::min(m_bounds.top(), point.y()));
    m_bounds.setRight(std::max(m_bounds.right(), point.x()));
    m_bounds.setBottom(std::max(m_bounds.bottom(), point.y()));
}

Line::Line(Style style, const QPointF& start, bool arrow)
    : Shape(std::move(style))
    , m_start(start)
    , m_end(start)
    , m_arrow(arrow) {}

void Line::render(QPainter& painter) const {
    if (isEmpty())
        return;

    painter.save();
    painter.setPen(pen());
    painter.setBrush(Qt::NoBrush);
    painter.drawLine(m_start, shaftEnd());

    if (m_arrow) {
        painter.setPen(Qt::NoPen);
        painter.setBrush(m_style.color);
        painter.drawPath(head());
    }

    painter.restore();
}

QRectF Line::bounds() const {
    const auto m = m_style.width * 2;
    return normalised(m_start, m_end).united(head().boundingRect()).adjusted(-m, -m, m, m);
}

void Line::translate(const QPointF& delta) {
    m_start += delta;
    m_end += delta;
}

void Line::update(const QPointF& point, bool constrain) {
    m_end = constrain ? constrainTo45(m_start, point) : point;
}

std::shared_ptr<Shape> Line::clone() const {
    return std::make_shared<Line>(*this);
}

bool Line::isEmpty() const {
    return QLineF(m_start, m_end).length() < 2.0;
}

QPainterPath Line::outline() const {
    QPainterPath path(m_start);
    path.lineTo(m_end);
    return path;
}

QPainterPath Line::head() const {
    QPainterPath path;
    if (!m_arrow || isEmpty())
        return path;

    const auto size = headSize();
    const auto dir = direction();
    const QPointF normal(-dir.y(), dir.x());
    const auto base = shaftEnd();

    path.moveTo(m_end);
    path.lineTo(base + normal * size / 2);
    path.lineTo(base - normal * size / 2);
    path.closeSubpath();

    return path;
}

QPointF Line::shaftEnd() const {
    return m_arrow ? m_end + direction() * headSize() : m_end;
}

QPointF Line::direction() const {
    const auto line = QLineF(m_end, m_start).unitVector();
    return { line.dx(), line.dy() };
}

qreal Line::headSize() const {
    return std::max(12.0, m_style.width * 4);
}

RectShape::RectShape(Style style, const QPointF& start, Kind kind)
    : Shape(std::move(style))
    , m_start(start)
    , m_end(start)
    , m_kind(kind) {}

void RectShape::render(QPainter& painter) const {
    const auto r = rect();
    if (isEffect()) {
        if (const auto* image = dynamic_cast<const QImage*>(painter.device()))
            renderEffect(painter, *image, QImage(), QPoint());
        else
            painter.fillRect(r, QColor(0, 0, 0, 60));
        return;
    }

    painter.save();
    painter.setPen(pen());
    painter.setBrush(m_style.fill ? QBrush(QColor(m_style.color.red(), m_style.color.green(), m_style.color.blue(), 60))
                                  : QBrush(Qt::NoBrush));
    if (m_kind == Kind::Ellipse)
        painter.drawEllipse(r);
    else if (m_style.rounded)
        painter.drawRoundedRect(r, 8, 8);
    else
        painter.drawRect(r);
    painter.restore();
}

QRectF RectShape::bounds() const {
    const auto m = isEffect() ? 0.0 : m_style.width / 2;
    return rect().adjusted(-m, -m, m, m);
}

bool RectShape::hitTest(const QPointF& point) const {
    if (isEffect() || m_style.fill)
        return outline().contains(point);
    return Shape::hitTest(point);
}

void RectShape::translate(const QPointF& delta) {
    m_start += delta;
    m_end += delta;
}

void RectShape::update(const QPointF& point, bool constrain) {
    m_end = constrain ? constrainSquare(m_start, point) : point;
}

std::shared_ptr<Shape> RectShape::clone() const {
    return std::make_shared<RectShape>(*this);
}

bool RectShape::isEmpty() const {
    const auto r = rect();
    return r.width() < 2.0 || r.height() < 2.0;
}

bool RectShape::isEffect() const {
    return m_kind == Kind::Blur || m_kind == Kind::Pixelate;
}

void RectShape::renderEffect(
    QPainter& painter, const QImage& base, const QImage& above, const QPoint& deviceOffset) const {
    if (isEmpty())
        return;

    const auto dpr = base.devicePixelRatio();
    const auto local = painter.worldTransform().mapRect(rect());
    const auto target = QRectF(local.topLeft() * dpr, local.size() * dpr).toAlignedRect();
    const auto dev = target.translated(deviceOffset).intersected(base.rect());
    if (dev.isEmpty())
        return;

    const auto scale = target.width() / rect().width();
    auto region = base.copy(dev).convertToFormat(QImage::Format_ARGB32_Premultiplied);
    region.setDevicePixelRatio(1);
    if (!above.isNull()) {
        auto layer = above.copy(dev);
        layer.setDevicePixelRatio(1);
        QPainter p(&region);
        p.drawImage(QPoint(), layer);
    }

    if (m_kind == Kind::Pixelate) {
        const auto block = std::max(1.0, (4 + m_style.effectStrength * 28) * scale);
        const auto small = region.scaled(std::max(1, qRound(region.width() / block)),
            std::max(1, qRound(region.height() / block)), Qt::IgnoreAspectRatio, Qt::FastTransformation);
        region = small.scaled(region.size(), Qt::IgnoreAspectRatio, Qt::FastTransformation);
    } else {
        const auto radius = qRound((2 + m_style.effectStrength * 14) * scale);
        const auto factor = std::max(1, radius / 2);
        const auto size = region.size();
        auto small = region.scaled(std::max(1, size.width() / factor), std::max(1, size.height() / factor),
            Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
        boxBlur(small, std::max(1, radius / factor));
        region = small.scaled(size, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    }

    region.setDevicePixelRatio(dpr);
    painter.save();
    painter.resetTransform();
    painter.drawImage(QPointF(dev.topLeft() - deviceOffset) / dpr, region);
    painter.restore();
}

QPainterPath RectShape::outline() const {
    QPainterPath path;
    if (m_kind == Kind::Ellipse)
        path.addEllipse(rect());
    else
        path.addRect(rect());
    return path;
}

QRectF RectShape::rect() const {
    return normalised(m_start, m_end);
}

Text::Text(Style style, const QPointF& pos)
    : Shape(std::move(style))
    , m_pos(pos) {}

void Text::render(QPainter& painter) const {
    if (m_text.isEmpty())
        return;

    painter.save();
    painter.setFont(m_style.font);

    if (m_style.textBackground) {
        painter.setPen(Qt::NoPen);
        painter.setBrush(m_style.textBackgroundColor);
        painter.drawRoundedRect(bounds(), m_style.textRadius, m_style.textRadius);
    }

    painter.setPen(m_style.color);
    painter.drawText(textRect(), Qt::AlignLeft | Qt::AlignTop, m_text);
    painter.restore();
}

QRectF Text::bounds() const {
    const auto pad = m_style.textPadding;
    return textRect().adjusted(-pad, -pad, pad, pad);
}

bool Text::hitTest(const QPointF& point) const {
    return bounds().contains(point);
}

void Text::translate(const QPointF& delta) {
    m_pos += delta;
}

void Text::update(const QPointF& point, bool constrain) {
    Q_UNUSED(point)
    Q_UNUSED(constrain)
}

std::shared_ptr<Shape> Text::clone() const {
    return std::make_shared<Text>(*this);
}

bool Text::isEmpty() const {
    return m_text.trimmed().isEmpty();
}

QPointF Text::pos() const {
    return m_pos;
}

QString Text::text() const {
    return m_text;
}

void Text::setText(const QString& text) {
    m_text = text;
}

QRectF Text::textRect() const {
    const QFontMetricsF metrics(m_style.font);
    const auto size = metrics.boundingRect(QRectF(0, 0, 10000, 10000), Qt::AlignLeft | Qt::AlignTop, m_text).size();
    return { m_pos, size };
}

Counter::Counter(Style style, const QPointF& pos, int number)
    : Shape(std::move(style))
    , m_pos(pos)
    , m_number(number) {}

void Counter::render(QPainter& painter) const {
    painter.save();
    painter.setPen(Qt::NoPen);
    painter.setBrush(m_style.color);
    painter.drawEllipse(m_pos, radius(), radius());
    auto font = m_style.font;
    font.setBold(true);
    painter.setFont(font);
    painter.setPen(m_style.color.lightness() > 140 ? Qt::black : Qt::white);
    painter.drawText(bounds(), Qt::AlignCenter, QString::number(m_number));
    painter.restore();
}

QRectF Counter::bounds() const {
    return { m_pos.x() - radius(), m_pos.y() - radius(), radius() * 2, radius() * 2 };
}

bool Counter::hitTest(const QPointF& point) const {
    return QLineF(m_pos, point).length() <= radius();
}

void Counter::translate(const QPointF& delta) {
    m_pos += delta;
}

void Counter::update(const QPointF& point, bool constrain) {
    Q_UNUSED(constrain)
    m_pos = point;
}

std::shared_ptr<Shape> Counter::clone() const {
    return std::make_shared<Counter>(*this);
}

int Counter::number() const {
    return m_number;
}

qreal Counter::radius() const {
    return std::max(14.0, m_style.font.pixelSize() * 0.9);
}

} // namespace caelestia::shell::components::annotation
