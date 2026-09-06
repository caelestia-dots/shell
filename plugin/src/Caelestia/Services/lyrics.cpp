#include "lyrics.hpp"

#include <qdatetime.h>
#include <qdir.h>
#include <qdiriterator.h>
#include <qfileinfo.h>
#include <qjsonarray.h>
#include <qnetworkcookie.h>
#include <qnetworkcookiejar.h>
#include <qsavefile.h>
#include <qurlquery.h>

#include <algorithm>
#include <vector>

#include "config/rootnodes.hpp"
#include "config/serviceconfig.hpp"
#include "config/userpaths.hpp"

namespace {

Q_LOGGING_CATEGORY(lcLyrics, "caelestia.lyrics", QtInfoMsg)

} // namespace

namespace caelestia::services {

using Qt::StringLiterals::operator""_s;
using Qt::StringLiterals::operator""_ba;

namespace {

constexpr int k_loadDebounceMs = 50;
constexpr qreal k_indexFudge = 0.1;
constexpr int k_maxLyricsMapEntries = 2000;

[[nodiscard]] const QHash<QByteArray, QByteArray>& netEaseHeaders() {
    static const QHash<QByteArray, QByteArray> k_h = {
        { "User-Agent"_ba, "Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0"_ba },
        { "Referer"_ba, "https://music.163.com/"_ba },
    };
    return k_h;
}

[[nodiscard]] const QHash<QByteArray, QByteArray>& lrclibHeaders() {
    static const QHash<QByteArray, QByteArray> k_h = {
        { "User-Agent"_ba, "caelestia-shell (https://github.com/caelestia-dots/shell)"_ba },
    };
    return k_h;
}

[[nodiscard]] QString joinArtists(const QString& s) {
    return s.trimmed();
}

[[nodiscard]] QString sanitizeFilenamePart(const QString& s) {
    QString out;
    out.reserve(s.size());
    for (const QChar c : s) {
        if (c == u'/' || c == u'\0') {
            out.append(u'_');
        } else {
            out.append(c);
        }
    }
    return out;
}

[[nodiscard]] bool containsCi(const QString& haystack, const QString& needle) {
    return haystack.contains(needle, Qt::CaseInsensitive);
}

[[nodiscard]] bool isUnknownAlbum(const QString& album) {
    return album.trimmed().startsWith(u"unknown"_s, Qt::CaseInsensitive);
}

struct ArtistTitleSplit {
    QString artist;
    QString title;
    bool valid = false;
};

// Multi-dash policy: First-separator split (A | B - C) is preferred over last-separator (A - B | C).
// Example: "Billie Eilish - Ocean Eyes - Acoustic Version" -> artist: "Billie Eilish", title: "Ocean Eyes - Acoustic
// Version"
// Example: "Rap Samurai - Sabrina Carpenter - Nobody’s Son (Lyrics)" -> prefix: "Rap Samurai", rest: "Sabrina Carpenter
// - Nobody's Son"
// Last-separator (A - B | C) would erroneously classify "Billie Eilish - Ocean Eyes" as artist and "Acoustic Version"
// as title.
[[nodiscard]] ArtistTitleSplit splitArtistTitle(const QString& title) {
    const QString trimmed = title.trimmed();
    if (trimmed.isEmpty()) {
        return {};
    }
    static const QRegularExpression k_sepRegex(u"\\s+-\\s+|\\s*[\\x{2013}\\x{2014}]\\s*"_s);
    const auto match = k_sepRegex.match(trimmed);
    if (!match.hasMatch()) {
        return {};
    }
    const QString prefix = trimmed.left(match.capturedStart()).trimmed();
    const QString stripped = trimmed.mid(match.capturedEnd()).trimmed();
    if (prefix.isEmpty() || stripped.isEmpty() || stripped == trimmed) {
        return {};
    }
    const QString cleanedTitle = Lyrics::cleanTrackTitle(stripped);
    return { .artist = prefix, .title = cleanedTitle.isEmpty() ? stripped : cleanedTitle, .valid = true };
}

[[nodiscard]] QUrl buildLrclibGetUrl(
    const QString& track, const QString& artist, const QString& album, qreal duration) {
    QUrl url(u"https://lrclib.net/api/get"_s);
    QUrlQuery q;
    q.addQueryItem(u"track_name"_s, track);
    q.addQueryItem(u"artist_name"_s, artist);
    if (!album.isEmpty() && !isUnknownAlbum(album)) {
        q.addQueryItem(u"album_name"_s, album);
    }
    constexpr qreal k_maxDurationSecs = std::numeric_limits<int>::max();
    if (duration > 0 && qIsFinite(duration) && duration < k_maxDurationSecs) {
        q.addQueryItem(u"duration"_s, QString::number(qRound(duration)));
    }
    url.setQuery(q);
    return url;
}

[[nodiscard]] QUrl buildLrclibSearchUrl(const QString& track, const QString& artist) {
    QUrl url(u"https://lrclib.net/api/search"_s);
    QUrlQuery q;
    q.addQueryItem(u"track_name"_s, track);
    q.addQueryItem(u"artist_name"_s, artist);
    url.setQuery(q);
    return url;
}

[[nodiscard]] bool isLrclibNotFound(const QNetworkReply* reply) {
    if (reply == nullptr) {
        return false;
    }
    if (reply->error() == QNetworkReply::ContentNotFoundError) {
        return true;
    }
    const QVariant status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute);
    return status.isValid() && status.toInt() == 404;
}

[[nodiscard]] bool isOfflineNetworkError(QNetworkReply::NetworkError code) {
    switch (code) {
    case QNetworkReply::HostNotFoundError:
    case QNetworkReply::ConnectionRefusedError:
    case QNetworkReply::TimeoutError:
    case QNetworkReply::TemporaryNetworkFailureError:
    case QNetworkReply::NetworkSessionFailedError:
    case QNetworkReply::BackgroundRequestNotAllowedError:
    case QNetworkReply::UnknownNetworkError:
        return true;
    default:
        return false;
    }
}

[[nodiscard]] QString normalizeForComp(QString s) {
    s = s.trimmed().toLower();
    s.replace(u'’', u'\'');
    s.replace(u'“', u'\"');
    s.replace(u'”', u'\"');
    return s;
}

[[nodiscard]] QString cleanArtist(const QString& artist) {
    if (artist.isEmpty()) {
        return {};
    }
    QString s = artist.trimmed();
    static const QRegularExpression k_channelSuffixRegex(
        u"(?:\\s*[-–—]?\\s*topic|\\s*[-–—]?\\s*vevo|\\s+official(?:\\s*channel)?|\\s*[-–—]\\s*official(?:\\s*channel)?)\\s*$"_s,
        QRegularExpression::CaseInsensitiveOption);
    s.remove(k_channelSuffixRegex);
    s = s.trimmed();
    static const QRegularExpression k_trailingDashRegex(u"\\s*[-–—]\\s*$"_s);
    s.remove(k_trailingDashRegex);
    return s.isEmpty() ? artist.trimmed() : s;
}

[[nodiscard]] bool matchesArtist(const QString& a, const QString& b) {
    if (a.isEmpty() || b.isEmpty()) {
        return false;
    }
    const QString na = normalizeForComp(cleanArtist(a));
    const QString nb = normalizeForComp(cleanArtist(b));
    if (na == nb) {
        return true;
    }
    const QString pa = normalizeForComp(Lyrics::extractPrimaryArtist(cleanArtist(a)));
    const QString pb = normalizeForComp(Lyrics::extractPrimaryArtist(cleanArtist(b)));
    return !pa.isEmpty() && !pb.isEmpty() && pa == pb;
}

[[nodiscard]] QString sanitizeSuggestedTitle(const QString& rawTitle, QString& sugArtist) {
    if (rawTitle.isEmpty()) {
        return {};
    }
    const QString cleaned = Lyrics::cleanTrackTitle(rawTitle);
    QString target = cleaned.isEmpty() ? rawTitle : cleaned;
    const ArtistTitleSplit split = splitArtistTitle(target);
    if (split.valid) {
        if (sugArtist.isEmpty() || matchesArtist(split.artist, sugArtist)) {
            sugArtist = cleanArtist(split.artist);
            return split.title;
        }
        if (matchesArtist(split.title, sugArtist)) {
            sugArtist = cleanArtist(split.title);
            const QString cleanedPrefix = Lyrics::cleanTrackTitle(split.artist);
            return cleanedPrefix.isEmpty() ? split.artist : cleanedPrefix;
        }
    }
    sugArtist = cleanArtist(sugArtist);
    return target;
}

[[nodiscard]] std::pair<QString, QString> findCandidateMetadata(const QList<LyricCandidate>& candidates) {
    for (const auto& cand : candidates) {
        if (cand.isValid() && !cand.title().isEmpty() && !cand.artist().isEmpty()) {
            return { cand.artist(), cand.title() };
        }
    }
    return {};
}

[[nodiscard]] QUrl buildNetEaseSearchUrl(const QString& cleanTitle, const QString& artistQuery) {
    QUrl url(u"https://music.163.com/api/search/get"_s);
    QUrlQuery q;
    q.addQueryItem(u"s"_s, u"%1 %2"_s.arg(cleanTitle, artistQuery));
    q.addQueryItem(u"type"_s, u"1"_s);
    q.addQueryItem(u"limit"_s, u"5"_s);
    url.setQuery(q);
    return url;
}

[[nodiscard]] qint64 findBestNetEaseSongId(
    const QJsonArray& songs, const QString& artist, const QString& primaryArtist) {
    for (const auto& v : songs) {
        const QJsonObject s = v.toObject();
        const QJsonArray artists = s.value(u"artists"_s).toArray();
        if (artists.isEmpty()) {
            continue;
        }
        const QString sArtist = artists.first().toObject().value(u"name"_s).toString();
        if (containsCi(artist, sArtist) || containsCi(sArtist, artist) || containsCi(primaryArtist, sArtist) ||
            containsCi(sArtist, primaryArtist)) {
            return static_cast<qint64>(s.value(u"id"_s).toDouble());
        }
    }
    return -1;
}

struct LrcIndexEntry {
    QString path;
    QString fileName;
};

[[nodiscard]] const std::vector<LrcIndexEntry>& cachedLrcEntries(const QString& dir) {
    static QString s_cachedDir;
    static QDateTime s_cachedMtime;
    static std::vector<LrcIndexEntry> s_cachedEntries;
    static bool s_cacheValid = false;

    const QDateTime curMtime = QFileInfo(dir).lastModified();
    if (s_cacheValid && s_cachedDir == dir && s_cachedMtime == curMtime) {
        return s_cachedEntries;
    }

    s_cachedDir = dir;
    s_cachedMtime = curMtime;
    s_cachedEntries.clear();

    if (!dir.isEmpty()) {
        QDirIterator it(dir, QStringList{ u"*.lrc"_s }, QDir::Files | QDir::NoDotAndDotDot,
            QDirIterator::Subdirectories | QDirIterator::FollowSymlinks);
        while (it.hasNext()) {
            const QString path = it.next();
            s_cachedEntries.push_back(LrcIndexEntry{ .path = path, .fileName = it.fileName() });
        }
    }

    s_cacheValid = true;
    return s_cachedEntries;
}

void pruneLyricsMap(QJsonObject& map, const QString& keepKey) {
    if (map.size() <= k_maxLyricsMapEntries) {
        return;
    }

    struct UsageEntry {
        qint64 lastUsed = 0;
        QString key;
    };

    std::vector<UsageEntry> usage;
    usage.reserve(static_cast<std::size_t>(map.size()));
    for (auto it = map.constBegin(); it != map.constEnd(); ++it) {
        if (it.key() == keepKey) {
            continue;
        }
        const qint64 lastUsed = static_cast<qint64>(it.value().toObject().value(u"lastUsed"_s).toDouble(0.0));
        usage.push_back(UsageEntry{ .lastUsed = lastUsed, .key = it.key() });
    }

    std::ranges::sort(usage, [](const UsageEntry& a, const UsageEntry& b) {
        return a.lastUsed < b.lastUsed;
    });

    const auto toRemove = static_cast<std::size_t>(map.size() - k_maxLyricsMapEntries);
    for (std::size_t i = 0; i < toRemove && i < usage.size(); ++i) {
        map.remove(usage[i].key);
    }
}

} // namespace

