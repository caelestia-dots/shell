#include "networkwalker.hpp"

#include <qloggingcategory.h>
#include <qtimer.h>

#include <utility>

namespace caelestia::services {

namespace {

Q_LOGGING_CATEGORY(logNmWalker, "caelestia.services.nmwalker", QtWarningMsg);

constexpr const char* kService = "org.freedesktop.NetworkManager";
constexpr const char* kPropsIface = "org.freedesktop.DBus.Properties";

} // namespace

NmWalker::NmWalker(QString rootPath, QObject* parent)
    : QObject(parent)
    , m_rootPath(std::move(rootPath)) {
    auto bus = systemBus();
    if (!bus) {
        return;
    }

    // NetworkManager may not be up yet, or may restart under us.
    bus->connect(
        QStringLiteral("org.freedesktop.DBus"),
        QStringLiteral("/org/freedesktop/DBus"),
        QStringLiteral("org.freedesktop.DBus"),
        QStringLiteral("NameOwnerChanged"),
        QStringLiteral("sss"),
        this,
        SLOT(handleNameOwnerChanged(QString, QString, QString)));

    watchObject(m_rootPath);
    scheduleRefresh();
}

bool NmWalker::ready() const {
    return m_ready;
}

bool NmWalker::walking() const {
    return m_refreshing;
}

QSet<QString>& NmWalker::seen() {
    return m_seen;
}

void NmWalker::setListChanged() {
    m_listChanged = true;
}

std::optional<QDBusConnection> NmWalker::systemBus() {
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        qCWarning(logNmWalker) << "System bus unavailable";
        return std::nullopt;
    }
    return bus;
}

void NmWalker::watchObject(const QString& path) {
    if (path.isEmpty() || path == QStringLiteral("/") || m_watched.contains(path)) {
        return;
    }

    auto bus = systemBus();
    if (!bus) {
        return;
    }

    if (bus->connect(
            QString::fromUtf8(kService),
            path,
            QString::fromUtf8(kPropsIface),
            QStringLiteral("PropertiesChanged"),
            this,
            SLOT(handlePropertiesChanged(QString, QVariantMap, QStringList)))) {
        m_watched.insert(path);
    }
}

void NmWalker::handlePropertiesChanged(
    const QString& iface, const QVariantMap& properties, const QStringList& invalidated) {
    Q_UNUSED(properties);
    Q_UNUSED(invalidated);

    if (triggersRefresh(iface)) {
        scheduleRefresh();
    }
}

void NmWalker::handleNameOwnerChanged(const QString& name, const QString& oldOwner, const QString& newOwner) {
    Q_UNUSED(oldOwner);

    if (name != QString::fromUtf8(kService)) {
        return;
    }

    m_watched.clear();

    if (newOwner.isEmpty()) {
        clearItems();
        m_ready = false;
        emit itemsChanged();
        emit changed();
        return;
    }

    // Fresh objects on the new owner, so the old subscriptions are worthless.
    watchObject(m_rootPath);
    scheduleRefresh();
}

void NmWalker::scheduleRefresh() {
    if (m_refreshing) {
        m_refreshQueued = true;
        return;
    }

    m_refreshing = true;
    QTimer::singleShot(0, this, [this]() {
        refresh();
    });
}

void NmWalker::refresh() {
    m_seen.clear();
    m_listChanged = false;
    m_pending = 0;

    readRoot();
}

void NmWalker::step(int delta) {
    m_pending += delta;
    if (m_pending > 0) {
        return;
    }

    finish();
}

void NmWalker::abandonWalk() {
    m_pending = 0;
    finish();
}

void NmWalker::finish() {
    pruneUnseen();

    const bool wasReady = m_ready;
    m_ready = true;

    if (m_listChanged) {
        emit itemsChanged();
    }
    if (!wasReady || m_listChanged) {
        emit changed();
    }

    m_refreshing = false;
    if (m_refreshQueued) {
        m_refreshQueued = false;
        scheduleRefresh();
    }
}

} // namespace caelestia::services
