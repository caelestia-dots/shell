#include "networkdbus.hpp"

#include <qdbusargument.h>
#include <qdbusconnection.h>
#include <qdbusextratypes.h>
#include <qdbusmessage.h>
#include <qdbusmetatype.h>
#include <qdbusreply.h>
#include <qfileinfo.h>
#include <qjsengine.h>
#include <qloggingcategory.h>
#include <qtimer.h>
#include <quuid.h>

namespace {

Q_LOGGING_CATEGORY(lcNetworkDbus, "caelestia.services.networkdbus", QtInfoMsg)

const QString k_service = QStringLiteral("org.freedesktop.NetworkManager");
const QString k_root = QStringLiteral("/org/freedesktop/NetworkManager");
const QString k_settingsPath = QStringLiteral("/org/freedesktop/NetworkManager/Settings");
const QString k_nmIface = QStringLiteral("org.freedesktop.NetworkManager");
const QString k_settingsIface = QStringLiteral("org.freedesktop.NetworkManager.Settings");
const QString k_connectionIface = QStringLiteral("org.freedesktop.NetworkManager.Settings.Connection");
const QString k_deviceIface = QStringLiteral("org.freedesktop.NetworkManager.Device");
const QString k_wirelessIface = QStringLiteral("org.freedesktop.NetworkManager.Device.Wireless");
const QString k_apIface = QStringLiteral("org.freedesktop.NetworkManager.AccessPoint");
const QString k_activeIface = QStringLiteral("org.freedesktop.NetworkManager.Connection.Active");
const QString k_ip4Iface = QStringLiteral("org.freedesktop.NetworkManager.IP4Config");
const QString k_propsIface = QStringLiteral("org.freedesktop.DBus.Properties");

// NMDeviceType
constexpr uint k_typeEthernet = 1;
constexpr uint k_typeWifi = 2;

// NMDeviceState
constexpr uint k_deviceActivated = 100;

// NM_802_11_AP_FLAGS and NM_802_11_AP_SEC
constexpr uint k_apFlagPrivacy = 0x1;
constexpr uint k_secKeyPsk = 0x100;
constexpr uint k_secKey8021x = 0x200;
constexpr uint k_secKeySae = 0x400;
constexpr uint k_secKeyOwe = 0x800;

QString pathOf(const QVariant& value) {
    if (value.canConvert<QDBusObjectPath>())
        return value.value<QDBusObjectPath>().path();
    return value.toString();
}

QString deviceStateName(uint state) {
    switch (state) {
    case 10:
        return QStringLiteral("unmanaged");
    case 20:
        return QStringLiteral("unavailable");
    case 30:
        return QStringLiteral("disconnected");
    case 100:
        return QStringLiteral("connected");
    case 110:
        return QStringLiteral("deactivating");
    case 120:
        return QStringLiteral("failed");
    default:
        return state > 30 && state < 100 ? QStringLiteral("connecting") : QStringLiteral("unknown");
    }
}

// Security as nmcli prints it in the SECURITY column: WPA1, WPA2, WPA3, 802.1X, OWE, WEP, or
// nothing for open networks
QString securityOf(uint flags, uint wpaFlags, uint rsnFlags) {
    QStringList parts;
    if (wpaFlags & k_secKeyPsk)
        parts << QStringLiteral("WPA1");
    if (rsnFlags & k_secKeyPsk)
        parts << QStringLiteral("WPA2");
    if (rsnFlags & k_secKeySae)
        parts << QStringLiteral("WPA3");
    if ((wpaFlags | rsnFlags) & k_secKey8021x)
        parts << QStringLiteral("802.1X");
    if (rsnFlags & k_secKeyOwe)
        parts << QStringLiteral("OWE");
    if (parts.isEmpty() && (flags & k_apFlagPrivacy))
        parts << QStringLiteral("WEP");
    return parts.join(QLatin1Char(' '));
}

QVariantMap getAll(const QString& path, const QString& iface) {
    const auto bus = QDBusConnection::systemBus();
    auto msg = QDBusMessage::createMethodCall(k_service, path, k_propsIface, QStringLiteral("GetAll"));
    msg.setArguments({ iface });
    const QDBusReply<QVariantMap> reply = bus.call(msg);
    return reply.isValid() ? reply.value() : QVariantMap{};
}

// Calls a method and reports whether NetworkManager accepted it (methods without a return value
// still succeed)
bool callOk(const QString& path, const QString& iface, const QString& method, const QVariantList& args = {}) {
    const auto bus = QDBusConnection::systemBus();
    auto msg = QDBusMessage::createMethodCall(k_service, path, iface, method);
    msg.setArguments(args);
    const QDBusMessage reply = bus.call(msg);
    if (reply.type() == QDBusMessage::ErrorMessage) {
        qCWarning(lcNetworkDbus) << method << "failed:" << reply.errorMessage();
        return false;
    }
    return true;
}

QVariant callMethod(const QString& path, const QString& iface, const QString& method, const QVariantList& args = {}) {
    const auto bus = QDBusConnection::systemBus();
    auto msg = QDBusMessage::createMethodCall(k_service, path, iface, method);
    msg.setArguments(args);
    const QDBusMessage reply = bus.call(msg);
    if (reply.type() == QDBusMessage::ErrorMessage) {
        qCWarning(lcNetworkDbus) << method << "failed:" << reply.errorMessage();
        return {};
    }
    return reply.arguments().value(0);
}

QStringList pathList(const QVariant& value) {
    QStringList out;
    if (value.canConvert<QDBusArgument>()) {
        const auto arg = value.value<QDBusArgument>();
        arg.beginArray();
        while (!arg.atEnd()) {
            QDBusObjectPath p;
            arg >> p;
            out << p.path();
        }
        arg.endArray();
    } else if (value.canConvert<QList<QDBusObjectPath>>()) {
        for (const auto& p : value.value<QList<QDBusObjectPath>>())
            out << p.path();
    }
    return out;
}

// aa{sv}, such as IP4Config.AddressData
QList<QVariantMap> mapList(const QVariant& value) {
    QList<QVariantMap> out;
    if (value.canConvert<QDBusArgument>()) {
        const auto arg = value.value<QDBusArgument>();
        arg.beginArray();
        while (!arg.atEnd()) {
            QVariantMap m;
            arg >> m;
            out << m;
        }
        arg.endArray();
    }
    return out;
}

QString ssidOf(const QVariant& value) {
    return QString::fromUtf8(value.toByteArray());
}

// Settings of one saved profile, as a{sa{sv}}
QVariantMap settingsOf(const QString& path) {
    const auto reply = callMethod(path, k_connectionIface, QStringLiteral("GetSettings"));
    if (!reply.canConvert<QDBusArgument>())
        return {};

    QVariantMap out;
    const auto arg = reply.value<QDBusArgument>();
    arg.beginMap();
    while (!arg.atEnd()) {
        QString group;
        QVariantMap values;
        arg.beginMapEntry();
        arg >> group >> values;
        arg.endMapEntry();
        out.insert(group, values);
    }
    arg.endMap();
    return out;
}

// Settings for a Wi-Fi profile: the secret travels over D-Bus, never through an argv
QMap<QString, QVariantMap> wifiSettings(
    const QString& ssid, const QString& bssid, const QString& password, bool hidden, const QString& keyMgmt) {
    QVariantMap connection{
        { QStringLiteral("id"), ssid },
        { QStringLiteral("type"), QStringLiteral("802-11-wireless") },
        { QStringLiteral("uuid"), QUuid::createUuid().toString(QUuid::WithoutBraces) },
    };
    QVariantMap wireless{
        { QStringLiteral("ssid"), ssid.toUtf8() },
        { QStringLiteral("mode"), QStringLiteral("infrastructure") },
    };
    if (!bssid.isEmpty()) {
        QByteArray mac;
        for (const auto& part : bssid.split(QLatin1Char(':')))
            mac.append(static_cast<char>(part.toUInt(nullptr, 16)));
        if (mac.size() == 6)
            wireless.insert(QStringLiteral("bssid"), mac);
    }
    if (hidden)
        wireless.insert(QStringLiteral("hidden"), true);

    QMap<QString, QVariantMap> settings{
        { QStringLiteral("connection"), connection },
        { QStringLiteral("802-11-wireless"), wireless },
        { QStringLiteral("ipv4"), QVariantMap{ { QStringLiteral("method"), QStringLiteral("auto") } } },
        { QStringLiteral("ipv6"), QVariantMap{ { QStringLiteral("method"), QStringLiteral("auto") } } },
    };
    if (!password.isEmpty()) {
        settings.insert(QStringLiteral("802-11-wireless-security"),
            QVariantMap{
                { QStringLiteral("key-mgmt"), keyMgmt.isEmpty() ? QStringLiteral("wpa-psk") : keyMgmt },
                { QStringLiteral("psk"), password },
            });
    }
    return settings;
}

} // namespace

