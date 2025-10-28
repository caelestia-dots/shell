#pragma once

#include <QtQuick/qquickitem.h>
#include <qfuture.h>
#include <qfuturewatcher.h>
#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia {

class ImageAnalyser : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(QQuickItem* sourceItem READ sourceItem WRITE setSourceItem NOTIFY sourceItemChanged)
    Q_PROPERTY(int rescaleSize READ rescaleSize WRITE setRescaleSize NOTIFY rescaleSizeChanged)
    Q_PROPERTY(QColor dominantColour READ dominantColour NOTIFY dominantColourChanged)
    Q_PROPERTY(qreal luminance READ luminance NOTIFY luminanceChanged)

public:
    explicit ImageAnalyser(QObject* parent = nullptr);

    [[nodiscard]] QString source() const;
    void setSource(const QString& source);

    [[nodiscard]] QQuickItem* sourceItem() const;
    void setSourceItem(QQuickItem* sourceItem);

    [[nodiscard]] int rescaleSize() const;
    void setRescaleSize(int rescaleSize);

    [[nodiscard]] QColor dominantColour() const;
    [[nodiscard]] qreal luminance() const;

    Q_INVOKABLE void requestUpdate();

signals:
    void sourceChanged();
    void sourceItemChanged();
    void rescaleSizeChanged();
    void dominantColourChanged();
    void luminanceChanged();

private:
    using AnalyseResult = QPair<QColor, qreal>;

    QFutureWatcher<AnalyseResult>* const m_futureWatcher;

    QString m_source;
    QQuickItem* m_sourceItem;
    int m_rescaleSize;

    QColor m_dominantColour;
    qreal m_luminance;

    void update();
    static void analyse(QPromise<AnalyseResult>& promise, const QImage& image, int rescaleSize);
};

} // namespace caelestia