QString Lyrics::cleanTrackTitle(const QString& title) {
    if (title.isEmpty()) {
        return {};
    }

    QString s = title.normalized(QString::NormalizationForm_C);

    // 1. Strip YouTube 11-character video IDs: [kffacxfA7G4]
    static const QRegularExpression k_ytIdRegex(u"\\[[a-zA-Z0-9_-]{11}\\]"_s);
    s.remove(k_ytIdRegex);

    // 2. Strip bracketed boilerplate (supporting ASCII + CJK/Full-width brackets)
    // Brackets: ( ) [ ] { } （ ） ［ ］ 【 】 「 」 『 』
    static const QRegularExpression k_boilerplateRegex(
        u"\\s*[\\(\\[\\{\\x{FF08}\\x{FF3B}\\x{3010}\\x{300C}\\x{300E}][^"
        u"\\)\\]\\}\\x{FF09}\\x{FF3D}\\x{3011}\\x{300D}\\x{300F}]*?"
        u"(?:official\\s*(?:music\\s*video|video|audio|lyrics?(?:\\s*video)?|"
        u"visualizer)?|music\\s*video|lyrics?(?:\\s*video)?|visualizer|audio|"
        u"remaster(?:ed)?|4k|hd|hq|pv|mv|full\\s*ver(?:sion)?|live(?:"
        u"\\s+at\\s+[^\\)\\]\\}]+)?|prod(?:\\.|\\s+by)[^\\)\\]\\}]+|"
        u"from\\s+(?:the\\s+)?(?:original\\s+)?(?:motion\\s+picture|soundtrack|film|movie|series|anime|game|show)[^\\)"
        u"\\]\\}]*|"
        u"spider-man[^\\)\\]\\}]*|(?:original\\s+)?soundtrack|\\bost\\b|theme\\s+song|movie\\s+ver(?:sion)?|film\\s+"
        u"ver(?:sion)?|anime\\s+ver(?:sion)"
        u"?)"
        u"[^\\)\\]\\}\\x{FF09}\\x{FF3D}\\x{3011}\\x{300D}\\x{300F}]*?"
        u"[\\)\\]\\}\\x{FF09}\\x{FF3D}\\x{3011}\\x{300D}\\x{300F}]"_s,
        QRegularExpression::CaseInsensitiveOption);
    s.remove(k_boilerplateRegex);

    // 3. Strip bracketed feature tags: (feat. Ludacris) or [ft. Artist]
    static const QRegularExpression k_bracketedFeatRegex(
        u"\\s*[\\(\\[\\{\\x{FF08}\\x{FF3B}\\x{3010}]\\s*(?:ft\\.?|feat\\.?|featuring|with)\\s+[^\\)\\]\\}\\x{FF09}\\x{FF3D}\\x{3011}]+[\\)\\]\\}\\x{FF09}\\x{FF3D}\\x{3011}]"_s,
        QRegularExpression::CaseInsensitiveOption);
    s.remove(k_bracketedFeatRegex);

    // 4. Strip trailing unbracketed feature tags: "Track Title feat. Artist"
    static const QRegularExpression k_trailingFeatRegex(
        u"\\s*(?:\\bft\\.?|\\bfeat\\.?|\\bfeaturing)\\s+.*$"_s, QRegularExpression::CaseInsensitiveOption);
    s.remove(k_trailingFeatRegex);

    s = s.trimmed();
    return s.isEmpty() ? title.trimmed() : s;
}

QString Lyrics::extractPrimaryArtist(const QString& artist) {
    if (artist.isEmpty()) {
        return {};
    }
    static const QRegularExpression k_splitRegex(
        u"\\s*(?:,|;|/|&|\\bft\\.?|\\bfeat\\.?|\\bfeaturing|\\bwith|\\bx\\b|\\b\\x{00D7}\\b)\\s*"_s,
        QRegularExpression::CaseInsensitiveOption);
    const QStringList parts = artist.split(k_splitRegex, Qt::SkipEmptyParts);
    return parts.isEmpty() ? artist.trimmed() : parts.first().trimmed();
}

class ResettingCookieJar : public QNetworkCookieJar {
public:
    using QNetworkCookieJar::QNetworkCookieJar;

    void clear() { setAllCookies({}); }
};