namespace caelestia::services {

NetworkDbus::NetworkDbus(QObject* parent)
    : QObject(parent) {
    // a{sa{sv}} (connection settings) and aa{sv} (address and DNS lists) must be registered before
    // they can be sent; unregistered types abort the process inside libdbus
    qDBusRegisterMetaType<QMap<QString, QVariantMap>>();
    qDBusRegisterMetaType<QList<QVariantMap>>();
    m_debounce.setSingleShot(true);
    m_debounce.setInterval(150);
    connect(&m_debounce, &QTimer::timeout, this, &NetworkDbus::changed);

    connectSignals();
}

bool NetworkDbus::available() const {
    return m_connected;
}

void NetworkDbus::connectSignals() {
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        qCWarning(lcNetworkDbus) << "No system bus, network state will not update live";
        return;
    }

    // Any property change on any NetworkManager object (devices, access points, active connections)
    m_connected = bus.connect(
        k_service, QString(), k_propsIface, QStringLiteral("PropertiesChanged"), this, SLOT(scheduleChanged()));
    m_connected = m_connected && bus.connect(k_service, k_root, k_nmIface, QStringLiteral("DeviceAdded"), this,
                                     SLOT(scheduleChanged()));
    m_connected = m_connected && bus.connect(k_service, k_root, k_nmIface, QStringLiteral("DeviceRemoved"), this,
                                     SLOT(scheduleChanged()));
    m_connected = m_connected && bus.connect(k_service, QString(), k_wirelessIface, QStringLiteral("AccessPointAdded"),
                                     this, SLOT(scheduleChanged()));
    m_connected = m_connected && bus.connect(k_service, QString(), k_wirelessIface,
                                     QStringLiteral("AccessPointRemoved"), this, SLOT(scheduleChanged()));
    m_connected = m_connected && bus.connect(k_service, k_settingsPath, k_settingsIface,
                                     QStringLiteral("NewConnection"), this, SLOT(scheduleChanged()));
    m_connected = m_connected && bus.connect(k_service, k_settingsPath, k_settingsIface,
                                     QStringLiteral("ConnectionRemoved"), this, SLOT(scheduleChanged()));

