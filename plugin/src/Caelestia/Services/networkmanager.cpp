#include "networkmanager.hpp"

#include <qdbusargument.h>
#include <qdbusextratypes.h>
#include <qdbusmessage.h>
#include <qdbuspendingcall.h>
#include <qdbuspendingreply.h>
#include <qloggingcategory.h>
#include <qtimer.h>

#include <utility>

namespace caelestia::services {

namespace {

Q_LOGGING_CATEGORY(logNetworkManager, "caelestia.services.networkmanager", QtWarningMsg);

constexpr const char* kService = "org.freedesktop.NetworkManager";
constexpr const char* kManagerPath = "/org/freedesktop/NetworkManager";
constexpr const char* kManagerIface = "org.freedesktop.NetworkManager";
constexpr const char* kDeviceIface = "org.freedesktop.NetworkManager.Device";
constexpr const char* kActiveIface = "org.freedesktop.NetworkManager.Connection.Active";
constexpr const char* kPropsIface = "org.freedesktop.DBus.Properties";

// From NMDeviceType; only the two we classify are named.
constexpr uint kDeviceTypeEthernet = 1;
constexpr uint kDeviceTypeWifi = 2;

// NM_DEVICE_STATE_ACTIVATED
constexpr uint kStateActivated = 100;

Transport transportForDeviceType(uint deviceType) {
    switch (deviceType) {
    case kDeviceTypeEthernet: return config::NetworkTransport::Ethernet;
    case kDeviceTypeWifi: return config::NetworkTransport::Wifi;
    default: return config::NetworkTransport::Other;
    }
}

} // namespace

NmDevice::NmDevice(QString path, QObject* parent)
    : QObject(parent)
    , m_path(std::move(path)) {}

QString NmDevice::path() const {
    return m_path;
}

QString NmDevice::interface() const {
    return m_interface;
}

Transport NmDevice::type() const {
    return m_type;
}

uint NmDevice::state() const {
    return m_state;
}

bool NmDevice::connected() const {
    return m_state == kStateActivated;
}

QString NmDevice::connection() const {
    return m_connection;
}

void NmDevice::setConnection(const QString& connection) {
    if (connection == m_connection) {
        return;
    }

    m_connection = connection;
    emit changed();
}

void NmDevice::update(const QVariantMap& props) {
    const auto interface = props.value(QStringLiteral("Interface")).toString();
    const auto type = transportForDeviceType(props.value(QStringLiteral("DeviceType")).toUInt());
    const auto state = props.value(QStringLiteral("State")).toUInt();

    if (interface == m_interface && type == m_type && state == m_state) {
        return;
    }

    m_interface = interface;
    m_type = type;
    m_state = state;
    emit changed();
}

NetworkManager::NetworkManager(QObject* parent)
    : QObject(parent) {
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

    watchObject(QString::fromUtf8(kManagerPath));
    scheduleRefresh();
}

bool NetworkManager::ready() const {
    return m_ready;
}

QList<NmDevice*> NetworkManager::devices() const {
    return m_devices;
}

bool NetworkManager::wirelessEnabled() const {
    return m_wirelessEnabled;
}

std::optional<QDBusConnection> NetworkManager::systemBus() {
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        qCWarning(logNetworkManager) << "System bus unavailable";
        return std::nullopt;
    }
    return bus;
}