Lyrics::Lyrics(QObject* parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
    , m_cookieJar(new ResettingCookieJar(m_nam))
    , m_loadDebounce(new QTimer(this))
    , m_saveDebounce(new QTimer(this)) {
    m_nam->setCookieJar(m_cookieJar);

    m_loadDebounce->setSingleShot(true);
    m_loadDebounce->setInterval(k_loadDebounceMs);
    QObject::connect(m_loadDebounce, &QTimer::timeout, this, &Lyrics::doLoad);

    m_saveDebounce->setSingleShot(true);
    m_saveDebounce->setInterval(400);
    QObject::connect(m_saveDebounce, &QTimer::timeout, this, &Lyrics::persistTrackPrefs);

    const auto* cfg = config::ConfigSingleton::instance();
    const auto* svcCfg = cfg->services();
    const auto* paths = cfg->paths();

    m_preferredBackend = svcCfg->lyricsBackend();

    QObject::connect(
        svcCfg, &config::ServiceConfig::lyricsBackendChanged, this, &Lyrics::onPreferredBackendConfigChanged);
    QObject::connect(paths, &config::UserPaths::lyricsDirChanged, this, &Lyrics::onLyricsDirChanged);

    loadLyricsMap();
}

Lyrics::~Lyrics() {
    if (m_loadDebounce) {
        m_loadDebounce->stop();
    }
    cancelInFlight();
    if (m_saveDebounce && m_saveDebounce->isActive()) {
        m_saveDebounce->stop();
        persistTrackPrefs();
    }
}

QStringList Lyrics::lyrics() const {
    return m_lyrics;
}

LyricsBackend Lyrics::backend() const {
    return m_backend;
}

LyricsBackend Lyrics::preferredBackend() const {
    return m_preferredBackend;
}

void Lyrics::setPreferredBackend(LyricsBackend value) {
    if (m_preferredBackend == value) {
        return;
    }
    m_preferredBackend = value;
    emit preferredBackendChanged();

    config::ConfigSingleton::instance()->services()->set_lyricsBackend(value);

    scheduleLoad();
}

QList<LyricCandidate> Lyrics::lyricCandidates() const {
    return m_candidates;
}

LyricCandidate Lyrics::selectedCandidate() const {
    return m_selected;
}

LyricCandidate Lyrics::autoCandidate() const {
    return m_autoCandidate;
}

bool Lyrics::hasCandidateOverride() const {
    return m_hasCandidateOverride;
}

bool Lyrics::loadCachedLyrics(const LyricCandidate& value) {
    const auto b = value.backend();
    if (b != LyricsBackend::LRCLIB && b != LyricsBackend::NetEase) {
        return false;
    }
    const QString cached = readCachedLrc(b, value.id());
    if (cached.isEmpty()) {
        return false;
    }
    const auto lines = parseLrc(cached);
    if (lines.isEmpty()) {
        return false;
    }
    setLines(lines, b);
    setLoading(false);
    if (!m_settingFromPrefs && !rawTrackKey().isEmpty() && m_saveDebounce) {
        m_saveDebounce->start();
    }
    return true;
}

void Lyrics::loadLocalLyricFile(const QString& path) {
    // For local, the id is the file path. Read directly.
    QFile f(path);
    if (f.open(QIODevice::ReadOnly)) {
        const QString text = QString::fromUtf8(f.readAll());
        const auto lines = parseLrc(text);
        if (lines.isEmpty()) {
            setError(QStringLiteral("empty or invalid LRC file: %1").arg(path));
            setOffline(false);
        } else {
            setLines(lines, LyricsBackend::Local);
        }
    } else {
        qCWarning(lcLyrics) << "selectedCandidate: cannot open local file" << path;
        setError(QStringLiteral("cannot open %1: %2").arg(path, f.errorString()));
        setOffline(false);
    }
    setLoading(false);
}

void Lyrics::setSelectedCandidate(const LyricCandidate& value) {
    if (m_selected == value) {
        return;
    }
    m_selected = value;
    emit selectedCandidateChanged();
    updateMetadataSuggestion();

    if (m_autoCandidate.isValid() && value == m_autoCandidate) {
        if (m_hasCandidateOverride) {
            m_hasCandidateOverride = false;
            emit hasCandidateOverrideChanged();
        }
    } else if (!m_settingFromPrefs) {
        if (!m_hasCandidateOverride) {
            m_hasCandidateOverride = true;
            emit hasCandidateOverrideChanged();
        }
    }

    if (!value.isValid()) {
        return;
    }

    appendCandidates({ value });

    const auto b = value.backend();
    setBackend(b);

    if (loadCachedLyrics(value)) {
        return;
    }

    setLoading(true);

    if (!m_settingFromPrefs) {
        cancelInFlight();
    }
    const int reqId = m_settingFromPrefs ? m_currentRequestId : newRequestId();

    if (b == LyricsBackend::LRCLIB) {
        fetchLrclibById(value.id(), reqId);
    } else if (b == LyricsBackend::NetEase) {
        fetchNetEaseLyricsById(value.id(), reqId);
    } else if (b == LyricsBackend::Local) {
        loadLocalLyricFile(value.id());
    }

    if (!m_settingFromPrefs && !rawTrackKey().isEmpty() && m_saveDebounce) {
        m_saveDebounce->start();
    }
}

void Lyrics::resetToAuto() {
    if (!m_hasCandidateOverride && (!m_autoCandidate.isValid() || m_selected == m_autoCandidate)) {
        return;
    }
    m_hasCandidateOverride = false;
    emit hasCandidateOverrideChanged();

    if (!rawTrackKey().isEmpty() && m_saveDebounce) {
        m_saveDebounce->start();
    }

    if (m_autoCandidate.isValid()) {
        setSelectedCandidate(m_autoCandidate);
    } else {
        refresh();
    }
}

void Lyrics::forceSearch() {
    if (m_forceSearching) {
        return;
    }
    const QString rawTitle = m_title.trimmed();
    const QString rawArtist = m_artist.trimmed();
    if (rawTitle.isEmpty() && rawArtist.isEmpty()) {
        return;
    }
    const int reqId = m_currentRequestId;

    setLoading(true);
    setForceSearching(true);

    auto pending = std::make_shared<int>(2);
    auto checkFinished = [this, reqId, pending] {
        if (--(*pending) <= 0) {
            if (reqId == m_currentRequestId) {
                setForceSearching(false);
                setLoading(false);
            }
        }
    };

    const QUrl lrclibUrl = buildLrclibSearchUrl(rawTitle, rawArtist);
    auto* lrclibReply = getJson(lrclibUrl, lrclibHeaders());
    trackReply(reqId, lrclibReply);
    QObject::connect(lrclibReply, &QNetworkReply::finished, this, [this, lrclibReply, reqId, checkFinished] {
        lrclibReply->deleteLater();
        if (reqId != m_currentRequestId) {
            return;
        }
        if (lrclibReply->error() != QNetworkReply::NoError) {
            if (!isLrclibNotFound(lrclibReply)) {
                qCDebug(lcLyrics) << "lrclib force search error:" << lrclibReply->errorString();
                noteReplyError(lrclibReply);
            }
            checkFinished();
            return;
        }
        const QJsonDocument doc = QJsonDocument::fromJson(lrclibReply->readAll());
        appendCandidates(parseLrclibSearchResult(doc.array()).candidates);
        checkFinished();
    });

    if (m_cookieJar) {
        m_cookieJar->clear();
    }
    QUrl netEaseUrl(u"https://music.163.com/api/search/get"_s);
    QUrlQuery netEaseQuery;
    netEaseQuery.addQueryItem(u"s"_s, u"%1 %2"_s.arg(rawTitle, rawArtist));
    netEaseQuery.addQueryItem(u"type"_s, u"1"_s);
    netEaseQuery.addQueryItem(u"limit"_s, u"5"_s);
    netEaseUrl.setQuery(netEaseQuery);
    auto* netEaseReply = getJson(netEaseUrl, netEaseHeaders());
    trackReply(reqId, netEaseReply);
    QObject::connect(netEaseReply, &QNetworkReply::finished, this, [this, netEaseReply, reqId, checkFinished] {
        netEaseReply->deleteLater();
        if (reqId != m_currentRequestId) {
            return;
        }
        if (netEaseReply->error() != QNetworkReply::NoError) {
            qCDebug(lcLyrics) << "netease force search error:" << netEaseReply->errorString();
            noteReplyError(netEaseReply);
            checkFinished();
            return;
        }
        const QJsonDocument doc = QJsonDocument::fromJson(netEaseReply->readAll());
        appendCandidates(parseNetEaseSearchResult(doc));
        checkFinished();
    });
}

bool Lyrics::loading() const {
    return m_loading;
}

bool Lyrics::forceSearching() const {
    return m_forceSearching;
}

bool Lyrics::hasLyrics() const {
    return m_hasLyrics;
}

bool Lyrics::hasMetadataSuggestion() const {
    return m_hasMetadataSuggestion;
}

QString Lyrics::suggestedArtist() const {
    return m_suggestedArtist;
}

QString Lyrics::suggestedTitle() const {
    return m_suggestedTitle;
}

qreal Lyrics::offset() const {
    return m_offset;
}

void Lyrics::setOffset(qreal value) {
    if (qFuzzyCompare(m_offset + 1.0, value + 1.0)) {
        return;
    }
    m_offset = value;
    emit offsetChanged();

    if (!m_settingFromPrefs && !rawTrackKey().isEmpty()) {
        if (m_saveDebounce) {
            m_saveDebounce->start();
        }
    }
}

QString Lyrics::trackArtist() const {
    return m_artist;
}

QString Lyrics::trackTitle() const {
    return m_title;
}

QString Lyrics::error() const {
    return m_error;
}

bool Lyrics::offline() const {
    return m_offline;
}

int Lyrics::indexForTime(qreal time) const {
    if (m_lines.isEmpty()) {
        return -1;
    }
    const qreal target = time - m_offset + k_indexFudge;
    qsizetype lo = 0;
    qsizetype hi = m_lines.size();
    while (lo < hi) {
        const qsizetype mid = lo + (hi - lo) / 2;
        if (m_lines.at(mid).time <= target) {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }
    return static_cast<int>(lo - 1);
}

qreal Lyrics::timeForIndex(int index) const {
    if (index < 0 || index >= m_lines.size()) {
        return -1.0;
    }
    return m_lines.at(index).time + m_offset;
}

void Lyrics::setTrack(const QString& artist, const QString& title, const QString& album, qreal duration) {
    const QString a = artist.trimmed();
    const QString t = title.trimmed();

    m_rawArtist = a;
    m_rawTitle = t;

    QString effectiveArtist = a;
    QString effectiveTitle = t;
    resolveMetadataAlias(effectiveArtist, effectiveTitle);

    if (effectiveArtist == m_artist && effectiveTitle == m_title && album == m_album &&
        qFuzzyCompare(duration + 1.0, m_duration + 1.0)) {
        return;
    }

    if (m_saveDebounce && m_saveDebounce->isActive()) {
        m_saveDebounce->stop();
        persistTrackPrefs();
    }

    cancelInFlight();

    m_artist = effectiveArtist;
    m_title = effectiveTitle;
    m_album = album;
    m_duration = duration;
    emit trackChanged();

    m_selected = LyricCandidate();
    emit selectedCandidateChanged();
    m_autoCandidate = LyricCandidate();
    emit autoCandidateChanged();
    m_hasCandidateOverride = false;
    emit hasCandidateOverrideChanged();
    m_offset = 0.0;
    emit offsetChanged();
    clearLines();
    clearCandidates();
    updateMetadataSuggestion();

    scheduleLoad();
}

void Lyrics::clearTrack() {
    if (m_saveDebounce && m_saveDebounce->isActive()) {
        m_saveDebounce->stop();
        persistTrackPrefs();
    }
    cancelInFlight();
    m_rawArtist.clear();
    m_rawTitle.clear();
    m_artist.clear();
    m_title.clear();
    m_album.clear();
    m_duration = 0.0;
    emit trackChanged();

    m_selected = LyricCandidate();
    emit selectedCandidateChanged();
    m_autoCandidate = LyricCandidate();
    emit autoCandidateChanged();
    m_hasCandidateOverride = false;
    emit hasCandidateOverrideChanged();
    m_offset = 0.0;
    emit offsetChanged();

    m_hasMetadataSuggestion = false;
    m_suggestedArtist.clear();
    m_suggestedTitle.clear();
    emit metadataSuggestionChanged();

    clearCandidates();
    clearLines();
    setError(QString());
    setOffline(false);
    setLoading(false);
}

void Lyrics::refresh() {
    scheduleLoad();
}

void Lyrics::setBackend(LyricsBackend value) {
    if (m_backend == value) {
        return;
    }
    m_backend = value;
    emit backendChanged();
}

void Lyrics::setLoading(bool value) {
    if (m_loading == value) {
        return;
    }
    m_loading = value;
    emit loadingChanged();
}

void Lyrics::setForceSearching(bool value) {
    if (m_forceSearching == value) {
        return;
    }
    m_forceSearching = value;
    emit forceSearchingChanged();
}

void Lyrics::setError(const QString& value) {
    if (m_error != value) {
        m_error = value;
        emit errorChanged();
    }
}

void Lyrics::setOffline(bool value) {
    if (m_offline != value) {
        m_offline = value;
        emit offlineChanged();
    }
}

void Lyrics::noteReplyError(QNetworkReply* reply) {
    if (reply == nullptr) {
        return;
    }
    if (isOfflineNetworkError(reply->error())) {
        setOffline(true);
        setError(QString());
    } else {
        setError(reply->errorString());
        setOffline(false);
    }
}

void Lyrics::setLines(QVector<LyricLine> lines, LyricsBackend source) {
    std::ranges::sort(lines, [](const LyricLine& a, const LyricLine& b) {
        return a.time < b.time;
    });

    m_lines = std::move(lines);
    QStringList list;
    list.reserve(m_lines.size());
    for (const auto& l : std::as_const(m_lines)) {
        list.append(l.text);
    }
    m_lyrics = std::move(list);

    setBackend(source);
    emit lyricsChanged();

    const auto hasLyrics = !m_lines.isEmpty();
    if (hasLyrics != m_hasLyrics) {
        m_hasLyrics = hasLyrics;
        emit hasLyricsChanged();
    }

    setError(QString());
    setOffline(false);
}

void Lyrics::clearLines() {
    // Doesn't actually clear lines, set a flag instead so anims can run
    if (m_hasLyrics) {
        m_hasLyrics = false;
        emit hasLyricsChanged();
        emit lyricsChanged();
    }
}

bool Lyrics::compareCandidates(const LyricCandidate& a, const LyricCandidate& b) const {
    // 1. autoCandidate always ranks first
    if (m_autoCandidate.isValid()) {
        if (a == m_autoCandidate) {
            return true;
        }
        if (b == m_autoCandidate) {
            return false;
        }
    }
    // 2. Duration matching if duration is known
    if (m_duration > 0.0) {
        const qreal diffA = a.duration() > 0.0 ? std::abs(a.duration() - m_duration) : 99999.0;
        const qreal diffB = b.duration() > 0.0 ? std::abs(b.duration() - m_duration) : 99999.0;
        if (std::abs(diffA - diffB) > 1.0) {
            return diffA < diffB;
        }
    }
    return false;
}

void Lyrics::appendCandidates(const QList<LyricCandidate>& add) {
    if (add.isEmpty()) {
        return;
    }
    bool changed = false;
    for (const auto& c : add) {
        if (!m_candidates.contains(c)) {
            m_candidates.append(c);
            changed = true;
        }
    }
    if (changed) {
        std::ranges::stable_sort(m_candidates, [this](const LyricCandidate& a, const LyricCandidate& b) {
            return compareCandidates(a, b);
        });

        emit lyricCandidatesChanged();
        updateMetadataSuggestion();
    }
}

void Lyrics::clearCandidates() {
    if (m_candidates.isEmpty()) {
        return;
    }
    m_candidates.clear();
    emit lyricCandidatesChanged();
}

void Lyrics::scheduleLoad() {
    m_loadDebounce->start();
}

int Lyrics::newRequestId() {
    return ++m_currentRequestId;
}

void Lyrics::cancelInFlight() {
    m_currentRequestId++;

    for (auto it = m_pendingReplies.begin(); it != m_pendingReplies.end(); ++it) {
        for (auto& ptr : it.value()) {
            if (auto* reply = ptr.data()) {
                reply->disconnect(this);
                reply->abort();
                reply->deleteLater();
            }
        }
    }
    m_pendingReplies.clear();
    setForceSearching(false);
}

void Lyrics::trackReply(int reqId, QNetworkReply* reply) {
    if (!reply) {
        return;
    }
    m_pendingReplies[reqId].append(QPointer<QNetworkReply>(reply));
    QObject::connect(reply, &QObject::destroyed, this, [this, reqId, reply] {
        if (auto it = m_pendingReplies.find(reqId); it != m_pendingReplies.end()) {
            it.value().removeIf([reply](const QPointer<QNetworkReply>& ptr) {
                return ptr.isNull() || ptr.data() == reply;
            });
            if (it.value().isEmpty()) {
                m_pendingReplies.erase(it);
            }
        }
    });
}

void Lyrics::doLoad() {
    if (m_artist.isEmpty() && m_title.isEmpty()) {
        clearLines();
        clearCandidates();
        setLoading(false);
        return;
    }

    cancelInFlight();
    const int reqId = newRequestId();

    setLoading(true);
    clearLines();
    clearCandidates();
    setError(QString());
    setOffline(false);

    m_autoCandidate = LyricCandidate();
    emit autoCandidateChanged();

    // Restore per-track prefs (offset, last-selected backend/id)
    m_settingFromPrefs = true;
    const QJsonObject saved = m_lyricsMap.value(rawTrackKey()).toObject();
    setOffset(saved.value(u"offset"_s).toDouble(0.0));
    LyricCandidate restored;
    const QString savedBackendKey = saved.value(u"backend"_s).toString();
    const QString savedId = saved.value(u"id"_s).toString();
    const qreal savedDuration = saved.value(u"duration"_s).toDouble(0.0);
    if (!savedBackendKey.isEmpty() && !savedId.isEmpty()) {
        restored = LyricCandidate(backendFromKey(savedBackendKey), savedId, m_title, m_artist, m_album,
            savedDuration > 0.0 ? savedDuration : m_duration);
    }
    m_settingFromPrefs = false;

    if (restored.isValid()) {
        if (m_duration > 10.0 && savedDuration > 0.0 && std::abs(savedDuration - m_duration) > 25.0) {
            qCWarning(lcLyrics) << "Ignoring stored candidate override" << restored.id()
                                << "due to duration mismatch:" << savedDuration << "vs track" << m_duration;
            m_hasCandidateOverride = false;
            emit hasCandidateOverrideChanged();
        } else {
            m_hasCandidateOverride = true;
            emit hasCandidateOverrideChanged();
            m_settingFromPrefs = true;
            setSelectedCandidate(restored);
            m_settingFromPrefs = false;
            // Restored override already resolved the selection (cached or fetch by id in
            // flight); skip the unconditional candidate fan-out.
            return;
        }
    } else {
        m_hasCandidateOverride = false;
        emit hasCandidateOverrideChanged();
    }

    if (m_preferredBackend == LyricsBackend::Local) {
        tryLocal(reqId);
        if (m_hasLyrics) {
            // Local already hit synchronously; skip online fan-out.
            return;
        }
        searchLrclibCandidates(reqId);
        searchNetEaseCandidates(reqId);
        return;
    }

    if (m_preferredBackend == LyricsBackend::NetEase) {
        // Single shared NetEase query: tryNetEase also appends picker candidates,
        // so skip the separate searchNetEaseCandidates fan-out.
        searchLrclibCandidates(reqId);
        tryNetEase(reqId);
        return;
    }

    // Always populate online candidates for the picker, regardless of preferred backend
    searchLrclibCandidates(reqId);
    searchNetEaseCandidates(reqId);

    // Primary attempt by preferred backend (only if no candidate override was restored)
    if (!m_hasCandidateOverride) {
        switch (m_preferredBackend) {
        case LyricsBackend::Local:
            tryLocal(reqId);
            break;
        case LyricsBackend::LRCLIB:
            tryLrclib(reqId);
            break;
        case LyricsBackend::NetEase:
            tryNetEase(reqId);
            break;
        case LyricsBackend::Auto:
        default:
            tryLocal(reqId);
            break;
        }
    }
}

void Lyrics::chainNext(LyricsBackend justFailed, int reqId) {
    if (m_hasLyrics) {
        setLoading(false);
        return;
    }
    if (m_preferredBackend != LyricsBackend::Auto) {
        // Non-auto modes don't chain
        setLoading(false);
        return;
    }
    switch (justFailed) {
    case LyricsBackend::Local:
        tryLrclib(reqId);
        return;
    case LyricsBackend::LRCLIB:
        tryNetEase(reqId);
        return;
    case LyricsBackend::NetEase:
    default:
        setLoading(false);
        return;
    }
}

bool Lyrics::tryLoadLocalFile(const QString& path) {
    if (path.isEmpty()) {
        return false;
    }
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        return false;
    }
    const QString text = QString::fromUtf8(f.readAll());
    const auto lines = parseLrc(text);
    if (lines.isEmpty()) {
        return false;
    }
    const LyricCandidate cand(LyricsBackend::Local, path, m_title, m_artist, m_album, m_duration);
    if (!m_autoCandidate.isValid()) {
        m_autoCandidate = cand;
        emit autoCandidateChanged();
    }
    appendCandidates({ cand });
    if (!m_hasCandidateOverride) {
        setLines(lines, LyricsBackend::Local);
        m_selected = cand;
        emit selectedCandidateChanged();
    }
    updateMetadataSuggestion();
    setLoading(false);
    return true;
}

void Lyrics::tryLocal(int reqId) {
    if (reqId != m_currentRequestId) {
        return;
    }

    setBackend(LyricsBackend::Local);

    const QString dir = lyricsDir();
    if (dir.isEmpty()) {
        chainNext(LyricsBackend::Local, reqId);
        return;
    }

    if (tryLoadLocalFile(tryReadLocalLrc(dir, m_artist, m_title))) {
        return;
    }

    if (tryLoadLocalFile(findLocalLrcRecursive(dir, m_artist, m_title))) {
        return;
    }

    qCDebug(lcLyrics) << "no local lrc for" << m_artist << "-" << m_title;
    chainNext(LyricsBackend::Local, reqId);
}

bool Lyrics::applyLrclibGetObject(const QJsonObject& obj, const QString& logTrack, const QString& logArtist) {
    const QString synced = obj.value(u"syncedLyrics"_s).toString();
    if (synced.isEmpty()) {
        qCDebug(lcLyrics) << "lrclib: no syncedLyrics for" << logArtist << "-" << logTrack;
        return false;
    }
    const auto lines = parseLrc(synced);
    if (lines.isEmpty()) {
        return false;
    }
    const qint64 id = static_cast<qint64>(obj.value(u"id"_s).toDouble());
    writeCachedLrc(LyricsBackend::LRCLIB, QString::number(id), synced);
    const LyricCandidate cand(LyricsBackend::LRCLIB, QString::number(id), obj.value(u"trackName"_s).toString(),
        obj.value(u"artistName"_s).toString(), obj.value(u"albumName"_s).toString(),
        obj.value(u"duration"_s).toDouble());
    if (!m_autoCandidate.isValid()) {
        m_autoCandidate = cand;
        emit autoCandidateChanged();
    }
    appendCandidates({ cand });
    if (!m_hasCandidateOverride) {
        setLines(lines, LyricsBackend::LRCLIB);
        m_selected = cand;
        emit selectedCandidateChanged();
    }
    updateMetadataSuggestion();
    setLoading(false);
    return true;
}

void Lyrics::retryLrclibGetSplit(
    int reqId, const QString& title, const QString& artist, const QString& album, qreal duration) {
    qCDebug(lcLyrics) << "lrclib /get retry split:" << artist << "-" << title;
    const QUrl retryUrl = buildLrclibGetUrl(title, artist, album, duration);
    auto* retry = getJson(retryUrl, lrclibHeaders());
    trackReply(reqId, retry);
    QObject::connect(retry, &QNetworkReply::finished, this, [this, retry, reqId, title, artist, album, duration] {
        retry->deleteLater();
        if (reqId != m_currentRequestId) {
            return;
        }
        if (retry->error() != QNetworkReply::NoError) {
            if (duration > 0.0 && isLrclibNotFound(retry)) {
                retryLrclibGetSplit(reqId, title, artist, album, 0.0);
                return;
            }
            if (isLrclibNotFound(retry)) {
                chainNext(LyricsBackend::LRCLIB, reqId);
                return;
            }
            qCDebug(lcLyrics) << "lrclib /get retry error:" << retry->errorString();
            if (!m_hasLyrics) {
                noteReplyError(retry);
            }
            chainNext(LyricsBackend::LRCLIB, reqId);
            return;
        }
        const QJsonObject retryObj = QJsonDocument::fromJson(retry->readAll()).object();
        if (!applyLrclibGetObject(retryObj, title, artist)) {
            chainNext(LyricsBackend::LRCLIB, reqId);
        }
    });
}

void Lyrics::tryLrclib(int reqId) {
    if (reqId != m_currentRequestId) {
        return;
    }

    setBackend(LyricsBackend::LRCLIB);

    const QString cleanTitle = cleanTrackTitle(m_title);
    const QString primaryArtist = extractPrimaryArtist(m_artist);
    const QString album = m_album;
    const qreal duration = m_duration;

    const QUrl url = buildLrclibGetUrl(cleanTitle, primaryArtist, album, duration);
    auto* reply = getJson(url, lrclibHeaders());
    trackReply(reqId, reply);

    QObject::connect(
        reply, &QNetworkReply::finished, this, [this, reply, reqId, cleanTitle, primaryArtist, album, duration] {
            reply->deleteLater();
            if (reqId != m_currentRequestId) {
                return;
            }
            if (reply->error() != QNetworkReply::NoError) {
                if (isLrclibNotFound(reply)) {
                    ArtistTitleSplit split = splitArtistTitle(cleanTitle);
                    if (!split.valid) {
                        split = splitArtistTitle(m_title);
                    }
                    if (split.valid && (split.title != cleanTitle || split.artist != primaryArtist)) {
                        retryLrclibGetSplit(reqId, split.title, split.artist, QString(), duration);
                        return;
                    }
                    chainNext(LyricsBackend::LRCLIB, reqId);
                    return;
                }
                qCDebug(lcLyrics) << "lrclib /get error:" << reply->errorString();
                if (!m_hasLyrics) {
                    noteReplyError(reply);
                }
                chainNext(LyricsBackend::LRCLIB, reqId);
                return;
            }
            const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
            if (!applyLrclibGetObject(doc.object(), cleanTitle, primaryArtist)) {
                chainNext(LyricsBackend::LRCLIB, reqId);
            }
        });
}

void Lyrics::tryNetEase(int reqId) {
    if (reqId != m_currentRequestId) {
        return;
    }

    setBackend(LyricsBackend::NetEase);

    // Reset cookies (LyricsBackend::NetEase rejects requests with stale cookies sometimes)
    if (m_cookieJar) {
        m_cookieJar->clear();
    }

    const QString cleanTitle = cleanTrackTitle(m_title);
    const QString primaryArtist = extractPrimaryArtist(m_artist);

    const QUrl url = buildNetEaseSearchUrl(cleanTitle, m_artist.isEmpty() ? primaryArtist : m_artist);

    auto* reply = getJson(url, netEaseHeaders());
    trackReply(reqId, reply);

    QObject::connect(reply, &QNetworkReply::finished, this, [this, reply, reqId, cleanTitle, primaryArtist] {
        reply->deleteLater();
        if (reqId != m_currentRequestId) {
            return;
        }
        if (reply->error() != QNetworkReply::NoError) {
            qCDebug(lcLyrics) << "netease /search error:" << reply->errorString();
            if (!m_hasLyrics) {
                noteReplyError(reply);
            }
            chainNext(LyricsBackend::NetEase, reqId);
            return;
        }

        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        // Share this single query result with the picker as well.
        appendCandidates(parseNetEaseSearchResult(doc));
        const QJsonArray songs = doc.object().value(u"result"_s).toObject().value(u"songs"_s).toArray();

        // Find best match by artist substring
        const qint64 bestId = findBestNetEaseSongId(songs, m_artist, primaryArtist);

        if (bestId < 0) {
            qCDebug(lcLyrics) << "netease: no artist match for" << m_artist << "-" << cleanTitle;
            chainNext(LyricsBackend::NetEase, reqId);
            return;
        }

        fetchNetEaseLyricsById(QString::number(bestId), reqId);
    });
}

Lyrics::LrclibSearchResult Lyrics::parseLrclibSearchResult(const QJsonArray& arr) const {
    LrclibSearchResult result;
    result.candidates.reserve(arr.size());
    qreal bestScore = -1e9;

    for (const auto& v : arr) {
        const QJsonObject o = v.toObject();
        const QString synced = o.value(u"syncedLyrics"_s).toString();
        const QString plain = o.value(u"plainLyrics"_s).toString();
        if (synced.isEmpty() && plain.isEmpty()) {
            continue;
        }
        const qint64 id = static_cast<qint64>(o.value(u"id"_s).toDouble());
        const qreal candDur = o.value(u"duration"_s).toDouble();
        const LyricCandidate cand(LyricsBackend::LRCLIB, QString::number(id), o.value(u"trackName"_s).toString(),
            o.value(u"artistName"_s).toString(), o.value(u"albumName"_s).toString(), candDur);
        result.candidates.append(cand);

        if (!synced.isEmpty()) {
            qreal score = 1000.0;
            if (m_duration > 10.0 && candDur > 0.0) {
                score -= std::abs(candDur - m_duration) * 10.0;
            }
            if (score > bestScore) {
                bestScore = score;
                result.bestCandidate = cand;
                result.bestSynced = synced;
            }
        }
    }
    return result;
}

QList<LyricCandidate> Lyrics::parseNetEaseSearchResult(const QJsonDocument& doc) {
    const QJsonArray songs = doc.object().value(u"result"_s).toObject().value(u"songs"_s).toArray();
    QList<LyricCandidate> candidates;
    candidates.reserve(songs.size());
    for (const auto& v : songs) {
        const QJsonObject s = v.toObject();
        QStringList artistNames;
        const QJsonArray artists = s.value(u"artists"_s).toArray();
        artistNames.reserve(artists.size());
        for (const auto& a : artists) {
            artistNames.append(a.toObject().value(u"name"_s).toString());
        }
        const double durMs =
            s.contains(u"duration"_s) ? s.value(u"duration"_s).toDouble() : s.value(u"dt"_s).toDouble();
        const double durSec = durMs > 0.0 ? durMs / 1000.0 : 0.0;
        candidates.append(
            LyricCandidate(LyricsBackend::NetEase, QString::number(static_cast<qint64>(s.value(u"id"_s).toDouble())),
                s.value(u"name"_s).toString(), artistNames.join(u", "_s), {}, durSec));
    }
    return candidates;
}

void Lyrics::applyLrclibCandidateUpgrade(const LyricCandidate& bestCand, const QString& bestSynced) {
    if (m_settingFromPrefs || !bestCand.isValid() || bestSynced.isEmpty()) {
        return;
    }

    const bool shouldUpgrade =
        !m_hasLyrics || (!m_selected.isValid()) ||
        (m_duration > 10.0 && m_selected.duration() > 0.0 && std::abs(m_selected.duration() - m_duration) > 10.0 &&
            std::abs(bestCand.duration() - m_duration) < 5.0);

    if (!shouldUpgrade) {
        return;
    }

    const auto lines = parseLrc(bestSynced);
    if (lines.isEmpty()) {
        return;
    }

    writeCachedLrc(LyricsBackend::LRCLIB, bestCand.id(), bestSynced);
    m_autoCandidate = bestCand;
    emit autoCandidateChanged();
    if (!m_hasCandidateOverride) {
        setLines(lines, LyricsBackend::LRCLIB);
        m_selected = bestCand;
        emit selectedCandidateChanged();
    }
    updateMetadataSuggestion();
    setLoading(false);
}

void Lyrics::retryLrclibSearchSplit(int reqId, const QString& title, const QString& artist) {
    qCDebug(lcLyrics) << "lrclib /search retry split:" << artist << "-" << title;
    const QUrl retryUrl = buildLrclibSearchUrl(title, artist);
    auto* retry = getJson(retryUrl, lrclibHeaders());
    trackReply(reqId, retry);
    QObject::connect(retry, &QNetworkReply::finished, this, [this, retry, reqId] {
        retry->deleteLater();
        if (reqId != m_currentRequestId) {
            return;
        }
        if (retry->error() != QNetworkReply::NoError) {
            if (!isLrclibNotFound(retry)) {
                qCDebug(lcLyrics) << "lrclib /search retry error:" << retry->errorString();
                if (!m_hasLyrics) {
                    noteReplyError(retry);
                }
            }
            return;
        }
        const QJsonDocument retryDoc = QJsonDocument::fromJson(retry->readAll());
        const auto retryResult = parseLrclibSearchResult(retryDoc.array());
        if (!m_autoCandidate.isValid() && retryResult.bestCandidate.isValid()) {
            m_autoCandidate = retryResult.bestCandidate;
            emit autoCandidateChanged();
            updateMetadataSuggestion();
        }
        appendCandidates(retryResult.candidates);
        applyLrclibCandidateUpgrade(retryResult.bestCandidate, retryResult.bestSynced);
    });
}

void Lyrics::searchLrclibCandidates(int reqId) {
    const QString cleanTitle = cleanTrackTitle(m_title);
    const QString primaryArtist = extractPrimaryArtist(m_artist);

    const QUrl url = buildLrclibSearchUrl(cleanTitle, primaryArtist);
    auto* reply = getJson(url, lrclibHeaders());
    trackReply(reqId, reply);

    QObject::connect(reply, &QNetworkReply::finished, this, [this, reply, reqId, cleanTitle, primaryArtist] {
        reply->deleteLater();
        if (reqId != m_currentRequestId) {
            return;
        }
        if (reply->error() != QNetworkReply::NoError) {
            if (!isLrclibNotFound(reply)) {
                qCDebug(lcLyrics) << "lrclib /search error:" << reply->errorString();
                if (!m_hasLyrics) {
                    noteReplyError(reply);
                }
            }
            return;
        }
        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        const auto result = parseLrclibSearchResult(doc.array());
        if (result.candidates.isEmpty()) {
            ArtistTitleSplit split = splitArtistTitle(cleanTitle);
            if (!split.valid) {
                split = splitArtistTitle(m_title);
            }
            if (split.valid && (split.title != cleanTitle || split.artist != primaryArtist)) {
                retryLrclibSearchSplit(reqId, split.title, split.artist);
                return;
            }
        }
        if (!m_autoCandidate.isValid() && result.bestCandidate.isValid()) {
            m_autoCandidate = result.bestCandidate;
            emit autoCandidateChanged();
            updateMetadataSuggestion();
        }
        appendCandidates(result.candidates);
        applyLrclibCandidateUpgrade(result.bestCandidate, result.bestSynced);
    });
}

void Lyrics::searchNetEaseCandidates(int reqId) {
    if (m_cookieJar) {
        m_cookieJar->clear();
    }

    const QString cleanTitle = cleanTrackTitle(m_title);
    const QString primaryArtist = extractPrimaryArtist(m_artist);

    const QUrl url = buildNetEaseSearchUrl(cleanTitle, m_artist.isEmpty() ? primaryArtist : m_artist);

    auto* reply = getJson(url, netEaseHeaders());
    trackReply(reqId, reply);

    QObject::connect(reply, &QNetworkReply::finished, this, [this, reply, reqId] {
        reply->deleteLater();
        if (reqId != m_currentRequestId) {
            return;
        }
        if (reply->error() != QNetworkReply::NoError) {
            qCDebug(lcLyrics) << "netease candidates error:" << reply->errorString();
            if (!m_hasLyrics) {
                noteReplyError(reply);
            }
            return;
        }
        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        appendCandidates(parseNetEaseSearchResult(doc));
    });
}

void Lyrics::fetchLrclibById(const QString& id, int reqId) {
    const QUrl url(u"https://lrclib.net/api/get/"_s + id);
    auto* reply = getJson(url, lrclibHeaders());
    trackReply(reqId, reply);

    QObject::connect(reply, &QNetworkReply::finished, this, [this, reply, reqId, id] {
        reply->deleteLater();
        if (reqId != m_currentRequestId) {
            return;
        }
        if (reply->error() != QNetworkReply::NoError) {
            qCWarning(lcLyrics) << "lrclib /get/{id} error:" << reply->errorString();
            noteReplyError(reply);
            setLoading(false);
            return;
        }
        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (doc.isNull() || !doc.isObject()) {
            setError(QStringLiteral("malformed JSON from LRCLIB"));
            setOffline(false);
            setLoading(false);
            return;
        }
        const QString synced = doc.object().value(u"syncedLyrics"_s).toString();
        if (synced.isEmpty()) {
            qCDebug(lcLyrics) << "lrclib /get/{id}: no syncedLyrics";
            setError(QStringLiteral("no synced lyrics for id %1").arg(id));
            setOffline(false);
            setLoading(false);
            return;
        }
        writeCachedLrc(LyricsBackend::LRCLIB, id, synced);
        setLines(parseLrc(synced), LyricsBackend::LRCLIB);
        setLoading(false);
    });
}

void Lyrics::fetchNetEaseLyricsById(const QString& id, int reqId) {
    QUrl url(u"https://music.163.com/api/song/lyric"_s);
    QUrlQuery q;
    q.addQueryItem(u"id"_s, id);
    q.addQueryItem(u"lv"_s, u"1"_s);
    q.addQueryItem(u"kv"_s, u"1"_s);
    q.addQueryItem(u"tv"_s, u"-1"_s);
    url.setQuery(q);

    auto* reply = getJson(url, netEaseHeaders());
    trackReply(reqId, reply);

    QObject::connect(reply, &QNetworkReply::finished, this, [this, reply, reqId, id] {
        reply->deleteLater();
        if (reqId != m_currentRequestId) {
            return;
        }
        if (reply->error() != QNetworkReply::NoError) {
            qCWarning(lcLyrics) << "netease /lyric error:" << reply->errorString();
            noteReplyError(reply);
            setLoading(false);
            return;
        }
        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (doc.isNull() || !doc.isObject()) {
            setError(QStringLiteral("malformed JSON from NetEase"));
            setOffline(false);
            setLoading(false);
            return;
        }
        if (doc.object().value(u"code"_s).toInt(200) == 404) {
            setError(QStringLiteral("NetEase: lyric not found (404) for id %1").arg(id));
            setOffline(false);
            setLoading(false);
            return;
        }
        const QString lrc = doc.object().value(u"lrc"_s).toObject().value(u"lyric"_s).toString();
        if (lrc.isEmpty()) {
            qCDebug(lcLyrics) << "netease /lyric: empty for id" << id;
            setError(QStringLiteral("empty lyric for id %1").arg(id));
            setOffline(false);
            setLoading(false);
            return;
        }
        writeCachedLrc(LyricsBackend::NetEase, id, lrc);
        const auto lines = parseLrc(lrc);
        const LyricCandidate cand(LyricsBackend::NetEase, id, m_title, m_artist, m_album, m_duration);
        if (!m_autoCandidate.isValid()) {
            m_autoCandidate = cand;
            emit autoCandidateChanged();
        }
        appendCandidates({ cand });
        if (!m_hasCandidateOverride) {
            setLines(lines, LyricsBackend::NetEase);
            m_selected = cand;
            emit selectedCandidateChanged();
        }
        updateMetadataSuggestion();
        setLoading(false);
    });
}

void Lyrics::updateMetadataSuggestion() {
    QString sugArtist;
    QString sugTitle;

    if (m_selected.isValid() && !m_selected.title().isEmpty() && !m_selected.artist().isEmpty()) {
        sugArtist = m_selected.artist();
        sugTitle = m_selected.title();
    } else if (m_autoCandidate.isValid() && !m_autoCandidate.title().isEmpty() && !m_autoCandidate.artist().isEmpty()) {
        sugArtist = m_autoCandidate.artist();
        sugTitle = m_autoCandidate.title();
    } else {
        std::tie(sugArtist, sugTitle) = findCandidateMetadata(m_candidates);
        if (sugArtist.isEmpty() || sugTitle.isEmpty()) {
            const QString cleaned = cleanTrackTitle(m_title);
            const ArtistTitleSplit split = splitArtistTitle(cleaned.isEmpty() ? m_title : cleaned);
            if (split.valid) {
                sugArtist = split.artist;
                sugTitle = split.title;
            } else if (cleaned != m_title.trimmed()) {
                sugArtist = m_artist;
                sugTitle = cleaned;
            }
        }
    }

    sugTitle = sanitizeSuggestedTitle(sugTitle, sugArtist);

    const bool hasSuggestion = !sugArtist.isEmpty() && !sugTitle.isEmpty() &&
                               (!m_title.trimmed().isEmpty() || !m_artist.trimmed().isEmpty()) &&
                               (normalizeForComp(sugArtist) != normalizeForComp(m_artist) ||
                                   normalizeForComp(sugTitle) != normalizeForComp(m_title));

    if (hasSuggestion != m_hasMetadataSuggestion || sugArtist != m_suggestedArtist || sugTitle != m_suggestedTitle) {
        m_hasMetadataSuggestion = hasSuggestion;
        m_suggestedArtist = sugArtist;
        m_suggestedTitle = sugTitle;
        emit metadataSuggestionChanged();
    }
}

// QNAM policy: PreferNetwork is fresh-first (network is always attempted first, HTTP cache
// is only a fallback when offline or when validators allow it), so the no-stale-lyrics
// requirement is preserved: a reachable backend always wins over any cached response.
// Unlike the previous AlwaysNetwork + "Cache-Control: no-cache, no-store" + "Pragma: no-cache"
// + "Connection: close", this allows QNAM HTTP caching and, crucially, HTTP/1.1 keep-alive
// connection reuse across lrclib/NetEase requests. The on-disk LRC cache in cacheDir()
// remains authoritative for offline reuse.
QNetworkReply* Lyrics::getJson(const QUrl& url, const QHash<QByteArray, QByteArray>& headers) {
    QNetworkRequest req(url);
    req.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::PreferNetwork);
    req.setRawHeader("Connection"_ba, "keep-alive"_ba);
    req.setRawHeader("Accept"_ba, "application/json"_ba);
    for (auto it = headers.constBegin(); it != headers.constEnd(); ++it) {
        req.setRawHeader(it.key(), it.value());
    }
    return m_nam->get(req);
}