    if (!m_connected)
        qCWarning(lcNetworkDbus) << "Could not subscribe to NetworkManager signals";
    emit availableChanged();
}

void NetworkDbus::scheduleChanged() {
    m_debounce.start();
}

QVariantMap NetworkDbus::snapshot() const {
    QVariantMap out;
    out.insert(QStringLiteral("available"), m_connected);
    if (!m_connected)
        return out;

    out.insert(
        QStringLiteral("wifiEnabled"), getAll(k_root, k_nmIface).value(QStringLiteral("WirelessEnabled")).toBool());

    QVariantList wifiDevices;
    QVariantList ethernetDevices;
    const auto devices = pathList(getAll(k_root, k_nmIface).value(QStringLiteral("AllDevices")));
    for (const auto& devicePath : devices) {
        const auto dev = getAll(devicePath, k_deviceIface);
        const uint type = dev.value(QStringLiteral("DeviceType")).toUInt();
        const auto iface = dev.value(QStringLiteral("Interface")).toString();
        const uint state = dev.value(QStringLiteral("State")).toUInt();
        const auto activePath = pathOf(dev.value(QStringLiteral("ActiveConnection")));
        QString connection;
        if (activePath.length() > 1)
            connection = getAll(activePath, k_activeIface).value(QStringLiteral("Id")).toString();

        if (type == k_typeWifi) {
            const auto wifi = getAll(devicePath, k_wirelessIface);
            const auto activeAp = pathOf(wifi.value(QStringLiteral("ActiveAccessPoint")));

            QVariantList aps;
            for (const auto& apPath : pathList(wifi.value(QStringLiteral("AccessPoints")))) {
                const auto ap = getAll(apPath, k_apIface);
                const auto ssid = ssidOf(ap.value(QStringLiteral("Ssid")));
                if (ssid.isEmpty())
                    continue; // Hidden networks show up as empty SSIDs; nothing to list
                const auto security = securityOf(ap.value(QStringLiteral("Flags")).toUInt(),
                    ap.value(QStringLiteral("WpaFlags")).toUInt(), ap.value(QStringLiteral("RsnFlags")).toUInt());
                aps.append(QVariantMap{
                    { QStringLiteral("ssid"), ssid },
                    { QStringLiteral("bssid"), ap.value(QStringLiteral("HwAddress")).toString() },
                    { QStringLiteral("strength"), ap.value(QStringLiteral("Strength")).toInt() },
                    { QStringLiteral("frequency"), ap.value(QStringLiteral("Frequency")).toInt() },
                    { QStringLiteral("active"), apPath == activeAp },
                    { QStringLiteral("security"), security },
                });
            }

            wifiDevices.append(QVariantMap{
                { QStringLiteral("iface"), iface },
                { QStringLiteral("state"), deviceStateName(state) },
                { QStringLiteral("connection"), connection },
                { QStringLiteral("aps"), aps },
            });
        } else if (type == k_typeEthernet) {
            // Virtual interfaces (veth, bridge, tun) have no physical device behind them
            if (!QFileInfo::exists(QStringLiteral("/sys/class/net/%1/device").arg(iface)))
                continue;
            ethernetDevices.append(QVariantMap{
                { QStringLiteral("iface"), iface },
                { QStringLiteral("state"), deviceStateName(state) },
                { QStringLiteral("connection"), connection },
                { QStringLiteral("connected"), state == k_deviceActivated },
            });
        }
    }
    out.insert(QStringLiteral("wifiDevices"), wifiDevices);
    out.insert(QStringLiteral("ethernetDevices"), ethernetDevices);

    QVariantList saved;
    const auto profiles = pathList(callMethod(k_settingsPath, k_settingsIface, QStringLiteral("ListConnections")));
    for (const auto& profile : profiles) {
        const auto settings = settingsOf(profile);
        const auto conn = settings.value(QStringLiteral("connection")).toMap();
        const auto wireless = settings.value(QStringLiteral("802-11-wireless")).toMap();
        const auto security = settings.value(QStringLiteral("802-11-wireless-security")).toMap();
        saved.append(QVariantMap{
            { QStringLiteral("id"), conn.value(QStringLiteral("id")).toString() },
            { QStringLiteral("uuid"), conn.value(QStringLiteral("uuid")).toString() },
            { QStringLiteral("type"), conn.value(QStringLiteral("type")).toString() },
            { QStringLiteral("ssid"), ssidOf(wireless.value(QStringLiteral("ssid"))) },
            { QStringLiteral("keyMgmt"), security.value(QStringLiteral("key-mgmt")).toString() },
            { QStringLiteral("autoconnect"), conn.value(QStringLiteral("autoconnect"), true).toBool() },
        });
    }
    out.insert(QStringLiteral("savedConnections"), saved);
    return out;
}

