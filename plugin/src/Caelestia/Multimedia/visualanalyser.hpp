#pragma once

#include <qcolor.h>
#include <qfuture.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qqmlparserstatus.h>
#include <qurl.h>

#include <caelestia/media/analysis.hpp>

namespace caelestia::multimedia {

class VisualAnalyser : public QObject, public QQmlParserStatus {
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
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

    void classBegin() override;
    void componentComplete() override;

signals:
    void sourceChanged();
    void dominantColourChanged();
    void luminanceChanged();

private:
    QString m_source;
    media::Analysis m_analysis;
    bool m_complete = false;

    void resolve();
    void analyse(const QString& path);
    void analyseProvider(const QUrl& url);
    void apply(QFuture<media::Analysis> future);
};

} // namespace caelestia::multimedia