void Lyrics::onPreferredBackendConfigChanged() {
    const LyricsBackend desired = config::ConfigSingleton::instance()->services()->lyricsBackend();
    if (desired == m_preferredBackend) {
        return;
    }
    m_preferredBackend = desired;
    emit preferredBackendChanged();
    scheduleLoad();
}

void Lyrics::onLyricsDirChanged() {
    scheduleLoad();
}

void Lyrics::loadLyricsMap() {
    m_lyricsMap = {};
    m_lyricsMapLoaded = false;

    QFile f(lyricsMapPath());
    if (!f.open(QIODevice::ReadOnly)) {
        m_lyricsMapLoaded = true;
        return;
    }
    const QByteArray bytes = f.readAll();
    f.close();

    QJsonParseError err{};
    const QJsonDocument doc = QJsonDocument::fromJson(bytes, &err);
    if (err.error != QJsonParseError::NoError) {
        qCWarning(lcLyrics) << "lyrics_map.json parse error:" << err.errorString();
        m_lyricsMapLoaded = true;
        return;
    }
    m_lyricsMap = doc.object();
    m_lyricsMapLoaded = true;
}

void Lyrics::persistTrackPrefs() {
    if (!m_lyricsMapLoaded || rawTrackKey().isEmpty()) {
        return;
    }
    const QString key = rawTrackKey();
    QJsonObject entry = m_lyricsMap.value(key).toObject();
    entry.insert(u"offset"_s, m_offset);
    if (m_hasCandidateOverride && m_selected.isValid()) {
        entry.insert(u"backend"_s, backendKey(m_selected.backend()));
        entry.insert(u"id"_s, m_selected.id());
        entry.insert(u"duration"_s, m_selected.duration());
    } else {
        entry.remove(u"backend"_s);
        entry.remove(u"id"_s);
        entry.remove(u"duration"_s);
    }
    const bool hasOverrides = (m_hasCandidateOverride && m_selected.isValid()) || entry.contains(u"appliedArtist"_s);
    if (entry.isEmpty() || (!hasOverrides && entry.size() == 1 && qFuzzyIsNull(entry.value(u"offset"_s).toDouble()))) {
        m_lyricsMap.remove(key);
    } else {
        // MRU bookkeeping: "lastUsed" orders entries by recency (missing == 0 == oldest for
        // pre-existing entries). QJsonObject keys are sorted, not insertion-ordered, so recency
        // must be explicit to bound growth by most-recently-used.
        entry.insert(u"lastUsed"_s, static_cast<double>(QDateTime::currentMSecsSinceEpoch()));
        m_lyricsMap.remove(key);
        m_lyricsMap.insert(key, entry);
        pruneLyricsMap(m_lyricsMap, key);
    }

    QDir().mkpath(stateDir());

    QSaveFile out(lyricsMapPath());
    if (!out.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qCWarning(lcLyrics) << "cannot open" << lyricsMapPath() << "for write:" << out.errorString();
        return;
    }
    const QByteArray bytes = QJsonDocument(m_lyricsMap).toJson(QJsonDocument::Compact);
    if (out.write(bytes) != bytes.size()) {
        qCWarning(lcLyrics) << "short write to" << lyricsMapPath();
        out.cancelWriting();
        return;
    }
    if (!out.commit()) {
        qCWarning(lcLyrics) << "commit failed for" << lyricsMapPath() << ":" << out.errorString();
    }
}