QVariantMap NetworkDbus::deviceDetails(const QString& iface) {
    QVariantMap out;
    const auto devices = pathList(getAll(k_root, k_nmIface).value(QStringLiteral("AllDevices")));
    for (const auto& devicePath : devices) {
        const auto dev = getAll(devicePath, k_deviceIface);
        if (dev.value(QStringLiteral("Interface")).toString() != iface)
            continue;

        out.insert(QStringLiteral("mac"), dev.value(QStringLiteral("HwAddress")).toString());
        const auto ip4Path = pathOf(dev.value(QStringLiteral("Ip4Config")));
        if (ip4Path.length() <= 1)
            break;

        const auto ip4 = getAll(ip4Path, k_ip4Iface);
        const auto addresses = mapList(ip4.value(QStringLiteral("AddressData")));
        if (!addresses.isEmpty()) {
            out.insert(QStringLiteral("ip"), addresses.first().value(QStringLiteral("address")).toString());
            out.insert(QStringLiteral("prefix"), addresses.first().value(QStringLiteral("prefix")).toInt());
        }
        out.insert(QStringLiteral("gateway"), ip4.value(QStringLiteral("Gateway")).toString());

        QStringList dns;
        for (const auto& server : mapList(ip4.value(QStringLiteral("NameserverData"))))
            dns << server.value(QStringLiteral("address")).toString();
        out.insert(QStringLiteral("dns"), dns);
        break;
    }
    return out;
}

