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

namespace caelestia::services {

// A saved connection profile, as stored by NetworkManager.
//
// Each profile reads itself and subscribes to its own object, so editing one
// doesn't cost a walk over all of them.
class NmConnection : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("NmConnection instances are owned by NetworkProfiles")

    // Profile name, i.e. what nmcli takes as a connection argument.
    Q_PROPERTY(QString id READ id NOTIFY changed)
    Q_PROPERTY(QString uuid READ uuid NOTIFY changed)
    // NetworkManager's setting name, e.g. "802-11-wireless" or "802-3-ethernet".
    Q_PROPERTY(QString type READ type NOTIFY changed)
    // Wifi profiles only; empty for everything else.
    Q_PROPERTY(QString ssid READ ssid NOTIFY changed)
    // Raw key management, e.g. "wpa-psk" or "sae". Empty on an open network.
    Q_PROPERTY(QString keyMgmt READ keyMgmt NOTIFY changed)
    Q_PROPERTY(bool autoconnect READ autoconnect NOTIFY changed)

public:
    explicit NmConnection(QString path, QObject* parent = nullptr);

    [[nodiscard]] QString path() const;
    [[nodiscard]] QString id() const;
    [[nodiscard]] QString uuid() const;
    [[nodiscard]] QString type() const;
    [[nodiscard]] QString ssid() const;
    [[nodiscard]] QString keyMgmt() const;
    [[nodiscard]] bool autoconnect() const;

    // Applies the nested settings map GetSettings returns.
    void update(const QMap<QString, QVariantMap>& settings);

    // Subscribes to this profile's own object on the system bus.
    void watch();

signals:
    void changed();
    // Raised when NetworkManager reports the profile was edited, so the owner
    // can read it again.
    void needsReread();

private slots:
    void handleUpdated();

private:
    QString m_path;
    QString m_id;
    QString m_uuid;
    QString m_type;
    QString m_ssid;
    QString m_keyMgmt;
    bool m_autoconnect = true;
};

// NetworkManager's saved profiles, read over D-Bus.
//
// This replaces parsing `nmcli connection show` and then spawning a further
// nmcli per wifi profile just to read its SSID: one GetSettings call per
// profile returns everything at once, and they run in parallel. Actions -
// adding, deleting, toggling autoconnect - stay on the CLI, where there's
// nothing to parse and nothing to gain from moving them.
class NetworkProfiles : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // False until a full snapshot has been read, so consumers can hold their
    // previous behaviour rather than acting on an empty list.
    Q_PROPERTY(bool ready READ ready NOTIFY changed)
    Q_PROPERTY(QQmlListProperty<caelestia::services::NmConnection> profiles READ profiles NOTIFY profilesChanged)

public:
    explicit NetworkProfiles(QObject* parent = nullptr);

    [[nodiscard]] bool ready() const;
    [[nodiscard]] QQmlListProperty<NmConnection> profiles();

signals:
    void changed();
    void profilesChanged();

private slots:
    void handlePropertiesChanged(const QString& iface, const QVariantMap& properties, const QStringList& invalidated);
    void handleNameOwnerChanged(const QString& name, const QString& oldOwner, const QString& newOwner);

private:
    // One walk at a time, with a flag to run again after. Bursts of signals
    // would otherwise each start their own and land out of order.
    void scheduleRefresh();
    void refresh();
    void readSettings();
    void readProfile(const QString& path);
    void step(int delta);
    void finish();

    void watchObject(const QString& path);
    void clearProfiles();

    [[nodiscard]] static std::optional<QDBusConnection> systemBus();

    bool m_ready = false;

    QList<NmConnection*> m_profiles;
    QHash<QString, NmConnection*> m_byPath;
    // Paths seen by the walk in progress; anything missing afterwards has gone.
    QSet<QString> m_seen;

    bool m_refreshing = false;
    bool m_refreshQueued = false;
    int m_pending = 0;
    bool m_listChanged = false;

    QSet<QString> m_watched;
};

} // namespace caelestia::services
