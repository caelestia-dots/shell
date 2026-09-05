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
constexpr const char* kWirelessIface = "org.freedesktop.NetworkManager.Device.Wireless";
constexpr const char* kApIface = "org.freedesktop.NetworkManager.AccessPoint";
constexpr const char* kPropsIface = "org.freedesktop.DBus.Properties";

// From NMDeviceType; only the two we classify are named.
constexpr uint kDeviceTypeEthernet = 1;
constexpr uint kDeviceTypeWifi = 2;

// NM_DEVICE_STATE_ACTIVATED
constexpr uint kStateActivated = 100;

// From NM80211ApFlags and NM80211ApSecurityFlags.
constexpr uint kApFlagPrivacy = 0x1;
constexpr uint kApSecKeyMgmt8021X = 0x200;
constexpr uint kApSecKeyMgmtSae = 0x400;
constexpr uint kApSecKeyMgmtOwe = 0x800;
constexpr uint kApSecKeyMgmtOweTm = 0x1000;

// Builds the label nmcli printed in its SECURITY column, so the string the UI
// shows doesn't change now that it comes from dbus rather than parsed output.
QString securityLabel(uint flags, uint wpaFlags, uint rsnFlags) {
    if (wpaFlags == 0 && rsnFlags == 0) {
        return (flags & kApFlagPrivacy) != 0 ? QStringLiteral("WEP") : QString();
    }

    QStringList parts;
    if (wpaFlags != 0) {
        parts << QStringLiteral("WPA1");
    }
    if ((rsnFlags & ~(kApSecKeyMgmtSae | kApSecKeyMgmtOwe | kApSecKeyMgmtOweTm)) != 0) {
        parts << QStringLiteral("WPA2");
    }
    if ((rsnFlags & kApSecKeyMgmtSae) != 0) {
        parts << QStringLiteral("WPA3");
    }
    if ((rsnFlags & (kApSecKeyMgmtOwe | kApSecKeyMgmtOweTm)) != 0) {
        parts << QStringLiteral("OWE");
    }
    if (((wpaFlags | rsnFlags) & kApSecKeyMgmt8021X) != 0) {
        parts << QStringLiteral("802.1X");
    }

    return parts.join(QLatin1Char(' '));
}

Transport transportForDeviceType(uint deviceType) {
    switch (deviceType) {
    case kDeviceTypeEthernet: return config::NetworkTransport::Ethernet;
    case kDeviceTypeWifi: return config::NetworkTransport::Wifi;
    default: return config::NetworkTransport::Other;
    }
}

} // namespace

NmAccessPoint::NmAccessPoint(QString path, QObject* parent)
    : QObject(parent)
    , m_path(std::move(path)) {}

QString NmAccessPoint::path() const {
    return m_path;
}

QString NmAccessPoint::ssid() const {
    return m_ssid;
}

QString NmAccessPoint::bssid() const {
    return m_bssid;
}

int NmAccessPoint::strength() const {
    return m_strength;
}

int NmAccessPoint::frequency() const {
    return m_frequency;
}

QString NmAccessPoint::security() const {
    return securityLabel(m_flags, m_wpaFlags, m_rsnFlags);
}

bool NmAccessPoint::isSecure() const {
    return !security().isEmpty();
}

bool NmAccessPoint::active() const {
    return m_active;
}

void NmAccessPoint::setActive(bool active) {
    if (active == m_active) {
        return;
    }

    m_active = active;
    emit changed();
}

// Merges rather than replaces: PropertiesChanged carries only what moved, so a
// missing key means unchanged, not empty.
void NmAccessPoint::update(const QVariantMap& props) {
    bool dirty = false;

    const auto apply = [&props, &dirty](const char* key, auto& field, auto convert) {
        const auto it = props.find(QString::fromUtf8(key));
        if (it == props.end()) {
            return;
        }

        const auto value = convert(it.value());
        if (value != field) {
            field = value;
            dirty = true;
        }
    };

    // Ssid is a byte array; NetworkManager doesn't promise it's valid UTF-8.
    apply("Ssid", m_ssid, [](const QVariant& v) {
        return QString::fromUtf8(v.toByteArray());
    });
    apply("HwAddress", m_bssid, [](const QVariant& v) {
        return v.toString();
    });
    apply("Strength", m_strength, [](const QVariant& v) {
        return static_cast<int>(v.toUInt());
    });
    apply("Frequency", m_frequency, [](const QVariant& v) {
        return static_cast<int>(v.toUInt());
    });
    apply("Flags", m_flags, [](const QVariant& v) {
        return v.toUInt();
    });
    apply("WpaFlags", m_wpaFlags, [](const QVariant& v) {
        return v.toUInt();
    });
    apply("RsnFlags", m_rsnFlags, [](const QVariant& v) {
        return v.toUInt();
    });

    if (dirty) {
        emit changed();
    }
}

void NmAccessPoint::watch() {
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        return;
    }

    bus.connect(
        QString::fromUtf8(kService),
        m_path,
        QString::fromUtf8(kPropsIface),
        QStringLiteral("PropertiesChanged"),
        this,
        SLOT(handlePropertiesChanged(QString, QVariantMap, QStringList)));
}