void NetworkDbus::requestScan(const QString& iface) {
    const auto devices = pathList(getAll(k_root, k_nmIface).value(QStringLiteral("AllDevices")));
    for (const auto& devicePath : devices) {
        if (getAll(devicePath, k_deviceIface).value(QStringLiteral("Interface")).toString() == iface) {
            callMethod(devicePath, k_wirelessIface, QStringLiteral("RequestScan"), { QVariantMap{} });
            return;
        }
    }
}

void NetworkDbus::setWifiEnabled(bool enabled) {
    const auto bus = QDBusConnection::systemBus();
    auto msg = QDBusMessage::createMethodCall(k_service, k_root, k_propsIface, QStringLiteral("Set"));
    msg.setArguments({ k_nmIface, QStringLiteral("WirelessEnabled"), QVariant::fromValue(QDBusVariant(enabled)) });
    const QDBusMessage reply = bus.call(msg);
    if (reply.type() == QDBusMessage::ErrorMessage)
        qCWarning(lcNetworkDbus) << "setWifiEnabled failed:" << reply.errorMessage();
}

QString NetworkDbus::profilePath(const QString& connectionId) {
    const auto profiles = pathList(callMethod(k_settingsPath, k_settingsIface, QStringLiteral("ListConnections")));
    for (const auto& profile : profiles) {
        if (settingsOf(profile).value(QStringLiteral("connection")).toMap().value(QStringLiteral("id")).toString() ==
            connectionId)
            return profile;
    }
    return {};
}

QString NetworkDbus::devicePathFor(const QString& iface, const QString& connectionType) {
    const auto devices = pathList(getAll(k_root, k_nmIface).value(QStringLiteral("AllDevices")));
    for (const auto& devicePath : devices) {
        const auto dev = getAll(devicePath, k_deviceIface);
        const auto name = dev.value(QStringLiteral("Interface")).toString();
        const uint type = dev.value(QStringLiteral("DeviceType")).toUInt();
        bool match = false;
        if (!iface.isEmpty()) {
            match = name == iface;
        } else if (connectionType == QStringLiteral("802-11-wireless")) {
            match = type == k_typeWifi;
        } else if (connectionType == QStringLiteral("802-3-ethernet")) {
            match = type == k_typeEthernet;
        }
        if (match)
            return devicePath;
    }
    return QStringLiteral("/");
}

// Calls back once the active connection settles: activated (success), deactivated (failure, with the
// device's reason when it has one), or timed out. NetworkManager's "no secrets" reason means the
// network needs a password.
void NetworkDbus::watchActivation(const QString& activePath, const QJSValue& callback) const {
    struct Watch {
        QTimer timer;
        int elapsedMs = 0;
    };

    auto* watch = new Watch;
    watch->timer.setInterval(250);
    QObject::connect(&watch->timer, &QTimer::timeout, this, [watch, activePath, callback, this] {
        watch->elapsedMs += 250;
        const uint state = getAll(activePath, k_activeIface).value(QStringLiteral("State")).toUInt();
        const bool success = state == 2; // NM_ACTIVE_CONNECTION_STATE_ACTIVATED
        const bool failed = state == 4;  // NM_ACTIVE_CONNECTION_STATE_DEACTIVATED
        const bool timedOut = watch->elapsedMs >= 30000;
        if (!success && !failed && !timedOut)
            return;

        uint reasonCode = 0;
        const auto devices = pathList(getAll(activePath, k_activeIface).value(QStringLiteral("Devices")));
        if (!devices.isEmpty()) {
            const auto reason = getAll(devices.first(), k_deviceIface).value(QStringLiteral("StateReason"));
            if (reason.canConvert<QDBusArgument>()) {
                const auto arg = reason.value<QDBusArgument>();
                arg.beginStructure();
                uint ignored = 0;
                arg >> ignored >> reasonCode;
                arg.endStructure();
            }
        }

        watch->timer.stop();
        if (callback.isCallable() && qjsEngine(this)) {
            auto result = qjsEngine(this)->newObject();
            result.setProperty(QStringLiteral("success"), success);
            QString error;
            if (timedOut)
                error = QStringLiteral("Timed out");
            else if (!success)
                error = QStringLiteral("Connection failed (reason %1)").arg(reasonCode);
            result.setProperty(QStringLiteral("error"), error);
            result.setProperty(QStringLiteral("needsPassword"), !success && reasonCode == 7); // NO_SECRETS
            result.setProperty(QStringLiteral("output"), QString());
            result.setProperty(QStringLiteral("exitCode"), success ? 0 : 1);
            callback.call({ result });
        }
        delete watch;
    });
    watch->timer.start();
}