QString Lyrics::lyricsDir() {
    QString dir = config::ConfigSingleton::instance()->paths()->lyricsDir();
    if (dir.isEmpty()) {
        return {};
    }
    if (dir == u"~"_s) {
        dir = QDir::homePath();
    } else if (dir.startsWith(u"~/"_s)) {
        dir.replace(0, 1, QDir::homePath());
    }
    while (dir.endsWith(u'/') && dir.size() > 1) {
        dir.chop(1);
    }
    return dir;
}

QString Lyrics::lyricsMapPath() {
    return stateDir() + u"/lyrics_map.json"_s;
}

QString Lyrics::trackKey() const {
    if (m_artist.isEmpty() && m_title.isEmpty()) {
        return {};
    }
    return u"%1 - %2"_s.arg(joinArtists(m_artist), m_title);
}

QString Lyrics::rawTrackKey() const {
    if (m_rawArtist.isEmpty() && m_rawTitle.isEmpty()) {
        return trackKey();
    }
    return u"%1 - %2"_s.arg(joinArtists(m_rawArtist), m_rawTitle);
}

void Lyrics::resolveMetadataAlias(QString& artist, QString& title) {
    if (!m_lyricsMapLoaded) {
        loadLyricsMap();
    }
    const QString rawKey = rawTrackKey();
    if (!rawKey.isEmpty() && m_lyricsMap.contains(rawKey)) {
        const QJsonObject entry = m_lyricsMap.value(rawKey).toObject();
        if (entry.contains(u"appliedArtist"_s) && entry.contains(u"appliedTitle"_s)) {
            artist = entry.value(u"appliedArtist"_s).toString();
            title = entry.value(u"appliedTitle"_s).toString();
        }
    }
}

