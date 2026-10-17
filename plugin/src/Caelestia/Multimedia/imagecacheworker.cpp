#include "imagecacheworker.hpp"

#include <qdatetime.h>
#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qloggingcategory.h>
#include <qsavefile.h>
#include <qset.h>
#include <qsqlerror.h>
#include <qsqlquery.h>
#include <quuid.h>

#include <utility>

#include "ktxencoder.hpp"

namespace {

Q_LOGGING_CATEGORY(lcCache, "caelestia.multimedia.image.cache", QtInfoMsg)

} // namespace

namespace caelestia::multimedia {

using Qt::StringLiterals::operator""_s;
using Qt::StringLiterals::operator""_L1;

namespace {

constexpr qint64 k_maxBytes = 512ll * 1024 * 1024;
constexpr auto k_suffix = ".ktx"_L1;

qint64 now() {
    return QDateTime::currentSecsSinceEpoch();
}

} // namespace

ImageCacheWorker::ImageCacheWorker(QString dir, QObject* parent)
    : QObject(parent)
    , m_dir(std::move(dir))
    , m_connection(QUuid::createUuid().toString()) {}

ImageCacheWorker::~ImageCacheWorker() {
    m_db.close();
    m_db = QSqlDatabase();
    QSqlDatabase::removeDatabase(m_connection);
}

void ImageCacheWorker::open() {
    if (!QDir().mkpath(m_dir)) {
        qCWarning(lcCache).noquote() << "Failed to create cache dir" << m_dir;
        return;
    }

    m_db = QSqlDatabase::addDatabase(u"QSQLITE"_s, m_connection);
    m_db.setDatabaseName(m_dir + u"/index.db"_s);
    if (!m_db.open()) {
        qCWarning(lcCache).noquote() << "Failed to open cache index:" << m_db.lastError().text();
        return;
    }

    QSqlQuery query(m_db);
    query.exec(u"CREATE TABLE IF NOT EXISTS entries (key TEXT PRIMARY KEY, bytes INTEGER NOT NULL, "
               "last_used INTEGER NOT NULL)"_s);

    reconcile();
    evict();
}

void ImageCacheWorker::touch(const QString& key) {
    QSqlQuery query(m_db);
    query.prepare(u"UPDATE entries SET last_used = :now WHERE key = :key"_s);
    query.bindValue(u":now"_s, now());
    query.bindValue(u":key"_s, key);
    query.exec();
}

void ImageCacheWorker::storeFile(
    const QString& key, const QString& path, const QSize& bucket, Qt::AspectRatioMode mode) {
    if (QFile::exists(pathFor(key)))
        return;

    const auto image = ktx::readFitted(path, bucket, mode);
    if (image.isNull()) {
        qCWarning(lcCache).noquote() << "Failed to decode" << path;
        return;
    }
    store(key, image);
}

void ImageCacheWorker::storeImage(
    const QString& key, const QImage& image, const QSize& bucket, Qt::AspectRatioMode mode) {
    if (QFile::exists(pathFor(key)) || image.isNull())
        return;

    store(key, ktx::fitted(image, bucket, mode));
}

void ImageCacheWorker::store(const QString& key, const QImage& image) {
    const auto data = ktx::encodeBc3(image);

    QSaveFile file(pathFor(key));
    if (!file.open(QIODevice::WriteOnly) || file.write(data) != data.size() || !file.commit()) {
        qCWarning(lcCache).noquote() << "Failed to write" << file.fileName() << file.errorString();
        return;
    }

    QSqlQuery query(m_db);
    query.prepare(u"INSERT OR REPLACE INTO entries (key, bytes, last_used) VALUES (:key, :bytes, :now)"_s);
    query.bindValue(u":key"_s, key);
    query.bindValue(u":bytes"_s, data.size());
    query.bindValue(u":now"_s, now());
    query.exec();

    qCDebug(lcCache).noquote() << "Stored" << key << image.size() << data.size() << "bytes";
    evict();
}

void ImageCacheWorker::reconcile() {
    QSet<QString> indexed;
    QSqlQuery query(m_db);
    query.exec(u"SELECT key FROM entries"_s);
    while (query.next())
        indexed.insert(query.value(0).toString());

    QSet<QString> onDisk;
    const auto files = QDir(m_dir).entryInfoList({ u"*"_s + k_suffix }, QDir::Files);
    for (const auto& info : files) {
        const auto key = info.completeBaseName();
        onDisk.insert(key);
        if (indexed.contains(key))
            continue;

        query.prepare(u"INSERT INTO entries (key, bytes, last_used) VALUES (:key, :bytes, :now)"_s);
        query.bindValue(u":key"_s, key);
        query.bindValue(u":bytes"_s, info.size());
        query.bindValue(u":now"_s, now());
        query.exec();
    }

    for (const QString& key : indexed)
        if (!onDisk.contains(key))
            remove(key);
}

void ImageCacheWorker::evict() {
    QSqlQuery query(m_db);
    query.exec(u"SELECT COALESCE(SUM(bytes), 0) FROM entries"_s);
    qint64 total = query.next() ? query.value(0).toLongLong() : 0;
    if (total <= k_maxBytes)
        return;

    QStringList stale;
    query.exec(u"SELECT key, bytes FROM entries ORDER BY last_used ASC"_s);
    while (total > k_maxBytes && query.next()) {
        stale << query.value(0).toString();
        total -= query.value(1).toLongLong();
    }
    query.finish();

    for (const auto& key : std::as_const(stale)) {
        QFile::remove(pathFor(key));
        remove(key);
        qCDebug(lcCache).noquote() << "Evicted" << key;
    }
}

void ImageCacheWorker::remove(const QString& key) {
    QSqlQuery query(m_db);
    query.prepare(u"DELETE FROM entries WHERE key = :key"_s);
    query.bindValue(u":key"_s, key);
    query.exec();
}

QString ImageCacheWorker::pathFor(const QString& key) const {
    return m_dir + u'/' + key + k_suffix;
}

} // namespace caelestia::multimedia
