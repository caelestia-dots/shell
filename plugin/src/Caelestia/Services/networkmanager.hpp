#pragma once

#include <qdbusconnection.h>
#include <qhash.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qset.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

#include <optional>

#include "config/enums.hpp"

namespace caelestia::services {

using Transport = config::NetworkTransport::Enum;

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

public:
    explicit NmDevice(QString path, QObject* parent = nullptr);

    [[nodiscard]] QString path() const;
    [[nodiscard]] QString interface() const;
    [[nodiscard]] Transport type() const;
    [[nodiscard]] uint state() const;
    [[nodiscard]] bool connected() const;
    [[nodiscard]] QString connection() const;

    // Set apart from update(): the name lives on the device's active connection
    // object, which is a second read.
    void setConnection(const QString& connection);

    // Applies a property map read from the device's D-Bus object, emitting
    // changed() only when something actually differs.
    void update(const QVariantMap& props);

signals:
    void changed();

private:
    QString m_path;
    QString m_interface;
    Transport m_type = config::NetworkTransport::None;
    uint m_state = 0;
    QString m_connection;
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
    Q_PROPERTY(QList<caelestia::services::NmDevice*> devices READ devices NOTIFY devicesChanged)
    Q_PROPERTY(bool wirelessEnabled READ wirelessEnabled NOTIFY changed)

public:
    explicit NetworkManager(QObject* parent = nullptr);

    [[nodiscard]] bool ready() const;
    [[nodiscard]] QList<NmDevice*> devices() const;
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
