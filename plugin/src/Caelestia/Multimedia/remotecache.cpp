#include "remotecache.hpp"

#include <qcryptographichash.h>
#include <qdatastream.h>
#include <qloggingcategory.h>
#include <qnetworkrequest.h>
#include <qtconcurrentrun.h>

#include <algorithm>
#include <utility>

namespace {

Q_LOGGING_CATEGORY(lcRemoteCache, "caelestia.multimedia.remotecache", QtWarningMsg)

using Qt::StringLiterals::operator""_s;
using Qt::StringLiterals::operator""_ba;

constexpr qint64 k_maxBytes = 256ll * 1024 * 1024;
constexpr qint64 k_maxMetaBytes = 1024ll * 1024;
constexpr int k_version = 1;
constexpr qint64 k_defaultMaxAge = 60ll * 60;
constexpr int k_timeoutMs = 30 * 1000;
constexpr int k_notModified = 304;

QDateTime headerDate(const QNetworkReply* reply, const QByteArray& name) {
    return QDateTime::fromString(QString::fromLatin1(reply->rawHeader(name)), Qt::RFC2822Date);
}

qint64 maxAgeFor(const QNetworkReply* reply, const QDateTime& fetchedAt) {
    const auto directives = reply->rawHeader("Cache-Control"_ba).split(',');
    for (const auto& directive : directives) {
        const auto trimmed = directive.trimmed();
        if (!trimmed.startsWith("max-age="_ba))
            continue;

        bool ok = false;
        const auto value = trimmed.mid(8).toLongLong(&ok);
        if (ok)
            return value;
    }

    const auto expires = headerDate(reply, "Expires"_ba);
    return expires.isValid() ? std::max<qint64>(0, fetchedAt.secsTo(expires)) : k_defaultMaxAge;
}

QString metaKeyFor(const QUrl& url) {
    return caelestia::utils::Cache::keyFor(url.toString());
}

QString bodyKeyFor(const QUrl& url, const QByteArray& body) {
    const auto digest = QCryptographicHash::hash(body, QCryptographicHash::Sha1).toHex();
    return caelestia::utils::Cache::keyFor(url.toString() + u'|' + QString::fromLatin1(digest));
}

} // namespace

namespace caelestia::shell::multimedia {

bool RemoteCache::Meta::isFresh() const {
    return fetchedAt.isValid() && QDateTime::currentDateTimeUtc() < fetchedAt.addSecs(maxAge);
}

QByteArray RemoteCache::Meta::serialise() const {
    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.setVersion(QDataStream::Qt_6_0);
    stream << bodyKey << etag << lastModified << fetchedAt << maxAge;
    return data;
}

RemoteCache::Meta RemoteCache::Meta::deserialise(const QByteArray& data) {
    if (data.isEmpty())
        return {};

    QDataStream stream(data);
    stream.setVersion(QDataStream::Qt_6_0);
    Meta meta;
    stream >> meta.bodyKey >> meta.etag >> meta.lastModified >> meta.fetchedAt >> meta.maxAge;
    return stream.status() == QDataStream::Ok && stream.atEnd() ? meta : Meta{};
}

RemoteCache* RemoteCache::instance() {
    static RemoteCache s_instance;
    return &s_instance;
}

bool RemoteCache::isRemote(const QUrl& url) {
    return url.scheme() == u"http"_s || url.scheme() == u"https"_s;
}

RemoteCache::RemoteCache(QObject* parent)
    : QObject(parent)
    , m_files(u"multimedia/remote"_s, k_maxBytes, u".asset"_s, k_version)
    , m_meta(u"multimedia/remote/meta"_s, k_maxMetaBytes, k_version) {}

QFuture<QUrl> RemoteCache::fetch(const QUrl& url) {
    auto& waiters = m_pending[url];
    QPromise<QUrl> promise;
    promise.start();
    auto future = promise.future();
    waiters.push_back(std::move(promise));

    if (waiters.size() > 1)
        return future;

    m_meta.lookup(metaKeyFor(url))
        .then(this,
            [this, url](const QByteArray& data) {
                return resolve(url, Meta::deserialise(data));
            })
        .unwrap()
        .then(this, [this, url](const QUrl& file) {
            const auto settled = m_pending.extract(url);
            if (settled.empty())
                return;

            for (auto& p : settled.mapped()) {
                p.addResult(file);
                p.finish();
            }
        });

    return future;
}

QFuture<QUrl> RemoteCache::resolve(const QUrl& url, const Meta& meta) {
    if (meta.bodyKey.isEmpty())
        return request(url, {});

    return m_files.lookup(meta.bodyKey)
        .then(this,
            [this, url, meta](const QUrl& file) {
                if (file.isEmpty())
                    return request(url, {});

                if (!meta.isFresh())
                    revalidate(url, meta);
                return QtFuture::makeReadyValueFuture(file);
            })
        .unwrap();
}

void RemoteCache::revalidate(const QUrl& url, const Meta& meta) {
    if (m_revalidating.contains(url))
        return;

    m_revalidating.insert(url);
    request(url, meta).then(this, [this, url, previous = fileFor(meta)](const QUrl& file) {
        m_revalidating.remove(url);
        if (!file.isEmpty() && file != previous)
            emit updated(url, file);
    });
}

QFuture<QUrl> RemoteCache::request(const QUrl& url, const Meta& meta) {
    QNetworkRequest req(url);
    req.setTransferTimeout(k_timeoutMs);
    if (!meta.etag.isEmpty())
        req.setHeader(QNetworkRequest::IfNoneMatchHeader, QStringList{ meta.etag });
    if (meta.lastModified.isValid())
        req.setHeader(QNetworkRequest::IfModifiedSinceHeader, meta.lastModified);

    auto* const reply = m_manager.get(req);
    return QtFuture::connect(reply, &QNetworkReply::finished)
        .then(this,
            [this, url, meta, reply] {
                reply->deleteLater();
                return onReply(url, meta, reply);
            })
        .unwrap();
}

QFuture<QUrl> RemoteCache::onReply(const QUrl& url, Meta meta, QNetworkReply* reply) {
    const auto existing = fileFor(meta);
    if (reply->error() != QNetworkReply::NoError) {
        qCWarning(lcRemoteCache) << "Failed to fetch" << url << reply->errorString();
        return QtFuture::makeReadyValueFuture(existing);
    }

    const auto date = headerDate(reply, "Date"_ba);
    meta.fetchedAt = date.isValid() ? date : QDateTime::currentDateTimeUtc();
    meta.maxAge = maxAgeFor(reply, meta.fetchedAt);

    if (reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt() == k_notModified) {
        m_meta.store(metaKeyFor(url), meta.serialise());
        return QtFuture::makeReadyValueFuture(existing);
    }

    meta.etag = reply->header(QNetworkRequest::ETagHeader).toString();
    meta.lastModified = reply->header(QNetworkRequest::LastModifiedHeader).toDateTime();

    const auto body = reply->readAll();
    return QtConcurrent::run(bodyKeyFor, url, body)
        .then(this,
            [this, url, meta, body](const QString& key) mutable {
                const auto previous = std::exchange(meta.bodyKey, key);
                m_meta.store(metaKeyFor(url), meta.serialise());
                if (key == previous)
                    return QtFuture::makeReadyValueFuture(fileFor(meta));

                m_files.store(key, body);
                return m_files.lookup(key);
            })
        .unwrap();
}

QUrl RemoteCache::fileFor(const Meta& meta) const {
    return meta.bodyKey.isEmpty() ? QUrl() : QUrl::fromLocalFile(m_files.pathFor(meta.bodyKey));
}

} // namespace caelestia::shell::multimedia
