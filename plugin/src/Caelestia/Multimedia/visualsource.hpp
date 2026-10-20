#pragma once

#include <qmediaplayer.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qsize.h>
#include <qurl.h>
#include <qvideoframe.h>

#include <atomic>

namespace caelestia::multimedia {

class VisualSource : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(VisualSource)

    Q_PROPERTY(caelestia::multimedia::VisualSource::Type type READ type NOTIFY typeChanged)
    Q_PROPERTY(bool videoReady READ videoReady NOTIFY videoReadyChanged)
    // The path to the image (source or a cached file when type is Still), or preview if type is Live.
    // The preview is cleared when the video is ready.
    Q_PROPERTY(QUrl imagePath READ imagePath NOTIFY imagePathChanged)
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(bool playing READ playing WRITE setPlaying NOTIFY playingChanged)
    Q_PROPERTY(
        caelestia::multimedia::VisualSource::FillMode fillMode READ fillMode WRITE setFillMode NOTIFY fillModeChanged)
    // A QML VideoOutput element from QtMultimedia
    Q_PROPERTY(QObject* videoOutput READ videoOutput WRITE setVideoOutput NOTIFY videoOutputChanged)
    // A QML item to use for the size of the loaded media
    Q_PROPERTY(QQuickItem* sizeSource READ sizeSource WRITE setSizeSource NOTIFY sizeSourceChanged)

public:
    enum class Type : quint8 {
        Unknown,
        Still,
        Live,
    };
    Q_ENUM(Type)

    enum class FillMode : quint8 {
        Stretch = 0,
        PreserveAspectFit,
        PreserveAspectCrop,
    };
    Q_ENUM(FillMode)

    explicit VisualSource(QObject* parent = nullptr);

    [[nodiscard]] Type type() const;
    [[nodiscard]] bool videoReady() const;
    [[nodiscard]] QUrl imagePath() const;

    [[nodiscard]] QString source() const;
    void setSource(const QString& source);

    [[nodiscard]] bool playing() const;
    void setPlaying(bool playing);

    [[nodiscard]] FillMode fillMode() const;
    void setFillMode(FillMode fillMode);

    [[nodiscard]] QObject* videoOutput() const;
    void setVideoOutput(QObject* videoOutput);

    [[nodiscard]] QQuickItem* sizeSource() const;
    void setSizeSource(QQuickItem* sizeSource);

signals:
    void typeChanged();
    void videoReadyChanged();
    void imagePathChanged();
    void sourceChanged();
    void playingChanged();
    void fillModeChanged();
    void videoOutputChanged();
    void sizeSourceChanged();

private:
    void setType(Type type);
    void setVideoReady(bool videoReady);
    void setImagePath(const QUrl& imagePath);
    void refresh();
    void watchWindow(QQuickWindow* window);
    void onVideoFrame(const QVideoFrame& frame);
    void syncPlayer();
    [[nodiscard]] QString localPath() const;
    [[nodiscard]] Qt::AspectRatioMode aspectMode() const;

    Type m_type = Type::Unknown;
    bool m_videoReady = false;
    QUrl m_imagePath;
    QString m_source;
    bool m_playing = false;
    FillMode m_fillMode = FillMode::PreserveAspectCrop;
    QObject* m_videoOutput = nullptr;
    QQuickItem* m_sizeSource = nullptr;
    QString m_key;
    QSize m_bucket;
    std::atomic<quint32> m_generation = 0;
    QMetaObject::Connection m_windowConn;
    QMetaObject::Connection m_sinkConn;
    QMediaPlayer m_player;
};

} // namespace caelestia::multimedia