void Lyrics::applySuggestedMetadata() {
    if (!m_hasMetadataSuggestion || m_suggestedArtist.isEmpty() || m_suggestedTitle.isEmpty()) {
        return;
    }

    const QString rawKey = rawTrackKey();
    const QString newArtist = m_suggestedArtist;
    const QString newTitle = m_suggestedTitle;

    if (!rawKey.isEmpty()) {
        if (!m_lyricsMapLoaded) {
            loadLyricsMap();
        }
        QJsonObject entry = m_lyricsMap.value(rawKey).toObject();
        entry.insert(u"appliedArtist"_s, newArtist);
        entry.insert(u"appliedTitle"_s, newTitle);
        m_lyricsMap.insert(rawKey, entry);
        persistTrackPrefs();
    }

    if (m_saveDebounce && m_saveDebounce->isActive()) {
        m_saveDebounce->stop();
        persistTrackPrefs();
    }

    cancelInFlight();

    m_artist = newArtist;
    m_title = newTitle;
    emit trackChanged();

    m_selected = LyricCandidate();
    emit selectedCandidateChanged();
    m_autoCandidate = LyricCandidate();
    emit autoCandidateChanged();
    m_hasCandidateOverride = false;
    emit hasCandidateOverrideChanged();
    m_offset = 0.0;
    emit offsetChanged();
    clearLines();
    clearCandidates();

    updateMetadataSuggestion();

    scheduleLoad();
}

