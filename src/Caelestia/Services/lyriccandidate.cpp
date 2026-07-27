#include "lyriccandidate.hpp"

namespace caelestia::services {

QString LyricsBackend::toString(Backend b) {
    switch (b) {
    case LyricsBackend::Auto:
        return QStringLiteral("Auto");
    case LyricsBackend::Local:
        return QStringLiteral("Local");
    case LyricsBackend::LRCLIB:
        return QStringLiteral("LRCLIB");
    case LyricsBackend::NetEase:
        return QStringLiteral("NetEase");
    default:
        return QStringLiteral("Unknown");
    }
}

LyricCandidate::LyricCandidate(
    LyricsBackend::Backend backend, QString id, QString title, QString artist, QString album, qreal duration)
    : m_backend(backend)
    , m_id(std::move(id))
    , m_title(std::move(title))
    , m_artist(std::move(artist))
    , m_album(std::move(album))
    , m_duration(duration) {}

LyricsBackend::Backend LyricCandidate::backend() const {
    return m_backend;
}

QString LyricCandidate::id() const {
    return m_id;
}

QString LyricCandidate::title() const {
    return m_title;
}

QString LyricCandidate::artist() const {
    return m_artist;
}

QString LyricCandidate::album() const {
    return m_album;
}

qreal LyricCandidate::duration() const {
    return m_duration;
}

bool LyricCandidate::isValid() const {
    return !m_id.isEmpty();
}

bool LyricCandidate::operator==(const LyricCandidate& o) const noexcept {
    return m_backend == o.m_backend && m_id == o.m_id;
}

bool LyricCandidate::operator!=(const LyricCandidate& o) const noexcept {
    return !(*this == o);
}

} // namespace caelestia::services
