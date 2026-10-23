#pragma once

#include <qcolor.h>
#include <qobject.h>
#include <qqmlintegration.h>

#include <caelestia/media/analysis.hpp>

namespace caelestia::multimedia {

class VisualAnalyser : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(QColor dominantColour READ dominantColour NOTIFY dominantColourChanged)
    Q_PROPERTY(qreal luminance READ luminance NOTIFY luminanceChanged)

public:
    explicit VisualAnalyser(QObject* parent = nullptr);

    [[nodiscard]] QString source() const;
    void setSource(const QString& source);

    [[nodiscard]] QColor dominantColour() const;
    [[nodiscard]] qreal luminance() const;

signals:
    void sourceChanged();
    void dominantColourChanged();
    void luminanceChanged();

private:
    QString m_source;
    media::Analysis m_analysis;

    void analyse(const QString& path);
};

} // namespace caelestia::multimedia
