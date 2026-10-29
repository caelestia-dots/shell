#include "notifdata.hpp"

#include <qbuffer.h>
#include <qcryptographichash.h>
#include <qdatetime.h>
#include <qfile.h>
#include <qimage.h>
#include <qmetaobject.h>
#include <qqml.h>
#include <qquickimageprovider.h>
#include <quuid.h>

#include "config/rootnodes.hpp"

namespace caelestia::shell::models {

using Qt::StringLiterals::operator""_s;

namespace {

constexpr int k_cacheVersion = 1;
constexpr QSize k_providerCacheSize(64, 64);

template <typename T> bool assign(T& field, const T& value) {
    if (field == value)
        return false;
    field = value;
    return true;
}

utils::FileCache& imageCache() {
    static utils::FileCache s_cache(u"notifs/images"_s, 512ll * 1024 * 1024, {}, k_cacheVersion);
    return s_cache;
}

QString keyForImage(const QImage& image) {
    if (image.isNull())
        return {};

    QCryptographicHash hash(QCryptographicHash::Sha256);
    hash.addData(u"%1x%2|%3|"_s
            .arg(QString::number(image.width()), QString::number(image.height()), QString::number(image.format()))
            .toUtf8());
    hash.addData(QByteArrayView(reinterpret_cast<const char*>(image.constBits()), image.sizeInBytes()));
    return QString::fromLatin1(hash.result().toHex());
}

QByteArray encodeImage(const QImage& image) {
    QByteArray bytes;
    QBuffer buffer(&bytes);
    buffer.open(QIODevice::WriteOnly);
    image.save(&buffer, "PNG");
    return bytes;
}

} // namespace

NotifAction::NotifAction(NotifData* parent, QString identifier, QString text, QObject* backer)
    : m_parent(parent)
    , m_backer(backer)
    , m_identifier(std::move(identifier))
    , m_text(std::move(text)) {}

QString NotifAction::identifier() const {
    return m_identifier;
}

QString NotifAction::text() const {
    return m_text;
}

void NotifAction::invoke() {
    if (m_backer)
        QMetaObject::invokeMethod(m_backer, "invoke");
    else if (m_parent)
        m_parent->dismiss();
}

NotifData::NotifData(QObject* parent)
    : QObject(parent)
    , m_createdAt(QDateTime::currentMSecsSinceEpoch())
    , m_popupTimer(new QTimer(this))
    , m_id(QUuid::createUuid().toString(QUuid::WithoutBraces))
    , m_expireTimeout(config::ConfigSingleton::instance()->notifs()->defaultExpireTimeout()) {
    m_popupTimer->setSingleShot(true);
    QObject::connect(m_popupTimer, &QTimer::timeout, this, &NotifData::popupClosed);
}

NotifData::NotifData(QObject* backer, QObject* parent)
    : NotifData(parent) {
    m_backer = backer;
    m_backer->setProperty("tracked", true);

    QObject::connect(m_backer, &QObject::destroyed, this, [this] {
        m_backer = nullptr;
    });

    syncFromBacker();
    connectBacker();
}

QString NotifData::id() const {
    return m_id;
}

QString NotifData::summary() const {
    return m_summary;
}

QString NotifData::body() const {
    return m_body;
}

QString NotifData::appIcon() const {
    return m_appIcon;
}

QString NotifData::appName() const {
    return m_appName;
}

QString NotifData::image() const {
    return m_image;
}

QVariantMap NotifData::hints() const {
    return m_hints;
}

int NotifData::expireTimeout() const {
    return m_expireTimeout;
}

NotifData::Urgency NotifData::urgency() const {
    return m_urgency;
}

bool NotifData::resident() const {
    return m_resident;
}

bool NotifData::hasActionIcons() const {
    return m_hasActionIcons;
}

QList<NotifAction> NotifData::actions() const {
    return m_actions;
}

void NotifData::dismiss() {
    if (m_closed)
        return;

    if (m_backer)
        QMetaObject::invokeMethod(m_backer, "dismiss");
    else
        onBackerClosed();
}

void NotifData::startPopupTimer() {
    m_popupTimer->setInterval(m_expireTimeout);
    m_popupTimer->start();
}

void NotifData::syncFromBacker() {
    if (!m_backer)
        return;

    bool dirty = false;

    if (assign(m_summary, m_backer->property("summary").toString())) {
        dirty = true;
        emit summaryChanged();
    }
    if (assign(m_body, m_backer->property("body").toString())) {
        dirty = true;
        emit bodyChanged();
    }
    if (assign(m_appIcon, m_backer->property("appIcon").toString())) {
        dirty = true;
        emit appIconChanged();
    }
    if (assign(m_appName, m_backer->property("appName").toString())) {
        dirty = true;
        emit appNameChanged();
    }
    if (assign(m_image, m_backer->property("image").toString())) {
        dirty = true;
        cacheImage();
        emit imageChanged();
    }
    if (assign(m_hints, m_backer->property("hints").toMap()))
        emit hintsChanged();
    if (const auto timeout = static_cast<int>(m_backer->property("expireTimeout").toReal() * 1000);
        timeout > 0 && !qFuzzyCompare(m_expireTimeout + 1.0, timeout + 1.0)) {
        dirty = true;
        m_expireTimeout = timeout;
        emit expireTimeoutChanged();
    }
    if (assign(m_urgency, m_backer->property("urgency").value<Urgency>())) {
        dirty = true;
        emit urgencyChanged();
    }
    if (assign(m_resident, m_backer->property("resident").toBool())) {
        dirty = true;
        emit residentChanged();
    }
    if (assign(m_hasActionIcons, m_backer->property("hasActionIcons").toBool())) {
        dirty = true;
        emit hasActionIconsChanged();
    }
    if (assign(m_actions, readBackerActions())) {
        dirty = true;
        emit actionsChanged();
    }

    if (dirty)
        emit changed();
}

void NotifData::onBackerClosed() {
    m_closed = true;
    emit closed();
}

void NotifData::connectBacker() {
    if (!m_backer)
        return;

    const auto* const backerMeta = m_backer->metaObject();
    const auto* const meta = metaObject();
    const auto sync = meta->method(meta->indexOfSlot("syncFromBacker()"));
    const auto closedSlot = meta->method(meta->indexOfSlot("onBackerClosed()"));

    for (int i = backerMeta->methodOffset(); i < backerMeta->methodCount(); ++i) {
        const auto signal = backerMeta->method(i);
        if (signal.methodType() != QMetaMethod::Signal)
            continue;

        if (signal.name() == "closed")
            QObject::connect(m_backer, signal, this, closedSlot);
        else if (signal.name().endsWith("Changed"))
            QObject::connect(m_backer, signal, this, sync);
    }
}

QList<NotifAction> NotifData::readBackerActions() {
    if (!m_backer)
        return {};

    const auto list = m_backer->property("actions").toList();
    QList<NotifAction> actions;
    actions.reserve(list.size());

    for (const auto& item : list) {
        auto* const action = item.value<QObject*>();
        if (!action)
            continue;

        actions.emplaceBack(
            this, action->property("identifier").toString(), action->property("text").toString(), action);
    }

    return actions;
}

void NotifData::cacheImage() {
    if (m_image.isEmpty() || m_image.startsWith(imageCache().dir()))
        return;

    const QUrl url(m_image);
    if (url.scheme() != u"image") {
        storeImage(utils::Cache::keyForPath(m_image), [path = m_image] {
            return QFile(path).readAll();
        });
        return;
    }

    auto* const engine = qmlEngine(this);
    if (!engine)
        return;

    auto* const base = engine->imageProvider(url.host());
    if (!base)
        return;

    // Keep the ?path= / ?fallback= query, drop only scheme, host and leading slash
    const auto id = url.toString(QUrl::RemoveScheme | QUrl::RemoveAuthority).mid(1);

    QFuture<QImage> image;
    if (base->imageType() == QQmlImageProviderBase::Image) {
        auto* const provider = static_cast<QQuickImageProvider*>(base);
        image = QtFuture::makeReadyValueFuture(provider).then(QtFuture::Launch::Async, [id](QQuickImageProvider* p) {
            return p->requestImage(id, nullptr, k_providerCacheSize);
        });
    } else if (base->imageType() == QQmlImageProviderBase::Pixmap) {
        auto* const provider = static_cast<QQuickImageProvider*>(base);
        image = QtFuture::makeReadyValueFuture(provider->requestPixmap(id, nullptr, k_providerCacheSize).toImage());
    } else {
        return;
    }

    image
        .then(QtFuture::Launch::Async,
            [](const QImage& img) {
                return std::pair{ keyForImage(img), img };
            })
        .then(this, [this](const std::pair<QString, QImage>& result) {
            storeImage(result.first, [img = result.second] {
                return encodeImage(img);
            });
        });
}

void NotifData::storeImage(const QString& key, utils::Cache::Producer producer) {
    if (key.isEmpty())
        return;

    imageCache().lookup(key).then(this, [this, key, producer = std::move(producer)](const QUrl& cached) {
        if (!cached.isEmpty()) {
            m_image = cached.toLocalFile();
            emit changed();
            return;
        }

        imageCache().store(key, producer).then(this, [this, key](bool ok) {
            if (!ok)
                return;

            m_image = imageCache().pathFor(key);
            emit changed();
        });
    });
}

} // namespace caelestia::shell::models