void NmAccessPoint::handlePropertiesChanged(
    const QString& iface, const QVariantMap& properties, const QStringList& invalidated) {
    Q_UNUSED(invalidated);

    if (iface == QString::fromUtf8(kApIface)) {
        update(properties);
    }
}

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

QList<NmAccessPoint*> NmDevice::accessPoints() const {
    return m_accessPoints;
}

qlonglong NmDevice::lastScan() const {
    return m_lastScan;
}

void NmDevice::setLastScan(qlonglong lastScan) {
    if (lastScan == m_lastScan) {
        return;
    }

    m_lastScan = lastScan;
    emit changed();
}

NmAccessPoint* NmDevice::accessPoint(const QString& path) const {
    return m_apByPath.value(path);
}

void NmDevice::addAccessPoint(NmAccessPoint* accessPoint) {
    if (accessPoint == nullptr || m_apByPath.contains(accessPoint->path())) {
        return;
    }

    m_apByPath.insert(accessPoint->path(), accessPoint);
    m_accessPoints.append(accessPoint);
    emit accessPointsChanged();
}

bool NmDevice::retainAccessPoints(const QSet<QString>& keep) {
    bool removed = false;

    for (int i = m_accessPoints.size() - 1; i >= 0; i--) {
        auto* accessPoint = m_accessPoints.at(i);
        if (!keep.contains(accessPoint->path())) {
            m_apByPath.remove(accessPoint->path());
            m_accessPoints.removeAt(i);
            accessPoint->deleteLater();
            removed = true;
        }
    }

    if (removed) {
        emit accessPointsChanged();
    }

    return removed;
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

    // Access points keep themselves up to date, so this only needs to catch
    // membership changes on the wireless interface, not per-AP churn.
    if (iface == QString::fromUtf8(kManagerIface) || iface == QString::fromUtf8(kDeviceIface) ||
        iface == QString::fromUtf8(kWirelessIface)) {
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

        if (device->type() == config::NetworkTransport::Wifi) {
            readWireless(path);
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

void NetworkManager::readWireless(const QString& devicePath) {
    auto bus = systemBus();
    if (!bus) {
        return;
    }

    auto msg = QDBusMessage::createMethodCall(
        QString::fromUtf8(kService), devicePath, QString::fromUtf8(kPropsIface), QStringLiteral("GetAll"));
    msg << QString::fromUtf8(kWirelessIface);

    step(1);
    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, devicePath](QDBusPendingCallWatcher* call) {
        call->deleteLater();

        const QDBusPendingReply<QVariantMap> reply = *call;
        auto* device = m_byPath.value(devicePath);
        if (reply.isError() || device == nullptr) {
            if (reply.isError()) {
                qCDebug(logNetworkManager) << "Skipping wireless" << devicePath << ":" << reply.error().message();
            }
            step(-1);
            return;
        }

        const auto props = reply.value();

        QList<QDBusObjectPath> paths;
        props.value(QStringLiteral("AccessPoints")).value<QDBusArgument>() >> paths;

        const auto activePath = props.value(QStringLiteral("ActiveAccessPoint")).value<QDBusObjectPath>().path();

        // Absent on older NetworkManager; leave it at -1 rather than reading a
        // missing key as "scanned at boot".
        const auto lastScan = props.find(QStringLiteral("LastScan"));
        if (lastScan != props.end()) {
            device->setLastScan(lastScan.value().toLongLong());
        }

        QSet<QString> seen;
        for (const auto& path : paths) {
            seen.insert(path.path());

            auto* accessPoint = device->accessPoint(path.path());
            if (accessPoint == nullptr) {
                // Only new access points cost a read; the ones already held
                // track their own properties.
                readAccessPoint(devicePath, path.path());
            } else {
                accessPoint->setActive(path.path() == activePath);
            }
        }

        device->retainAccessPoints(seen);

        step(-1);
    });
}

void NetworkManager::readAccessPoint(const QString& devicePath, const QString& accessPointPath) {
    auto bus = systemBus();
    if (!bus) {
        return;
    }

    auto msg = QDBusMessage::createMethodCall(
        QString::fromUtf8(kService), accessPointPath, QString::fromUtf8(kPropsIface), QStringLiteral("GetAll"));
    msg << QString::fromUtf8(kApIface);

    step(1);
    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(
        watcher,
        &QDBusPendingCallWatcher::finished,
        this,
        [this, devicePath, accessPointPath](QDBusPendingCallWatcher* call) {
            call->deleteLater();

            const QDBusPendingReply<QVariantMap> reply = *call;
            auto* device = m_byPath.value(devicePath);
            if (reply.isError() || device == nullptr) {
                if (reply.isError()) {
                    // Access points come and go between scans; that's expected.
                    qCDebug(logNetworkManager)
                        << "Skipping access point" << accessPointPath << ":" << reply.error().message();
                }
                step(-1);
                return;
            }

            if (device->accessPoint(accessPointPath) == nullptr) {
                auto* accessPoint = new NmAccessPoint(accessPointPath, device);
                accessPoint->update(reply.value());
                accessPoint->watch();
                device->addAccessPoint(accessPoint);
            }

            step(-1);
        });
}

} // namespace caelestia::services
