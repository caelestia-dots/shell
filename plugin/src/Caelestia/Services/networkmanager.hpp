#pragma once

#include <qdbusconnection.h>
#include <qhash.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qqmllist.h>
#include <qset.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

#include <optional>

#include "config/enums.hpp"

namespace caelestia::services {

using Transport = config::NetworkTransport::Enum;

// A wifi access point as NetworkManager sees it.
//
// Each one subscribes to its own D-Bus object. Signal strength changes
// constantly, and routing every one of those through a full device walk would
// cost far more than the update is worth.
class NmAccessPoint : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("NmAccessPoint instances are owned by NetworkManager")

    Q_PROPERTY(QString ssid READ ssid NOTIFY changed)
    Q_PROPERTY(QString bssid READ bssid NOTIFY changed)
    // Signal strength as a percentage.
    Q_PROPERTY(int strength READ strength NOTIFY changed)
    // Frequency in MHz.
    Q_PROPERTY(int frequency READ frequency NOTIFY changed)
    // Security label in the same shape nmcli printed, e.g. "WPA2" or "WPA1
    // WPA2", empty on an open network.
    Q_PROPERTY(QString security READ security NOTIFY changed)
    Q_PROPERTY(bool isSecure READ isSecure NOTIFY changed)
    // Whether this is the access point the device is currently associated with.
    Q_PROPERTY(bool active READ active NOTIFY changed)

public:
    explicit NmAccessPoint(QString path, QObject* parent = nullptr);

    [[nodiscard]] QString path() const;
    [[nodiscard]] QString ssid() const;
    [[nodiscard]] QString bssid() const;
    [[nodiscard]] int strength() const;
    [[nodiscard]] int frequency() const;
    [[nodiscard]] QString security() const;
    [[nodiscard]] bool isSecure() const;
    [[nodiscard]] bool active() const;

    // Merges a property map, which may be a full snapshot or just the keys a
    // PropertiesChanged signal carried.
    void update(const QVariantMap& props);
    // Set apart from update(): which access point is active is a property of
    // the device, not of the access point.
    void setActive(bool active);

    // Subscribes to this access point's own object on the system bus.
    void watch();

signals:
    void changed();

private slots:
    void handlePropertiesChanged(const QString& iface, const QVariantMap& properties, const QStringList& invalidated);

private:
    QString m_path;
    QString m_ssid;
    QString m_bssid;
    int m_strength = 0;
    int m_frequency = 0;
    uint m_flags = 0;
    uint m_wpaFlags = 0;
    uint m_rsnFlags = 0;
    bool m_active = false;
};

// A network device as NetworkManager sees it.
//
// Held as an object rather than a plain value so consumers can bind to it and
// have their bindings re-run when NetworkManager reports a change, instead of
// the list being replaced wholesale on every refresh.
class NmDevice : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("NmDevice instances are owned by NetworkManager")

    Q_PROPERTY(QString interface READ interface NOTIFY changed)
    // Alias for `interface`. QML consumers have always called this `iface`, and
    // aliasing here is cheaper than renaming it at every use site.
    Q_PROPERTY(QString iface READ interface NOTIFY changed)
    Q_PROPERTY(caelestia::config::NetworkTransport::Enum type READ type NOTIFY changed)
    Q_PROPERTY(uint state READ state NOTIFY changed)
    // Whether the device has finished activating, i.e. NM state 100.
    Q_PROPERTY(bool connected READ connected NOTIFY changed)
    // Name of the profile currently active on the device, empty when it's down.
    // This is what `nmcli device status` reported in its CONNECTION column.
    Q_PROPERTY(QString connection READ connection NOTIFY changed)
    // Only ever populated for wifi devices; empty for everything else.
    Q_PROPERTY(QQmlListProperty<caelestia::services::NmAccessPoint> accessPoints READ accessPoints NOTIFY
            accessPointsChanged)
    // Hardware address of the device, e.g. "00:1a:2b:3c:4d:5e".
    Q_PROPERTY(QString hwAddress READ hwAddress NOTIFY changed)
    // Active IPv4 configuration. Empty while the device is down.
    Q_PROPERTY(QString address READ address NOTIFY changed)
    // Prefix length of the address, e.g. 24, or 0 when there is none.
    Q_PROPERTY(int prefix READ prefix NOTIFY changed)
    Q_PROPERTY(QString gateway READ gateway NOTIFY changed)
    Q_PROPERTY(QStringList dns READ dns NOTIFY changed)
    // Boot time in milliseconds at which the device last finished a scan, or -1
    // if it never has. NetworkManager publishes no scanning flag, so this
    // moving is the only signal that a scan finished. Wifi devices only.
    Q_PROPERTY(qlonglong lastScan READ lastScan NOTIFY changed)

