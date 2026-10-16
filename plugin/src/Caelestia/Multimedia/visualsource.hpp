#pragma once

#include <qobject.h>

namespace caelestia::multimedia {

class VisualSource : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(VisualSource)

    Q_PROPERTY(caelestia::multimedia::VisualSource::Type type READ type NOTIFY typeChanged)
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(bool playing READ playing WRITE setPlaying NOTIFY playingChanged)
    // A QML VideoOutput element from QtMultimedia
    Q_PROPERTY(QObject* videoOutput READ videoOutput WRITE setVideoOutput NOTIFY videoOutputChanged)

public:
    enum class Type : quint8 {
        Unknown,
        Still,
        Live,
    };

    explicit VisualSource(QObject* parent = nullptr);

    [[nodiscard]] Type type() const;
    [[nodiscard]] bool ready() const;

    [[nodiscard]] QString source() const;
    void setSource(const QString& source);

    [[nodiscard]] bool playing() const;
    void setPlaying(bool playing);

    [[nodiscard]] QObject* videoOutput() const;
    void setVideoOutput(QObject* videoOutput);

signals:
    void typeChanged();
    void readyChanged();
    void sourceChanged();
    void playingChanged();
    void videoOutputChanged();

private:
    Type m_type = Type::Unknown;
    bool m_ready = false;
    QString m_source;
    bool m_playing = false;
    QObject* m_videoOutput = nullptr;
};

} // namespace caelestia::multimedia