void NetworkDbus::activate(const QString& connectionId, const QString& iface, const QJSValue& callback) {
    const auto profile = profilePath(connectionId);
    if (profile.isEmpty()) {
        qCWarning(lcNetworkDbus) << "activate: no profile named" << connectionId;
        return;
    }
    const auto type =
        settingsOf(profile).value(QStringLiteral("connection")).toMap().value(QStringLiteral("type")).toString();
    // Virtual profiles (dummy, VPN, ...) have no device until they're up, so "/" lets NetworkManager pick
    const auto devicePath = devicePathFor(iface, type);
    const auto bus = QDBusConnection::systemBus();
    auto msg = QDBusMessage::createMethodCall(k_service, k_root, k_nmIface, QStringLiteral("ActivateConnection"));
    msg.setArguments({
        QVariant::fromValue(QDBusObjectPath(profile)),
        QVariant::fromValue(QDBusObjectPath(devicePath)),
        QVariant::fromValue(QDBusObjectPath(QStringLiteral("/"))),
    });
    const QDBusMessage reply = bus.call(msg);
    const auto active = reply.type() == QDBusMessage::ReplyMessage ? pathOf(reply.arguments().value(0)) : QString();
    if (active.length() <= 1) {
        if (callback.isCallable() && qjsEngine(this)) {
            auto result = qjsEngine(this)->newObject();
            result.setProperty(QStringLiteral("success"), false);
            result.setProperty(QStringLiteral("error"), QStringLiteral("No device for %1").arg(connectionId));
            callback.call({ result });
        }
        return;
    }
    watchActivation(active, callback);
}

void NetworkDbus::deactivate(const QString& connectionId, const QString& iface, const QJSValue& callback) {
    const auto devices = pathList(getAll(k_root, k_nmIface).value(QStringLiteral("AllDevices")));
    for (const auto& devicePath : devices) {
        const auto dev = getAll(devicePath, k_deviceIface);
        const auto name = dev.value(QStringLiteral("Interface")).toString();
        if (!iface.isEmpty() && name != iface)
            continue;
        const auto activePath = pathOf(dev.value(QStringLiteral("ActiveConnection")));
        if (activePath.length() <= 1)
            continue;
        if (!connectionId.isEmpty() &&
            getAll(activePath, k_activeIface).value(QStringLiteral("Id")).toString() != connectionId)
            continue;

        callMethod(k_root, k_nmIface, QStringLiteral("DeactivateConnection"),
            { QVariant::fromValue(QDBusObjectPath(activePath)) });
        if (callback.isCallable() && qjsEngine(this)) {
            auto result = qjsEngine(this)->newObject();
            result.setProperty(QStringLiteral("success"), true);
            result.setProperty(QStringLiteral("error"), QString());
            result.setProperty(QStringLiteral("needsPassword"), false);
            result.setProperty(QStringLiteral("output"), QString());
            result.setProperty(QStringLiteral("exitCode"), 0);
            callback.call({ result });
        }
        return;
    }
}

void NetworkDbus::connectWifi(const QString& ssid, const QString& bssid, const QString& password, bool hidden,
    const QString& keyMgmt, const QJSValue& callback) {
    // A new profile replaces the old one with the same name, as before
    forget(ssid, QJSValue());

    const auto devicePath = devicePathFor(QString(), QStringLiteral("802-11-wireless"));
    if (devicePath == QStringLiteral("/")) {
        qCWarning(lcNetworkDbus) << "connectWifi: no Wi-Fi device";
        return;
    }

    QString apPath = QStringLiteral("/");
    if (!bssid.isEmpty()) {
        const auto wifi = getAll(devicePath, k_wirelessIface);
        for (const auto& candidate : pathList(wifi.value(QStringLiteral("AccessPoints")))) {
            if (getAll(candidate, k_apIface)
                    .value(QStringLiteral("HwAddress"))
                    .toString()
                    .compare(bssid, Qt::CaseInsensitive) == 0) {
                apPath = candidate;
                break;
            }
        }
    }

    const auto settings = wifiSettings(ssid, bssid, password, hidden, keyMgmt);
    const auto bus = QDBusConnection::systemBus();
    auto msg = QDBusMessage::createMethodCall(k_service, k_root, k_nmIface, QStringLiteral("AddAndActivateConnection"));
    msg.setArguments({
        QVariant::fromValue(settings),
        QVariant::fromValue(QDBusObjectPath(devicePath)),
        QVariant::fromValue(QDBusObjectPath(apPath)),
    });
    const QDBusMessage reply = bus.call(msg);
    if (reply.type() == QDBusMessage::ErrorMessage) {
        qCWarning(lcNetworkDbus) << "connectWifi failed:" << reply.errorMessage();
        return;
    }
    // AddAndActivateConnection returns (profile, active connection)
    watchActivation(pathOf(reply.arguments().value(1)), callback);
}

