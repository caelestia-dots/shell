#include "networkroute.hpp"

#include <qdbusargument.h>
#include <qdbusextratypes.h>
#include <qdbusmessage.h>
#include <qdbuspendingcall.h>
#include <qdbuspendingreply.h>
#include <qloggingcategory.h>

namespace caelestia::services {

namespace {

Q_LOGGING_CATEGORY(logNetworkRoute, "caelestia.services.networkroute", QtWarningMsg);

constexpr const char* k_service = "org.freedesktop.NetworkManager";
constexpr const char* k_managerPath = "/org/freedesktop/NetworkManager";
constexpr const char* k_managerIface = "org.freedesktop.NetworkManager";
constexpr const char* k_activeIface = "org.freedesktop.NetworkManager.Connection.Active";
constexpr const char* k_deviceIface = "org.freedesktop.NetworkManager.Device";
constexpr const char* k_propsIface = "org.freedesktop.DBus.Properties";

// From NMDeviceType; only the two we classify are named.
constexpr uint k_deviceTypeEthernet = 1;
constexpr uint k_deviceTypeWifi = 2;

} // namespace

NetworkRoute::NetworkRoute(QObject* parent)
    : NmWalker(QString::fromUtf8(k_managerPath), parent) {}

Transport NetworkRoute::primaryTransport() const {
    return m_primary;
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

// The primary connection is a manager property, and its device's type is a
// device property, so a change to either has to start a fresh walk. The active
// connection is watched too, since its device list can change under it.
bool NetworkRoute::triggersRefresh(const QString& iface) const {
    return iface == QString::fromUtf8(k_managerIface) || iface == QString::fromUtf8(k_activeIface) ||
           iface == QString::fromUtf8(k_deviceIface);
}

void NetworkRoute::publish() {
    if (m_building == m_primary) {
        return;
    }

    m_primary = m_building;
    setListChanged();
}

void NetworkRoute::clearItems() {
    m_primary = config::NetworkTransport::None;
}

void NetworkRoute::readRoot() {
    m_building = config::NetworkTransport::None;

    auto bus = systemBus();
    if (!bus) {
        abandonWalk();
        return;
    }

    auto msg = QDBusMessage::createMethodCall(QString::fromUtf8(k_service), QString::fromUtf8(k_managerPath),
        QString::fromUtf8(k_propsIface), QStringLiteral("GetAll"));
    msg << QString::fromUtf8(k_managerIface);

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

        readActiveConnection(reply.value().value(QStringLiteral("PrimaryConnection")).value<QDBusObjectPath>().path());

        step(-1);
    });
    // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks) watcher is parented and self-deletes
}

void NetworkRoute::readActiveConnection(const QString& path) {
    auto bus = systemBus();
    if (!bus || path.isEmpty() || path == QStringLiteral("/")) {
        return;
    }

    watchObject(path);

    auto msg = QDBusMessage::createMethodCall(
        QString::fromUtf8(k_service), path, QString::fromUtf8(k_propsIface), QStringLiteral("GetAll"));
    msg << QString::fromUtf8(k_activeIface);

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

        QList<QDBusObjectPath> paths;
        reply.value().value(QStringLiteral("Devices")).value<QDBusArgument>() >> paths;

        // A connection's devices are its stack bottom-up, so the first one is
        // the link the traffic actually goes over. A VPN's active connection
        // has no devices of its own beyond its tunnel, which classifies as
        // Other and leaves the underlying connection to answer for the link.
        if (!paths.isEmpty()) {
            readDevice(paths.first().path());
        }

        step(-1);
    });
    // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks) watcher is parented and self-deletes
}

void NetworkRoute::readDevice(const QString& devicePath) {
    auto bus = systemBus();
    if (!bus || devicePath.isEmpty() || devicePath == QStringLiteral("/")) {
        return;
    }

    watchObject(devicePath);

    auto msg = QDBusMessage::createMethodCall(
        QString::fromUtf8(k_service), devicePath, QString::fromUtf8(k_propsIface), QStringLiteral("GetAll"));
    msg << QString::fromUtf8(k_deviceIface);

    step(1);
    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, devicePath](QDBusPendingCallWatcher* call) {
        call->deleteLater();

        const QDBusPendingReply<QVariantMap> reply = *call;
        if (reply.isError()) {
            qCDebug(logNetworkRoute) << "Skipping device" << devicePath << ":" << reply.error().message();
            step(-1);
            return;
        }

        m_building = transportForDeviceType(reply.value().value(QStringLiteral("DeviceType")).toUInt());

        step(-1);
    });
    // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks) watcher is parented and self-deletes
}

} // namespace caelestia::services
