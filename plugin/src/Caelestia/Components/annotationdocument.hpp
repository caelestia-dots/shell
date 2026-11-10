#pragma once

#include <qcolor.h>
#include <qfont.h>
#include <qimage.h>
#include <qlist.h>
#include <qobject.h>
#include <qqmlintegration.h>

#include <memory>
#include <vector>

#include "annotationshape.hpp"

class QPainter;

namespace caelestia::shell::components {

class AnnotationDocument : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(AnnotationDocument)

    Q_PROPERTY(Tool tool READ tool WRITE setTool NOTIFY toolChanged FINAL)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged FINAL)
    Q_PROPERTY(qreal strokeWidth READ strokeWidth WRITE setStrokeWidth NOTIFY strokeWidthChanged FINAL)
    Q_PROPERTY(bool fill READ fill WRITE setFill NOTIFY fillChanged FINAL)
    Q_PROPERTY(bool rounded READ rounded WRITE setRounded NOTIFY roundedChanged FINAL)
    Q_PROPERTY(QFont font READ font WRITE setFont NOTIFY fontChanged FINAL)
    Q_PROPERTY(qreal fontSize READ fontSize WRITE setFontSize NOTIFY fontSizeChanged FINAL)
    Q_PROPERTY(bool textBackground READ textBackground WRITE setTextBackground NOTIFY textBackgroundChanged FINAL)
    Q_PROPERTY(qreal effectStrength READ effectStrength WRITE setEffectStrength NOTIFY effectStrengthChanged FINAL)

    Q_PROPERTY(bool canUndo READ canUndo NOTIFY changed FINAL)
    Q_PROPERTY(bool canRedo READ canRedo NOTIFY changed FINAL)
    Q_PROPERTY(bool empty READ isEmpty NOTIFY changed FINAL)
    Q_PROPERTY(int nextCounter READ nextCounter NOTIFY changed FINAL)
    Q_PROPERTY(int selected READ selected NOTIFY selectedChanged FINAL)

public:
    enum class Tool : quint8 {
        Select,
        Pencil,
        Highlighter,
        Line,
        Arrow,
        Rect,
        Ellipse,
        Text,
        Counter,
        Blur,
        Pixelate,
    };
    Q_ENUM(Tool)

    explicit AnnotationDocument(QObject* parent = nullptr);

    [[nodiscard]] Tool tool() const;
    void setTool(Tool tool);

    [[nodiscard]] QColor color() const;
    void setColor(const QColor& color);

    [[nodiscard]] qreal strokeWidth() const;
    void setStrokeWidth(qreal width);

    [[nodiscard]] bool fill() const;
    void setFill(bool fill);

    [[nodiscard]] bool rounded() const;
    void setRounded(bool rounded);

    [[nodiscard]] QFont font() const;
    void setFont(const QFont& font);

    [[nodiscard]] qreal fontSize() const;
    void setFontSize(qreal size);

    [[nodiscard]] bool textBackground() const;
    void setTextBackground(bool background);

    [[nodiscard]] qreal effectStrength() const;
    void setEffectStrength(qreal strength);

    [[nodiscard]] bool canUndo() const;
    [[nodiscard]] bool canRedo() const;
    [[nodiscard]] bool isEmpty() const;
    [[nodiscard]] int nextCounter() const;
    [[nodiscard]] int selected() const;

    Q_INVOKABLE void undo();
    Q_INVOKABLE void redo();
    Q_INVOKABLE void clear();
    Q_INVOKABLE void deselect();
    Q_INVOKABLE void deleteSelected();
    Q_INVOKABLE void copy();
    Q_INVOKABLE void paste();
    Q_INVOKABLE void setText(int index, const QString& text);
    Q_INVOKABLE [[nodiscard]] QString textAt(int index) const;

    Q_INVOKABLE void press(const QPointF& point, bool constrain);
    Q_INVOKABLE void move(const QPointF& point, bool constrain);
    Q_INVOKABLE void release();
    Q_INVOKABLE void doubleClick(const QPointF& point);

    void render(QPainter& painter) const;
    void renderPreview(QPainter& painter, const QImage& below) const;
    [[nodiscard]] QRectF selectedBounds() const;

signals:
    void toolChanged();
    void colorChanged();
    void strokeWidthChanged();
    void fillChanged();
    void roundedChanged();
    void fontChanged();
    void fontSizeChanged();
    void textBackgroundChanged();
    void effectStrengthChanged();
    void changed();
    void previewChanged();
    void selectedChanged();
    void textEditRequested(int index, QPointF pos, const QString& text);

private:
    using Shapes = QList<std::shared_ptr<annotation::Shape>>;

    [[nodiscard]] annotation::Style currentStyle() const;
    [[nodiscard]] std::shared_ptr<annotation::Shape> createShape(const QPointF& point) const;
    [[nodiscard]] int shapeAt(const QPointF& point) const;
    void pushUndo();
    void commit(Shapes shapes);
    void setSelected(int index);

    Tool m_tool = Tool::Pencil;
    QColor m_color = Qt::red;
    qreal m_strokeWidth = 4.0;
    bool m_fill = false;
    bool m_rounded = true;
    QFont m_font;
    qreal m_fontSize = 18.0;
    bool m_textBackground = true;
    qreal m_effectStrength = 0.5;

    Shapes m_shapes;
    std::vector<Shapes> m_undo;
    std::vector<Shapes> m_redo;
    std::shared_ptr<annotation::Shape> m_preview;
    std::shared_ptr<annotation::Shape> m_clipboard;
    int m_selected = -1;
    bool m_dragging = false;
    QPointF m_dragStart;
    std::shared_ptr<annotation::Shape> m_dragBase;
    QPointF m_textPos;
};

} // namespace caelestia::shell::components
