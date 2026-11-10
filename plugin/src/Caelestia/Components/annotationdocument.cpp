#include "annotationdocument.hpp"

#include <qpainter.h>

#include <algorithm>
#include <cmath>

namespace caelestia::shell::components {

using namespace annotation;

AnnotationDocument::AnnotationDocument(QObject* parent)
    : QObject(parent) {
    connect(this, &AnnotationDocument::selectedChanged, this, &AnnotationDocument::selectedBoundsChanged);
    connect(this, &AnnotationDocument::changed, this, &AnnotationDocument::selectedBoundsChanged);
    connect(this, &AnnotationDocument::previewChanged, this, &AnnotationDocument::selectedBoundsChanged);
}

AnnotationDocument::Tool AnnotationDocument::tool() const {
    return m_tool;
}

void AnnotationDocument::setTool(Tool tool) {
    if (m_tool == tool)
        return;

    m_tool = tool;
    if (tool != Tool::Select)
        deselect();
    emit toolChanged();
}

QColor AnnotationDocument::color() const {
    return m_color;
}

void AnnotationDocument::setColor(const QColor& color) {
    if (m_color == color)
        return;

    m_color = color;
    emit colorChanged();
}

qreal AnnotationDocument::strokeWidth() const {
    return m_strokeWidth;
}

void AnnotationDocument::setStrokeWidth(qreal width) {
    if (qFuzzyCompare(m_strokeWidth, width))
        return;

    m_strokeWidth = width;
    emit strokeWidthChanged();
}

bool AnnotationDocument::fill() const {
    return m_fill;
}

void AnnotationDocument::setFill(bool fill) {
    if (m_fill == fill)
        return;

    m_fill = fill;
    emit fillChanged();
}

bool AnnotationDocument::rounded() const {
    return m_rounded;
}

void AnnotationDocument::setRounded(bool rounded) {
    if (m_rounded == rounded)
        return;

    m_rounded = rounded;
    emit roundedChanged();
}

QFont AnnotationDocument::font() const {
    return m_font;
}

void AnnotationDocument::setFont(const QFont& font) {
    if (m_font == font)
        return;

    m_font = font;
    emit fontChanged();
}

bool AnnotationDocument::textBackground() const {
    return m_textBackground;
}

void AnnotationDocument::setTextBackground(bool background) {
    if (m_textBackground == background)
        return;

    m_textBackground = background;
    emit textBackgroundChanged();
}

QColor AnnotationDocument::textBackgroundColor() const {
    return m_textBackgroundColor;
}

void AnnotationDocument::setTextBackgroundColor(const QColor& color) {
    if (m_textBackgroundColor == color)
        return;

    m_textBackgroundColor = color;
    emit textBackgroundColorChanged();
}

qreal AnnotationDocument::textPadding() const {
    return m_textPadding;
}

void AnnotationDocument::setTextPadding(qreal padding) {
    if (qFuzzyCompare(m_textPadding, padding))
        return;

    m_textPadding = padding;
    emit textPaddingChanged();
}

qreal AnnotationDocument::textRadius() const {
    return m_textRadius;
}

void AnnotationDocument::setTextRadius(qreal radius) {
    if (qFuzzyCompare(m_textRadius, radius))
        return;

    m_textRadius = radius;
    emit textRadiusChanged();
}

qreal AnnotationDocument::effectStrength() const {
    return m_effectStrength;
}

void AnnotationDocument::setEffectStrength(qreal strength) {
    if (qFuzzyCompare(m_effectStrength, strength))
        return;

    m_effectStrength = strength;
    emit effectStrengthChanged();
}

bool AnnotationDocument::canUndo() const {
    return !m_undo.empty();
}

bool AnnotationDocument::canRedo() const {
    return !m_redo.empty();
}

bool AnnotationDocument::isEmpty() const {
    return m_shapes.empty();
}

int AnnotationDocument::nextCounter() const {
    int next = 1;
    for (const auto& shape : m_shapes)
        if (const auto* counter = dynamic_cast<const Counter*>(shape.get()))
            next = std::max(next, counter->number() + 1);
    return next;
}

int AnnotationDocument::selected() const {
    return m_selected;
}

void AnnotationDocument::undo() {
    if (m_undo.empty())
        return;

    m_redo.push_back(m_shapes);
    m_shapes = std::move(m_undo.back());
    m_undo.pop_back();
    setSelected(-1);
    emit changed();
}

void AnnotationDocument::redo() {
    if (m_redo.empty())
        return;

    m_undo.push_back(m_shapes);
    m_shapes = std::move(m_redo.back());
    m_redo.pop_back();
    setSelected(-1);
    emit changed();
}

void AnnotationDocument::clear() {
    if (m_shapes.empty())
        return;

    commit({});
}

void AnnotationDocument::deselect() {
    setSelected(-1);
}

void AnnotationDocument::deleteSelected() {
    if (m_selected < 0)
        return;

    auto shapes = m_shapes;
    shapes.erase(shapes.begin() + m_selected);
    setSelected(-1);
    commit(std::move(shapes));
}

void AnnotationDocument::copy() {
    if (m_selected >= 0)
        m_clipboard = m_shapes[m_selected]->clone();
}

void AnnotationDocument::paste() {
    if (!m_clipboard)
        return;

    auto shape = m_clipboard->clone();
    shape->translate(QPointF(16, 16));
    auto shapes = m_shapes;
    shapes.push_back(std::move(shape));
    commit(std::move(shapes));
    setSelected(static_cast<int>(m_shapes.size()) - 1);
}

void AnnotationDocument::setText(int index, const QString& text) {
    const bool empty = text.trimmed().isEmpty();
    auto shapes = m_shapes;

    if (index < 0) {
        if (empty)
            return;
        auto shape = std::make_shared<Text>(currentStyle(), m_textPos);
        shape->setText(text);
        shapes.push_back(std::move(shape));
        commit(std::move(shapes));
        return;
    }

    if (index >= static_cast<int>(shapes.size()))
        return;

    const auto copy = std::dynamic_pointer_cast<Text>(shapes[index]->clone());
    if (!copy)
        return;

    if (empty) {
        shapes.erase(shapes.begin() + index);
        setSelected(-1);
    } else {
        copy->setText(text);
        shapes[index] = copy;
    }
    commit(std::move(shapes));
}

QString AnnotationDocument::textAt(int index) const {
    if (index < 0 || index >= static_cast<int>(m_shapes.size()))
        return {};

    const auto* text = dynamic_cast<const Text*>(m_shapes[index].get());
    return text ? text->text() : QString();
}

void AnnotationDocument::press(const QPointF& point, bool constrain) {
    Q_UNUSED(constrain)

    if (m_tool == Tool::Select) {
        auto index = m_selected;
        if (index < 0 || !selectedBounds().contains(point))
            index = shapeAt(point);

        setSelected(index);
        if (index >= 0) {
            m_dragging = true;
            m_dragStart = point;
        }
        return;
    }

    if (m_tool == Tool::Text) {
        m_textPos = point;
        emit textEditRequested(-1, point, QString());
        return;
    }

    m_preview = createShape(point);
    emit previewChanged();
}

void AnnotationDocument::move(const QPointF& point, bool constrain) {
    if (m_dragging && m_selected >= 0) {
        if (!m_dragBase) {
            pushUndo();
            m_dragBase = m_shapes[m_selected]->clone();
            emit changed();
        }

        auto delta = point - m_dragStart;
        if (constrain) {
            if (std::abs(delta.x()) >= std::abs(delta.y()))
                delta.setY(0);
            else
                delta.setX(0);
        }

        m_preview = m_dragBase->clone();
        m_preview->translate(delta);
        emit previewChanged();
        return;
    }

    if (!m_preview)
        return;

    m_preview->update(point, constrain);
    emit previewChanged();
}

void AnnotationDocument::release() {
    if (m_dragging) {
        m_dragging = false;
        m_dragBase = nullptr;
        if (!m_preview)
            return;

        if (m_selected >= 0)
            m_shapes[m_selected] = std::move(m_preview);
        m_preview = nullptr;
        emit previewChanged();
        emit changed();
        return;
    }

    if (!m_preview)
        return;

    auto shape = std::move(m_preview);
    m_preview = nullptr;
    emit previewChanged();
    if (shape->isEmpty())
        return;

    auto shapes = m_shapes;
    shapes.push_back(std::move(shape));
    commit(std::move(shapes));
}

void AnnotationDocument::doubleClick(const QPointF& point) {
    if (m_tool != Tool::Select)
        return;

    const auto index = shapeAt(point);
    if (index < 0)
        return;

    if (const auto* text = dynamic_cast<const Text*>(m_shapes[index].get())) {
        setSelected(index);
        emit textEditRequested(index, text->pos(), text->text());
    }
}

void AnnotationDocument::render(QPainter& painter, const QImage& base) const {
    painter.setRenderHint(QPainter::Antialiasing);
    painter.setRenderHint(QPainter::TextAntialiasing);
    const auto* above = base.isNull() ? nullptr : dynamic_cast<const QImage*>(painter.device());
    const auto dragged = m_dragging && m_preview ? m_selected : -1;
    for (qsizetype i = 0; i < m_shapes.size(); ++i) {
        if (i == dragged)
            continue;
        if (const auto* effect = dynamic_cast<const RectShape*>(m_shapes[i].get());
            effect && effect->isEffect() && above)
            effect->renderEffect(painter, base, *above, QPoint());
        else
            m_shapes[i]->render(painter);
    }
}

void AnnotationDocument::renderPreview(
    QPainter& painter, const QImage& base, const QImage& above, const QPoint& deviceOffset) const {
    if (!m_preview)
        return;

    painter.setRenderHint(QPainter::Antialiasing);
    if (const auto* effect = dynamic_cast<const RectShape*>(m_preview.get()); effect && effect->isEffect())
        effect->renderEffect(painter, base, above, deviceOffset);
    else
        m_preview->render(painter);
}

std::optional<QRectF> AnnotationDocument::previewBounds() const {
    if (!m_preview)
        return std::nullopt;
    return m_preview->bounds();
}

QRectF AnnotationDocument::selectedBounds() const {
    if (m_selected < 0 || m_selected >= static_cast<int>(m_shapes.size()))
        return {};
    return (m_dragging && m_preview ? m_preview : m_shapes[m_selected])->bounds();
}

Style AnnotationDocument::currentStyle() const {
    return {
        .color = m_color,
        .width = m_strokeWidth,
        .fill = m_fill,
        .rounded = m_rounded,
        .font = m_font,
        .textBackground = m_textBackground,
        .textBackgroundColor = m_textBackgroundColor,
        .textPadding = m_textPadding,
        .textRadius = m_textRadius,
        .effectStrength = m_effectStrength,
    };
}

std::shared_ptr<Shape> AnnotationDocument::createShape(const QPointF& point) const {
    const auto style = currentStyle();
    switch (m_tool) {
    case Tool::Pencil:
        return std::make_shared<Stroke>(style, point, false);
    case Tool::Highlighter:
        return std::make_shared<Stroke>(style, point, true);
    case Tool::Line:
        return std::make_shared<Line>(style, point, false);
    case Tool::Arrow:
        return std::make_shared<Line>(style, point, true);
    case Tool::Rect:
        return std::make_shared<RectShape>(style, point, RectShape::Kind::Rect);
    case Tool::Ellipse:
        return std::make_shared<RectShape>(style, point, RectShape::Kind::Ellipse);
    case Tool::Blur:
        return std::make_shared<RectShape>(style, point, RectShape::Kind::Blur);
    case Tool::Pixelate:
        return std::make_shared<RectShape>(style, point, RectShape::Kind::Pixelate);
    case Tool::Counter:
        return std::make_shared<Counter>(style, point, nextCounter());
    default:
        return nullptr;
    }
}

int AnnotationDocument::shapeAt(const QPointF& point) const {
    for (int i = static_cast<int>(m_shapes.size()) - 1; i >= 0; --i)
        if (m_shapes[i]->hitTest(point))
            return i;
    return -1;
}

void AnnotationDocument::pushUndo() {
    m_undo.push_back(m_shapes);
    m_redo.clear();
}

void AnnotationDocument::commit(Shapes shapes) {
    pushUndo();
    m_shapes = std::move(shapes);
    if (m_selected >= static_cast<int>(m_shapes.size()))
        setSelected(-1);
    emit changed();
}

void AnnotationDocument::setSelected(int index) {
    if (m_selected == index)
        return;

    m_selected = index;
    emit selectedChanged();
}

} // namespace caelestia::shell::components
