#include "networkroute.hpp"

#include <qdbusargument.h>
#include <qdbusextratypes.h>
#include <qdbusmessage.h>
#include <qdbuspendingcall.h>
#include <qdbuspendingreply.h>
#include <qdbusreply.h>
#include <qloggingcategory.h>
#include <qtimer.h>

namespace caelestia::services {

namespace {

Q_LOGGING_CATEGORY(logNetworkRoute, "caelestia.services.networkroute", QtWarningMsg);

constexpr const char* kService = "org.freedesktop.NetworkManager";
constexpr const char* kManagerPath = "/org/freedesktop/NetworkManager";
constexpr const char* kManagerIface = "org.freedesktop.NetworkManager";
constexpr const char* kActiveIface = "org.freedesktop.NetworkManager.Connection.Active";
constexpr const char* kDeviceIface = "org.freedesktop.NetworkManager.Device";
constexpr const char* kPropsIface = "org.freedesktop.DBus.Properties";

// From NMDeviceType; only the two we classify are named.
constexpr uint kDeviceTypeEthernet = 1;
constexpr uint kDeviceTypeWifi = 2;

} // namespace

bool NetworkRoute::Snapshot::operator==(const Snapshot& o) const noexcept {
    return primary == o.primary && ipv4 == o.ipv4 && ipv6 == o.ipv6 && primaryInterface == o.primaryInterface;
}

NetworkRoute::NetworkRoute(QObject* parent)
    : QObject(parent) {
    auto bus = systemBus();
    if (!bus) {
        return;
    }

    // NetworkManager may not be up yet, or may restart under us.
    bus->connect(QStringLiteral("org.freedesktop.DBus"), QStringLiteral("/org/freedesktop/DBus"),
        QStringLiteral("org.freedesktop.DBus"), QStringLiteral("NameOwnerChanged"), QStringLiteral("sss"), this,
        SLOT(handleNameOwnerChanged(QString, QString, QString)));

    watchObject(QString::fromUtf8(kManagerPath));
    scheduleRefresh();
}

bool NetworkRoute::ready() const {
    return m_ready;
}

Transport NetworkRoute::primaryTransport() const {
    return m_current.primary;
}

Transport NetworkRoute::ipv4Transport() const {
    return m_current.ipv4;
}

Transport NetworkRoute::ipv6Transport() const {
    return m_current.ipv6;
}

bool NetworkRoute::mixed() const {
    return m_current.ipv4 != config::NetworkTransport::None && m_current.ipv6 != config::NetworkTransport::None &&
           m_current.ipv4 != m_current.ipv6;
}

QString NetworkRoute::primaryInterface() const {
    return m_current.primaryInterface;
}

std::optional<QDBusConnection> NetworkRoute::systemBus() {
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        qCWarning(logNetworkRoute) << "System bus unavailable";
        return std::nullopt;
    }
    return bus;
}

Transport NetworkRoute::transportForDeviceType(uint deviceType) {
    switch (deviceType) {
    case kDeviceTypeEthernet:
        return config::NetworkTransport::Ethernet;
    case kDeviceTypeWifi:
        return config::NetworkTransport::Wifi;
    default:
        return config::NetworkTransport::Other;
    }
}

// Subscribes to property changes on an object once. NetworkManager emits these
// for the manager, every active connection and every device, which is what
// tells us a walk is out of date.
void NetworkRoute::watchObject(const QString& path) {
    if (path.isEmpty() || path == QStringLiteral("/") || m_watched.contains(path)) {
        return;
    }

    auto bus = systemBus();
    if (!bus) {
        return;
    }

    if (bus->connect(QString::fromUtf8(kService), path, QString::fromUtf8(kPropsIface),
            QStringLiteral("PropertiesChanged"), this,
            SLOT(handlePropertiesChanged(QString, QVariantMap, QStringList)))) {
        m_watched.insert(path);
    }
}

void NetworkRoute::handlePropertiesChanged(
    const QString& iface, const QVariantMap& properties, const QStringList& invalidated) {
    Q_UNUSED(properties);
    Q_UNUSED(invalidated);

    if (iface == QString::fromUtf8(kManagerIface) || iface == QString::fromUtf8(kActiveIface) ||
        iface == QString::fromUtf8(kDeviceIface)) {
        scheduleRefresh();
    }
}

void NetworkRoute::handleNameOwnerChanged(const QString& name, const QString& oldOwner, const QString& newOwner) {
    Q_UNUSED(oldOwner);

    if (name != QString::fromUtf8(kService)) {
        return;
    }

    if (newOwner.isEmpty()) {
        // NetworkManager went away; report nothing rather than stale state.
        m_watched.clear();
        m_ready = false;
        m_current = Snapshot();
        emit changed();
        return;
    }

    // Fresh objects on the new owner, so the old subscriptions are worthless.
    m_watched.clear();
    watchObject(QString::fromUtf8(kManagerPath));
    scheduleRefresh();
}

// Signals arrive in bursts - a connection going up touches the manager, the
// active connection and its device in quick succession. Coalescing them means
// one walk per burst instead of several racing ones.
void NetworkRoute::scheduleRefresh() {
    if (m_refreshing) {
        m_refreshQueued = true;
        return;
    }

    m_refreshing = true;
    QTimer::singleShot(0, this, [this]() {
        refresh();
    });
}