QString Lyrics::backendKey(LyricsBackend value) {
    switch (value) {
    case LyricsBackend::Local:
        return u"Local"_s;
    case LyricsBackend::LRCLIB:
        return u"LRCLIB"_s;
    case LyricsBackend::NetEase:
        return u"NetEase"_s;
    case LyricsBackend::Auto:
    default:
        return u"Auto"_s;
    }
}

LyricsBackend Lyrics::backendFromKey(const QString& key) {
    if (key.compare(u"Local"_s, Qt::CaseInsensitive) == 0) {
        return LyricsBackend::Local;
    }
    if (key.compare(u"LRCLIB"_s, Qt::CaseInsensitive) == 0) {
        return LyricsBackend::LRCLIB;
    }
    if (key.compare(u"NetEase"_s, Qt::CaseInsensitive) == 0) {
        return LyricsBackend::NetEase;
    }
    return LyricsBackend::Auto;
}

const QString& Lyrics::stateDir() {
    static const QString k_dir = [] {
        QString state = qEnvironmentVariable("XDG_STATE_HOME");
        if (state.isEmpty()) {
            state = QDir::homePath() + u"/.local/state"_s;
        }
        return state + u"/caelestia/lyrics"_s;
    }();
    return k_dir;
}

const QString& Lyrics::cacheDir() {
    static const QString k_dir = [] {
        QString cache = qEnvironmentVariable("XDG_CACHE_HOME");
        if (cache.isEmpty()) {
            cache = QDir::homePath() + u"/.cache"_s;
        }
        return cache + u"/caelestia/lyrics"_s;
    }();
    return k_dir;
}