void NetworkManager::watchObject(const QString& path) {
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

void NetworkManager::handlePropertiesChanged(
    const QString& iface, const QVariantMap& properties, const QStringList& invalidated) {
    Q_UNUSED(properties);
    Q_UNUSED(invalidated);

    if (iface == QString::fromUtf8(kManagerIface) || iface == QString::fromUtf8(kDeviceIface)) {
        scheduleRefresh();
    }
}

void NetworkManager::handleNameOwnerChanged(const QString& name, const QString& oldOwner, const QString& newOwner) {
    Q_UNUSED(oldOwner);

    if (name != QString::fromUtf8(kService)) {
        return;
    }

    m_watched.clear();

    if (newOwner.isEmpty()) {
        // NetworkManager went away; report nothing rather than stale devices.
        clearDevices();
        m_ready = false;
        emit devicesChanged();
        emit changed();
        return;
    }

    // Fresh objects on the new owner, so the old subscriptions are worthless.
    watchObject(QString::fromUtf8(kManagerPath));
    scheduleRefresh();
}

void NetworkManager::clearDevices() {
    for (auto* device : std::as_const(m_devices)) {
        device->deleteLater();
    }
    m_devices.clear();
    m_byPath.clear();
}

void NetworkManager::scheduleRefresh() {
    if (m_refreshing) {
        m_refreshQueued = true;
        return;
    }

    m_refreshing = true;
    QTimer::singleShot(0, this, [this]() {
        refresh();
    });
}

void NetworkManager::refresh() {
    m_seen.clear();
    m_listChanged = false;
    m_pending = 0;

    readManager();
}

// Each async read holds a reference; the result is published when the last one
// lands, so a partial walk is never visible.
void NetworkManager::step(int delta) {
    m_pending += delta;
    if (m_pending > 0) {
        return;
    }

    finish();
}

void NetworkManager::finish() {
    // Anything not seen by this walk is gone.
    for (int i = m_devices.size() - 1; i >= 0; i--) {
        auto* device = m_devices.at(i);
        if (!m_seen.contains(device->path())) {
            m_byPath.remove(device->path());
            m_devices.removeAt(i);
            device->deleteLater();
            m_listChanged = true;
        }
    }

    const bool wasReady = m_ready;
    m_ready = true;

    if (m_listChanged) {
        emit devicesChanged();
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

void NetworkManager::readManager() {
    auto bus = systemBus();
    if (!bus) {
        finish();
        return;
    }

    auto msg = QDBusMessage::createMethodCall(
        QString::fromUtf8(kService),
        QString::fromUtf8(kManagerPath),
        QString::fromUtf8(kPropsIface),
        QStringLiteral("GetAll"));
    msg << QString::fromUtf8(kManagerIface);

    step(1);
    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher* call) {
        call->deleteLater();

        const QDBusPendingReply<QVariantMap> reply = *call;
        if (reply.isError()) {
            qCWarning(logNetworkManager) << "Failed to read NetworkManager properties:" << reply.error().message();
            step(-1);
            return;
        }

        const auto props = reply.value();

        const auto wireless = props.value(QStringLiteral("WirelessEnabled")).toBool();
        if (wireless != m_wirelessEnabled) {
            m_wirelessEnabled = wireless;
            emit changed();
        }

        const auto devices = props.value(QStringLiteral("Devices")).value<QDBusArgument>();
        QList<QDBusObjectPath> paths;
        devices >> paths;

        for (const auto& path : paths) {
            readDevice(path.path());
        }

        step(-1);
    });
}

void NetworkManager::readDevice(const QString& path) {
    auto bus = systemBus();
    if (!bus || path.isEmpty() || path == QStringLiteral("/")) {
        return;
    }

    watchObject(path);

    auto msg = QDBusMessage::createMethodCall(
        QString::fromUtf8(kService), path, QString::fromUtf8(kPropsIface), QStringLiteral("GetAll"));
    msg << QString::fromUtf8(kDeviceIface);

    step(1);
    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, path](QDBusPendingCallWatcher* call) {
        call->deleteLater();

        const QDBusPendingReply<QVariantMap> reply = *call;
        if (reply.isError()) {
            // Devices come and go while we're walking; that's expected.
            qCDebug(logNetworkManager) << "Skipping device" << path << ":" << reply.error().message();
            step(-1);
            return;
        }

        m_seen.insert(path);

        auto* device = m_byPath.value(path);
        if (device == nullptr) {
            device = new NmDevice(path, this);
            m_byPath.insert(path, device);
            m_devices.append(device);
            m_listChanged = true;
        }
        const auto props = reply.value();
        device->update(props);

        // The profile name isn't on the device, it's on whatever active
        // connection is attached to it, so that's a second read.
        const auto connectionPath = props.value(QStringLiteral("ActiveConnection")).value<QDBusObjectPath>().path();
        if (connectionPath.isEmpty() || connectionPath == QStringLiteral("/")) {
            device->setConnection(QString());
        } else {
            readConnection(path, connectionPath);
        }

        step(-1);
    });
}

void NetworkManager::readConnection(const QString& devicePath, const QString& connectionPath) {
    auto bus = systemBus();
    if (!bus) {
        return;
    }

    auto msg = QDBusMessage::createMethodCall(
        QString::fromUtf8(kService), connectionPath, QString::fromUtf8(kPropsIface), QStringLiteral("Get"));
    msg << QString::fromUtf8(kActiveIface) << QStringLiteral("Id");

    step(1);
    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, devicePath](QDBusPendingCallWatcher* call) {
        call->deleteLater();

        const QDBusPendingReply<QDBusVariant> reply = *call;
        if (reply.isError()) {
            // Connections go down while we're walking; that's expected.
            qCDebug(logNetworkManager) << "Skipping connection for" << devicePath << ":" << reply.error().message();
        }

        // Looked up again rather than captured: the walk may have dropped the
        // device while this was in flight.
        auto* device = m_byPath.value(devicePath);
        if (device != nullptr) {
            device->setConnection(reply.isError() ? QString() : reply.value().variant().toString());
        }

        step(-1);
    });
}

} // namespace caelestia::services
