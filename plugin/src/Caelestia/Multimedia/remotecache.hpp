#pragma once

#include <qdatetime.h>
#include <qfuture.h>
#include <qnetworkaccessmanager.h>
#include <qnetworkreply.h>
#include <qobject.h>
#include <qpromise.h>
#include <qset.h>
#include <qstring.h>
#include <qurl.h>

#include <caelestia/utils/cache.hpp>

#include <map>
#include <vector>

namespace caelestia::shell::multimedia {

class RemoteCache : public QObject {
    Q_OBJECT

public:
    static RemoteCache* instance();
    [[nodiscard]] static bool isRemote(const QUrl& url);

    // Resolves to a local file URL, or an empty URL on failure. A stale entry resolves immediately
    // and is revalidated in the background; a changed resource is announced through updated().
    [[nodiscard]] QFuture<QUrl> fetch(const QUrl& url);

signals:
    void updated(const QUrl& url, const QUrl& file);

private:
    struct Meta {
        QString bodyKey;
        QString etag;
        QDateTime lastModified;
        QDateTime fetchedAt;
        qint64 maxAge = 0;

        [[nodiscard]] bool isFresh() const;
        [[nodiscard]] QByteArray serialise() const;
        [[nodiscard]] static Meta deserialise(const QByteArray& data);
    };

    explicit RemoteCache(QObject* parent = nullptr);

    [[nodiscard]] QFuture<QUrl> resolve(const QUrl& url, const Meta& meta);
    void revalidate(const QUrl& url, const Meta& meta);
    [[nodiscard]] QFuture<QUrl> request(const QUrl& url, const Meta& meta);
    [[nodiscard]] QFuture<QUrl> onReply(const QUrl& url, Meta meta, QNetworkReply* reply);
    [[nodiscard]] QUrl fileFor(const Meta& meta) const;

    utils::FileCache m_files;
    utils::BlobCache m_meta;
    QNetworkAccessManager m_manager;
    std::map<QUrl, std::vector<QPromise<QUrl>>> m_pending;
    QSet<QUrl> m_revalidating;
};

} // namespace caelestia::shell::multimedia
