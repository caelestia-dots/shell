#pragma once

#include <qhash.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qqmllist.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

#include <cstdint>

#include "networkwalker.hpp"

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
    // IPv4 configuration as saved on the profile, which is not the same thing
    // as what the device ended up with; that lives on NmDevice.
    Q_PROPERTY(QString ipv4Method READ ipv4Method NOTIFY changed)
    // First manual address in CIDR form, e.g. "192.168.1.5/24". Empty on auto.
    Q_PROPERTY(QString ipv4Address READ ipv4Address NOTIFY changed)
    Q_PROPERTY(QString ipv4Gateway READ ipv4Gateway NOTIFY changed)
    Q_PROPERTY(QStringList ipv4Dns READ ipv4Dns NOTIFY changed)
    Q_PROPERTY(bool ipv4IgnoreAutoDns READ ipv4IgnoreAutoDns NOTIFY changed)

public:
    explicit NmConnection(QString path, QObject* parent = nullptr);

    [[nodiscard]] QString path() const;
    [[nodiscard]] QString id() const;
    [[nodiscard]] QString uuid() const;
    [[nodiscard]] QString type() const;
    [[nodiscard]] QString ssid() const;
    [[nodiscard]] QString keyMgmt() const;
    [[nodiscard]] bool autoconnect() const;
    [[nodiscard]] QString ipv4Method() const;
    [[nodiscard]] QString ipv4Address() const;
    [[nodiscard]] QString ipv4Gateway() const;
    [[nodiscard]] QStringList ipv4Dns() const;
    [[nodiscard]] bool ipv4IgnoreAutoDns() const;

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
    QString m_ipv4Method;
    QString m_ipv4Address;
    QString m_ipv4Gateway;
    QStringList m_ipv4Dns;
    bool m_ipv4IgnoreAutoDns = false;
};

// NetworkManager's saved profiles, read over D-Bus.
//
// This replaces parsing `nmcli connection show` and then spawning a further
// nmcli per wifi profile just to read its SSID: one GetSettings call per
// profile returns everything at once, and they run in parallel. Actions -
// adding, deleting, toggling autoconnect - stay on the CLI, where there's
// nothing to parse and nothing to gain from moving them.
class NetworkProfiles : public NmWalker {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QQmlListProperty<caelestia::services::NmConnection> profiles READ profiles NOTIFY itemsChanged)

public:
    explicit NetworkProfiles(QObject* parent = nullptr);

    [[nodiscard]] QQmlListProperty<NmConnection> profiles();

protected:
    void readRoot() override;
    [[nodiscard]] bool triggersRefresh(const QString& iface) const override;
    void pruneUnseen() override;
    void clearItems() override;

private:
    // Whether the read belongs to a walk. A reread triggered by an edit does
    // not: it must stay out of the walk's pending count and seen set, or it
    // will drive the count to zero underneath a walk in progress and prune
    // profiles the walk hasn't reached yet.
    enum class Read : std::uint8_t {
        Walk,
        Detached
    };

    void readProfile(const QString& path, Read read);

    QList<NmConnection*> m_profiles;
    QHash<QString, NmConnection*> m_byPath;
};

} // namespace caelestia::services