void NetworkRoute::refresh() {
    m_building = Snapshot();
    m_primaryConnection.clear();
    m_connIsDefault4.clear();
    m_connIsDefault6.clear();
    m_connTransport.clear();
    m_connInterface.clear();
    m_pending = 0;

    readManager();
}

// Each async read holds a reference; the snapshot is applied when the last one
// lands, so a partial walk is never published.
void NetworkRoute::step(int delta) {
    m_pending += delta;
    if (m_pending > 0) {
        return;
    }

    Snapshot snapshot;
    snapshot.primaryInterface = m_connInterface.value(m_primaryConnection);
    snapshot.primary = m_connTransport.value(m_primaryConnection, config::NetworkTransport::None);

    for (auto it = m_connIsDefault4.cbegin(); it != m_connIsDefault4.cend(); ++it) {
        if (it.value()) {
            snapshot.ipv4 = m_connTransport.value(it.key(), config::NetworkTransport::None);
            break;
        }
    }
    for (auto it = m_connIsDefault6.cbegin(); it != m_connIsDefault6.cend(); ++it) {
        if (it.value()) {
            snapshot.ipv6 = m_connTransport.value(it.key(), config::NetworkTransport::None);
            break;
        }
    }

    finishRefresh(snapshot);
}

void NetworkRoute::finishRefresh(const Snapshot& snapshot) {
    const bool wasReady = m_ready;
    m_ready = true;

    if (!wasReady || !(snapshot == m_current)) {
        m_current = snapshot;
        emit changed();
    }

    m_refreshing = false;
    if (m_refreshQueued) {
        m_refreshQueued = false;
        scheduleRefresh();
    }
}

void NetworkRoute::readManager() {
    const auto bus = systemBus();
    if (!bus) {
        finishRefresh(Snapshot());
        return;
    }

    auto msg = QDBusMessage::createMethodCall(QString::fromUtf8(kService), QString::fromUtf8(kManagerPath),
        QString::fromUtf8(kPropsIface), QStringLiteral("GetAll"));
    msg << QString::fromUtf8(kManagerIface);

    step(1);
    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher* call) {
        call->deleteLater();

        const QDBusPendingReply<QVariantMap> reply = *call;
        if (reply.isError()) {
            qCWarning(logNetworkRoute) << "Failed to read NetworkManager properties:" << reply.error().message();
            step(-1);
            return;
        }

        const auto props = reply.value();
        m_primaryConnection = props.value(QStringLiteral("PrimaryConnection")).value<QDBusObjectPath>().path();

        const auto actives = props.value(QStringLiteral("ActiveConnections")).value<QDBusArgument>();
        QList<QDBusObjectPath> paths;
        actives >> paths;

        for (const auto& path : paths) {
            readActiveConnection(path.path(), path.path() == m_primaryConnection);
        }

        step(-1);
    });
}

void NetworkRoute::readActiveConnection(const QString& path, bool isPrimary) {
    Q_UNUSED(isPrimary);

    const auto bus = systemBus();
    if (!bus || path.isEmpty() || path == QStringLiteral("/")) {
        return;
    }

    watchObject(path);

    auto msg = QDBusMessage::createMethodCall(
        QString::fromUtf8(kService), path, QString::fromUtf8(kPropsIface), QStringLiteral("GetAll"));
    msg << QString::fromUtf8(kActiveIface);

    step(1);
    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, path](QDBusPendingCallWatcher* call) {
        call->deleteLater();

        const QDBusPendingReply<QVariantMap> reply = *call;
        if (reply.isError()) {
            // Connections come and go while we're walking; that's expected.
            qCDebug(logNetworkRoute) << "Skipping active connection" << path << ":" << reply.error().message();
            step(-1);
            return;
        }

        const auto props = reply.value();
        m_connIsDefault4.insert(path, props.value(QStringLiteral("Default")).toBool());
        m_connIsDefault6.insert(path, props.value(QStringLiteral("Default6")).toBool());

        const auto devices = props.value(QStringLiteral("Devices")).value<QDBusArgument>();
        QList<QDBusObjectPath> paths;
        devices >> paths;

        // A connection's devices are its stack bottom-up, so the first one is
        // the link the traffic actually goes over. A VPN's active connection
        // has no devices of its own beyond its tunnel, which classifies as
        // Other and leaves the underlying connection to answer for the link.
        if (!paths.isEmpty()) {
            readDevice(path, paths.first().path());
        }

        step(-1);
    });
}

void NetworkRoute::readDevice(const QString& connPath, const QString& devicePath) {
    const auto bus = systemBus();
    if (!bus || devicePath.isEmpty() || devicePath == QStringLiteral("/")) {
        return;
    }

    watchObject(devicePath);

    auto msg = QDBusMessage::createMethodCall(
        QString::fromUtf8(kService), devicePath, QString::fromUtf8(kPropsIface), QStringLiteral("GetAll"));
    msg << QString::fromUtf8(kDeviceIface);

    step(1);
    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, connPath](QDBusPendingCallWatcher* call) {
        call->deleteLater();

        const QDBusPendingReply<QVariantMap> reply = *call;
        if (reply.isError()) {
            qCDebug(logNetworkRoute) << "Skipping device for" << connPath << ":" << reply.error().message();
            step(-1);
            return;
        }

        const auto props = reply.value();
        m_connTransport.insert(connPath, transportForDeviceType(props.value(QStringLiteral("DeviceType")).toUInt()));
        m_connInterface.insert(connPath, props.value(QStringLiteral("Interface")).toString());

        step(-1);
    });
}

} // namespace caelestia::services
