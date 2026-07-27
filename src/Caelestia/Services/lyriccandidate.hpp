#pragma once

#include <qqmlintegration.h>

namespace caelestia::services {

class LyricsBackend : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    enum Backend {
        Auto = 0,
        Local,
        LRCLIB,
        NetEase
    };
    Q_ENUM(Backend)

    Q_INVOKABLE QString toString(caelestia::services::LyricsBackend::Backend b);
};

class LyricCandidate {
    Q_GADGET
    QML_VALUE_TYPE(lyricCandidate)

    Q_PROPERTY(caelestia::services::LyricsBackend::Backend backend READ backend)
    Q_PROPERTY(QString id READ id)
    Q_PROPERTY(QString title READ title)
    Q_PROPERTY(QString artist READ artist)
    Q_PROPERTY(QString album READ album)
    Q_PROPERTY(qreal duration READ duration)

public:
    LyricCandidate() = default;
    LyricCandidate(LyricsBackend::Backend backend, QString id, QString title, QString artist, QString album = {},
        qreal duration = 0.0);

    [[nodiscard]] LyricsBackend::Backend backend() const;
    [[nodiscard]] QString id() const;
    [[nodiscard]] QString title() const;
    [[nodiscard]] QString artist() const;
    [[nodiscard]] QString album() const;
    [[nodiscard]] qreal duration() const;

    [[nodiscard]] bool isValid() const;
    bool operator==(const LyricCandidate& o) const noexcept;
    bool operator!=(const LyricCandidate& o) const noexcept;

private:
    LyricsBackend::Backend m_backend = LyricsBackend::Auto;
    QString m_id;
    QString m_title;
    QString m_artist;
    QString m_album;
    qreal m_duration = 0.0;
};

} // namespace caelestia::services