void NetworkDbus::forget(const QString& connectionId, const QJSValue& callback) {
    const auto profiles = pathList(callMethod(k_settingsPath, k_settingsIface, QStringLiteral("ListConnections")));
    int removed = 0;
    for (const auto& profile : profiles) {
        if (settingsOf(profile).value(QStringLiteral("connection")).toMap().value(QStringLiteral("id")).toString() !=
            connectionId)
            continue;
        callMethod(profile, k_connectionIface, QStringLiteral("Delete"));
        ++removed;
    }
    if (callback.isCallable() && qjsEngine(this)) {
        auto result = qjsEngine(this)->newObject();
        result.setProperty(QStringLiteral("success"), removed > 0);
        result.setProperty(QStringLiteral("error"),
            removed > 0 ? QString() : QStringLiteral("No saved profile named %1").arg(connectionId));
        result.setProperty(QStringLiteral("output"), QString());
        result.setProperty(QStringLiteral("exitCode"), removed > 0 ? 0 : 1);
        callback.call({ result });
    }
}

bool NetworkDbus::autoconnect(const QString& connectionId) {
    const auto profile = profilePath(connectionId);
    if (profile.isEmpty())
        return false;
    return settingsOf(profile)
        .value(QStringLiteral("connection"))
        .toMap()
        .value(QStringLiteral("autoconnect"), true)
        .toBool();
}

bool NetworkDbus::setAutoconnect(const QString& connectionId, bool enabled) {
    const auto profile = profilePath(connectionId);
    if (profile.isEmpty())
        return false;

    auto settings = settingsOf(profile);
    auto connection = settings.value(QStringLiteral("connection")).toMap();
    connection.insert(QStringLiteral("autoconnect"), enabled);
    settings.insert(QStringLiteral("connection"), connection);

    if (settings.contains(QStringLiteral("802-11-wireless-security"))) {
        auto security = settings.value(QStringLiteral("802-11-wireless-security")).toMap();
        if (enabled) {
            // psk-flags 0: the next password is stored with the profile
            security.insert(QStringLiteral("psk-flags"), 0u);
        } else {
            // psk-flags 2: the secret isn't stored, so NetworkManager asks for it on the next connect
            security.insert(QStringLiteral("psk-flags"), 2u);
            security.insert(QStringLiteral("psk"), QString());
        }
        settings.insert(QStringLiteral("802-11-wireless-security"), security);
    }

    QMap<QString, QVariantMap> update;
    for (auto it = settings.constBegin(); it != settings.constEnd(); ++it)
        update.insert(it.key(), it.value().toMap());
    return callOk(profile, k_connectionIface, QStringLiteral("Update"), { QVariant::fromValue(update) });
}

void NetworkDbus::connectDevice(const QString& iface, const QJSValue& callback) {
    // "/" as the profile lets NetworkManager choose the one that fits the device
    const auto devicePath = devicePathFor(iface, QString());
    const auto active = callMethod(k_root, k_nmIface, QStringLiteral("ActivateConnection"),
        {
            QVariant::fromValue(QDBusObjectPath(QStringLiteral("/"))),
            QVariant::fromValue(QDBusObjectPath(devicePath)),
            QVariant::fromValue(QDBusObjectPath(QStringLiteral("/"))),
        });
    const auto activePath = pathOf(active);
    if (devicePath == QStringLiteral("/") || activePath.length() <= 1) {
        if (callback.isCallable() && qjsEngine(this)) {
            auto result = qjsEngine(this)->newObject();
            result.setProperty(QStringLiteral("success"), false);
            result.setProperty(QStringLiteral("error"), QStringLiteral("Could not bring up %1").arg(iface));
            callback.call({ result });
        }
        return;
    }
    watchActivation(activePath, callback);
}