public:
    explicit NmDevice(QString path, QObject* parent = nullptr);

    [[nodiscard]] QString path() const;
    [[nodiscard]] QString interface() const;
    [[nodiscard]] Transport type() const;
    [[nodiscard]] uint state() const;
    [[nodiscard]] bool connected() const;
    [[nodiscard]] QString connection() const;

    [[nodiscard]] QQmlListProperty<NmAccessPoint> accessPoints();
    [[nodiscard]] qlonglong lastScan() const;
    [[nodiscard]] QString hwAddress() const;
    [[nodiscard]] QString address() const;
    [[nodiscard]] int prefix() const;
    [[nodiscard]] QString gateway() const;
    [[nodiscard]] QStringList dns() const;
    [[nodiscard]] NmAccessPoint* accessPoint(const QString& path) const;

    // Set apart from update(): the name lives on the device's active connection
    // object, which is a second read.
    void setConnection(const QString& connection);
    void setLastScan(qlonglong lastScan);
    // Set apart from update(): the addresses live on the device's Ip4Config
    // object, which is a second read.
    void setIp4Config(const QString& address, int prefix, const QString& gateway, const QStringList& dns);

    void addAccessPoint(NmAccessPoint* accessPoint);
    // Drops any access point whose path isn't in `keep`. Returns whether the
    // list changed.
    bool retainAccessPoints(const QSet<QString>& keep);

    // Applies a property map read from the device's D-Bus object, emitting
    // changed() only when something actually differs.
    void update(const QVariantMap& props);

signals:
    void changed();
    void accessPointsChanged();

private:
    QString m_path;
    QString m_interface;
    Transport m_type = config::NetworkTransport::None;
    uint m_state = 0;
    QString m_connection;
    qlonglong m_lastScan = -1;
    QString m_hwAddress;
    QString m_address;
    int m_prefix = 0;
    QString m_gateway;
    QStringList m_dns;

    QList<NmAccessPoint*> m_accessPoints;
    QHash<QString, NmAccessPoint*> m_apByPath;
};

// NetworkManager's device list, read over D-Bus.
//
// This replaces parsing `nmcli device status`: devices arrive as typed
// properties and NetworkManager signals when they change, so there's nothing
// to poll and no output format to depend on. Actions - connecting, forgetting,
// scanning - stay on the CLI, where there's nothing to parse and nothing to
// gain from moving them.
class NetworkManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // False until a full snapshot has been read, so consumers can hold their
    // previous behaviour rather than acting on an empty list.
    Q_PROPERTY(bool ready READ ready NOTIFY changed)
    Q_PROPERTY(QQmlListProperty<caelestia::services::NmDevice> devices READ devices NOTIFY devicesChanged)
    Q_PROPERTY(bool wirelessEnabled READ wirelessEnabled NOTIFY changed)

public:
    explicit NetworkManager(QObject* parent = nullptr);

    [[nodiscard]] bool ready() const;
    [[nodiscard]] QQmlListProperty<NmDevice> devices();
    [[nodiscard]] bool wirelessEnabled() const;

signals:
    void changed();
    void devicesChanged();

private slots:
    void handlePropertiesChanged(const QString& iface, const QVariantMap& properties, const QStringList& invalidated);
    void handleNameOwnerChanged(const QString& name, const QString& oldOwner, const QString& newOwner);

private:
    // One walk at a time, with a flag to run again after. Bursts of signals
    // would otherwise each start their own and land out of order.
    void scheduleRefresh();
    void refresh();
    void readManager();
    void readDevice(const QString& path);
    void readConnection(const QString& devicePath, const QString& connectionPath);
    void readWireless(const QString& devicePath);
    void readIp4Config(const QString& devicePath, const QString& configPath);
    void readAccessPoint(const QString& devicePath, const QString& accessPointPath);
    void step(int delta);
    void finish();

    void watchObject(const QString& path);
    void clearDevices();

    [[nodiscard]] static std::optional<QDBusConnection> systemBus();

    bool m_ready = false;
    bool m_wirelessEnabled = false;

    QList<NmDevice*> m_devices;
    QHash<QString, NmDevice*> m_byPath;
    // Paths seen by the walk in progress; anything missing afterwards has gone.
    QSet<QString> m_seen;

    bool m_refreshing = false;
    bool m_refreshQueued = false;
    int m_pending = 0;
    bool m_listChanged = false;

    QSet<QString> m_watched;
};

} // namespace caelestia::services
