#include "networkroute.hpp"

#include <qdbusargument.h>
#include <qdbusextratypes.h>
#include <qdbusmessage.h>
#include <qdbuspendingcall.h>
#include <qdbuspendingreply.h>
#include <qdbusreply.h>
#include <qloggingcategory.h>
#include <qtimer.h>

#include <utility>

namespace {

Q_LOGGING_CATEGORY(lcNetworkRoute, "caelestia.services.networkroute", QtWarningMsg)

} // namespace

namespace caelestia::services {

using Qt::StringLiterals::operator""_s;

namespace {

const QString k_service = u"org.freedesktop.NetworkManager"_s;
const QString k_managerPath = u"/org/freedesktop/NetworkManager"_s;
const QString k_managerIface = u"org.freedesktop.NetworkManager"_s;
const QString k_activeIface = u"org.freedesktop.NetworkManager.Connection.Active"_s;
const QString k_deviceIface = u"org.freedesktop.NetworkManager.Device"_s;
const QString k_propsIface = u"org.freedesktop.DBus.Properties"_s;

const QString k_busService = u"org.freedesktop.DBus"_s;
const QString k_busPath = u"/org/freedesktop/DBus"_s;

// From NMDeviceType; only the two we classify are named.
constexpr uint k_deviceTypeEthernet = 1;
constexpr uint k_deviceTypeWifi = 2;

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
    bus->connect(k_busService, k_busPath, k_busService, u"NameOwnerChanged"_s, u"sss"_s, this,
        SLOT(handleNameOwnerChanged(QString, QString, QString)));

    watchObject(k_managerPath);
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
    const auto v4 = m_current.ipv4;
    const auto v6 = m_current.ipv6;
    return v4 != config::NetworkTransport::None && v6 != config::NetworkTransport::None && v4 != v6;
}

QString NetworkRoute::primaryInterface() const {
    return m_current.primaryInterface;
}

std::optional<QDBusConnection> NetworkRoute::systemBus() {
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        qCWarning(lcNetworkRoute) << "System bus unavailable";
        return std::nullopt;
    }
    return bus;
}

Transport NetworkRoute::transportForDeviceType(uint deviceType) {
    switch (deviceType) {
    case k_deviceTypeEthernet:
        return config::NetworkTransport::Ethernet;
    case k_deviceTypeWifi:
        return config::NetworkTransport::Wifi;
    default:
        return config::NetworkTransport::Other;
    }
}

// Subscribes to property changes on an object once. NetworkManager emits these
// for the manager, every active connection and every device, which is what
// tells us a walk is out of date.
void NetworkRoute::watchObject(const QString& path) {
    if (path.isEmpty() || path == u"/"_s || m_watched.contains(path)) {
        return;
    }

    auto bus = systemBus();
    if (!bus) {
        return;
    }

    if (bus->connect(k_service, path, k_propsIface, u"PropertiesChanged"_s, this,
            SLOT(handlePropertiesChanged(QString, QVariantMap, QStringList)))) {
        m_watched.insert(path);
    }
}

void NetworkRoute::handlePropertiesChanged(
    const QString& iface, const QVariantMap& properties, const QStringList& invalidated) {
    Q_UNUSED(properties);
    Q_UNUSED(invalidated);

    if (iface == k_managerIface || iface == k_activeIface || iface == k_deviceIface) {
        scheduleRefresh();
    }
}

void NetworkRoute::handleNameOwnerChanged(const QString& name, const QString& oldOwner, const QString& newOwner) {
    Q_UNUSED(oldOwner);

    if (name != k_service) {
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
    watchObject(k_managerPath);
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
    QTimer::singleShot(0, this, &NetworkRoute::refresh);
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

    auto msg = QDBusMessage::createMethodCall(k_service, k_managerPath, k_propsIface, u"GetAll"_s);
    msg << k_managerIface;

    step(1);
    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher* call) {
        call->deleteLater();

        const QDBusPendingReply<QVariantMap> reply = *call;
        if (reply.isError()) {
            qCWarning(lcNetworkRoute) << "Failed to read NetworkManager properties:" << reply.error().message();
            step(-1);
            return;
        }

        const auto props = reply.value();
        m_primaryConnection = props.value(u"PrimaryConnection"_s).value<QDBusObjectPath>().path();

        const auto actives = props.value(u"ActiveConnections"_s).value<QDBusArgument>();
        QList<QDBusObjectPath> paths;
        actives >> paths;

        for (const auto& path : std::as_const(paths)) {
            readActiveConnection(path.path(), path.path() == m_primaryConnection);
        }

        step(-1);
    });
}

void NetworkRoute::readActiveConnection(const QString& path, bool isPrimary) {
    Q_UNUSED(isPrimary);

    const auto bus = systemBus();
    if (!bus || path.isEmpty() || path == u"/"_s) {
        return;
    }

    watchObject(path);

    auto msg = QDBusMessage::createMethodCall(k_service, path, k_propsIface, u"GetAll"_s);
    msg << k_activeIface;

    step(1);
    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, path](QDBusPendingCallWatcher* call) {
        call->deleteLater();

        const QDBusPendingReply<QVariantMap> reply = *call;
        if (reply.isError()) {
            // Connections come and go while we're walking; that's expected.
            qCDebug(lcNetworkRoute) << "Skipping active connection" << path << ":" << reply.error().message();
            step(-1);
            return;
        }

        const auto props = reply.value();
        m_connIsDefault4.insert(path, props.value(u"Default"_s).toBool());
        m_connIsDefault6.insert(path, props.value(u"Default6"_s).toBool());

        const auto devices = props.value(u"Devices"_s).value<QDBusArgument>();
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
    if (!bus || devicePath.isEmpty() || devicePath == u"/"_s) {
        return;
    }

    watchObject(devicePath);

    auto msg = QDBusMessage::createMethodCall(k_service, devicePath, k_propsIface, u"GetAll"_s);
    msg << k_deviceIface;

    step(1);
    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, connPath](QDBusPendingCallWatcher* call) {
        call->deleteLater();

        const QDBusPendingReply<QVariantMap> reply = *call;
        if (reply.isError()) {
            qCDebug(lcNetworkRoute) << "Skipping device for" << connPath << ":" << reply.error().message();
            step(-1);
            return;
        }

        const auto props = reply.value();
        m_connTransport.insert(connPath, transportForDeviceType(props.value(u"DeviceType"_s).toUInt()));
        m_connInterface.insert(connPath, props.value(u"Interface"_s).toString());

        step(-1);
    });
}

} // namespace caelestia::services
