#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

#include "config/enums.hpp"

namespace caelestia::services {

using LyricsBackend = config::LyricsBackend::Enum;

class LyricCandidate {
    Q_GADGET
    QML_VALUE_TYPE(lyricCandidate)

    Q_PROPERTY(caelestia::config::LyricsBackend::Enum backend READ backend)
    Q_PROPERTY(QString id READ id)
    Q_PROPERTY(QString title READ title)
    Q_PROPERTY(QString artist READ artist)
    Q_PROPERTY(QString album READ album)
    Q_PROPERTY(qreal duration READ duration)

public:
    LyricCandidate() = default;
    LyricCandidate(
        LyricsBackend backend, QString id, QString title, QString artist, QString album = {}, qreal duration = 0.0);

    [[nodiscard]] LyricsBackend backend() const;
    [[nodiscard]] QString id() const;
    [[nodiscard]] QString title() const;
    [[nodiscard]] QString artist() const;
    [[nodiscard]] QString album() const;
    [[nodiscard]] qreal duration() const;

    [[nodiscard]] bool isValid() const;
    bool operator==(const LyricCandidate& o) const noexcept;
    bool operator!=(const LyricCandidate& o) const noexcept;

private:
    LyricsBackend m_backend = LyricsBackend::Auto;
    QString m_id;
    QString m_title;
    QString m_artist;
    QString m_album;
    qreal m_duration = 0.0;
};

} // namespace caelestia::services