QString Lyrics::cachePathFor(LyricsBackend backend, const QString& id) {
    if (id.isEmpty() || backend == LyricsBackend::Auto || backend == LyricsBackend::Local) {
        return {};
    }
    return u"%1/%2/%3.lrc"_s.arg(cacheDir(), backendKey(backend), sanitizeFilenamePart(id));
}

QString Lyrics::readCachedLrc(LyricsBackend backend, const QString& id) {
    const QString path = cachePathFor(backend, id);
    if (path.isEmpty()) {
        return {};
    }
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        return {};
    }
    return QString::fromUtf8(f.readAll());
}

void Lyrics::writeCachedLrc(LyricsBackend backend, const QString& id, const QString& text) {
    if (text.isEmpty()) {
        return;
    }
    const QString path = cachePathFor(backend, id);
    if (path.isEmpty()) {
        return;
    }
    QDir().mkpath(QFileInfo(path).absolutePath());

    QSaveFile out(path);
    if (!out.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qCWarning(lcLyrics) << "cannot open" << path << "for write:" << out.errorString();
        return;
    }
    const QByteArray bytes = text.toUtf8();
    if (out.write(bytes) != bytes.size()) {
        qCWarning(lcLyrics) << "short write to" << path;
        out.cancelWriting();
        return;
    }
    if (!out.commit()) {
        qCWarning(lcLyrics) << "commit failed for" << path << ":" << out.errorString();
    }
}

QString Lyrics::tryReadLocalLrc(const QString& dir, const QString& artist, const QString& title) {
    if (artist.isEmpty() && title.isEmpty()) {
        return {};
    }
    const QString flat = u"%1/%2 - %3.lrc"_s.arg(dir, sanitizeFilenamePart(artist), sanitizeFilenamePart(title));
    return QFile::exists(flat) ? flat : QString();
}

QString Lyrics::findLocalLrcRecursive(const QString& dir, const QString& artist, const QString& title) {
    if (dir.isEmpty()) {
        return {};
    }
    if (artist.isEmpty() && title.isEmpty()) {
        return {};
    }

    // Cached listing: a full recursive scan per track miss is O(tree) on every miss. Cache the
    // *.lrc listing and invalidate only when the top-level directory mtime changes. Note the
    // trade-off: creations inside subdirectories do not bump the top-level mtime on Linux, so
    // such files appear on the next top-level change or restart; the flat fast-path in
    // tryReadLocalLrc() still hits the filesystem directly, so exact "<artist> - <title>.lrc"
    // matches are always fresh.
    const std::vector<LrcIndexEntry>& entries = cachedLrcEntries(dir);
    for (const LrcIndexEntry& entry : entries) {
        if ((artist.isEmpty() || containsCi(entry.fileName, artist)) &&
            (title.isEmpty() || containsCi(entry.fileName, title))) {
            return entry.path;
        }
    }
    return {};
}

QVector<LyricLine> Lyrics::parseLrc(const QString& text) {
    QVector<LyricLine> result;
    if (text.isEmpty()) {
        return result;
    }

    static const QRegularExpression k_timeRegex(u"\\[(\\d+):(\\d+(?:\\.\\d+)?)\\]"_s);
    static const QStringList k_creditKeywords = {
        u"作词"_s,
        u"作曲"_s,
        u"编曲"_s,
        u"制作"_s,
        u"收录"_s,
        u"演奏"_s,
        u"词："_s,
        u"曲："_s,
        u"Lyricist"_s,
        u"Composer"_s,
        u"Arranger"_s,
        u"Producer"_s,
        u"Mixing"_s,
        u"Mastering"_s,
    };

    const QStringList lines = text.split(u'\n');
    for (const QString& line : lines) {
        QList<QRegularExpressionMatch> matches;
        auto it = k_timeRegex.globalMatch(line);
        while (it.hasNext()) {
            matches.append(it.next());
        }
        if (matches.isEmpty()) {
            continue;
        }

        QString lyric = line;
        lyric.replace(k_timeRegex, QString());
        lyric = lyric.trimmed();

        const qreal firstTime = matches.first().captured(1).toInt() * 60.0 + matches.first().captured(2).toDouble();

        if (firstTime < 20.0) {
            bool isCredit = false;
            for (const QString& k : k_creditKeywords) {
                if (lyric.contains(k, Qt::CaseInsensitive)) {
                    isCredit = true;
                    break;
                }
            }
            if (isCredit && (lyric.contains(u':') || lyric.contains(QChar(0xFF1A)) || lyric.size() < 25)) {
                continue;
            }
        }

        for (const auto& m : matches) {
            const qreal t = m.captured(1).toInt() * 60.0 + m.captured(2).toDouble();
            result.append(LyricLine{ .time = t, .text = lyric });
        }
    }

    std::ranges::sort(result, [](const LyricLine& a, const LyricLine& b) {
        return a.time < b.time;
    });

    return result;
}

} // namespace caelestia::services