QVariantMap NetworkDbus::ipv4Config(const QString& connectionId) {
    const auto profile = profilePath(connectionId);
    if (profile.isEmpty())
        return {};

    const auto settings = settingsOf(profile);
    const auto ipv4 = settings.value(QStringLiteral("ipv4")).toMap();
    const auto conn = settings.value(QStringLiteral("connection")).toMap();

    QString address;
    const auto addresses = mapList(ipv4.value(QStringLiteral("address-data")));
    if (!addresses.isEmpty())
        address = QStringLiteral("%1/%2")
                      .arg(addresses.first().value(QStringLiteral("address")).toString())
                      .arg(addresses.first().value(QStringLiteral("prefix")).toUInt());

    const auto dns = ipv4.value(QStringLiteral("dns-data")).toStringList();
    const auto ignoreAutoDns = ipv4.value(QStringLiteral("ignore-auto-dns")).toBool();

    QString method = ipv4.value(QStringLiteral("method"), QStringLiteral("auto")).toString();
    if (method == QStringLiteral("auto") && ignoreAutoDns)
        method = QStringLiteral("auto-dns");

    return QVariantMap{
        { QStringLiteral("method"), method },
        { QStringLiteral("address"), address },
        { QStringLiteral("gateway"), ipv4.value(QStringLiteral("gateway")).toString() },
        { QStringLiteral("dns"), dns },
        { QStringLiteral("ignoreAutoDns"), ignoreAutoDns },
        { QStringLiteral("autoconnect"), conn.value(QStringLiteral("autoconnect"), true).toBool() },
    };
}

bool NetworkDbus::setIpv4Config(const QString& connectionId, const QVariantMap& config) {
    const auto profile = profilePath(connectionId);
    if (profile.isEmpty())
        return false;

    auto settings = settingsOf(profile);
    auto ipv4 = settings.value(QStringLiteral("ipv4")).toMap();
    const auto method = config.value(QStringLiteral("method"), QStringLiteral("auto")).toString();
    const auto dns = config.value(QStringLiteral("dns")).toStringList();

    if (method == QStringLiteral("manual")) {
        const auto address = config.value(QStringLiteral("address")).toString().split(QLatin1Char('/'));
        const auto prefix = address.size() > 1 ? address.at(1).toUInt() : 24u;
        ipv4.insert(QStringLiteral("method"), QStringLiteral("manual"));
        ipv4.insert(QStringLiteral("address-data"), QVariant::fromValue(QList<QVariantMap>{
                                                        QVariantMap{
                                                            { QStringLiteral("address"), address.value(0) },
                                                            { QStringLiteral("prefix"), prefix },
                                                        },
                                                    }));
        const auto gateway = config.value(QStringLiteral("gateway")).toString();
        if (gateway.isEmpty())
            ipv4.remove(QStringLiteral("gateway"));
        else
            ipv4.insert(QStringLiteral("gateway"), gateway);
        ipv4.insert(QStringLiteral("ignore-auto-dns"), true);
    } else {
        // DHCP addressing; "auto-dns" keeps the custom DNS below, plain "auto" uses the DHCP ones
        ipv4.insert(QStringLiteral("method"), QStringLiteral("auto"));
        ipv4.remove(QStringLiteral("address-data"));
        ipv4.remove(QStringLiteral("gateway"));
        ipv4.insert(QStringLiteral("ignore-auto-dns"), method == QStringLiteral("auto-dns"));
    }

    if (dns.isEmpty())
        ipv4.remove(QStringLiteral("dns-data"));
    else
        ipv4.insert(QStringLiteral("dns-data"), dns);

    // The legacy keys (addresses, dns) come back from GetSettings too; NetworkManager refuses an
    // update that carries them next to the address-data/dns-data it is given
    ipv4.remove(QStringLiteral("addresses"));
    ipv4.remove(QStringLiteral("dns"));

    settings.insert(QStringLiteral("ipv4"), ipv4);
    QMap<QString, QVariantMap> update;
    for (auto it = settings.constBegin(); it != settings.constEnd(); ++it)
        update.insert(it.key(), it.value().toMap());
    return callOk(profile, k_connectionIface, QStringLiteral("Update"), { QVariant::fromValue(update) });
}

} // namespace caelestia::services
