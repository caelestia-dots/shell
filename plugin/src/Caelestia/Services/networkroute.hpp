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

// Which kind of link the system is actually routing through, read from
// NetworkManager rather than reconstructed from the routing table.
//
// "Is a cable plugged in" and "is traffic going over it" are different
// questions, and the routing table alone can't answer the second one either:
// a VPN owns the default route while the traffic underneath it still leaves
// over ethernet or wifi. NetworkManager already tracks this - the primary
// connection, and which active connection holds the v4 and v6 defaults - so
// this follows those to their devices and classifies them by device type.
class NetworkRoute : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // False until a full snapshot has been read; consumers should keep their
    // previous behaviour until then rather than acting on empty state.
    Q_PROPERTY(bool ready READ ready NOTIFY changed)
    Q_PROPERTY(caelestia::config::NetworkTransport::Enum primaryTransport READ primaryTransport NOTIFY changed)
    Q_PROPERTY(caelestia::config::NetworkTransport::Enum ipv4Transport READ ipv4Transport NOTIFY changed)
    Q_PROPERTY(caelestia::config::NetworkTransport::Enum ipv6Transport READ ipv6Transport NOTIFY changed)
    // True when v4 and v6 both have a default and they're on different kinds
    // of link, so a UI showing a single icon can tell it's simplifying.
    Q_PROPERTY(bool mixed READ mixed NOTIFY changed)
    Q_PROPERTY(QString primaryInterface READ primaryInterface NOTIFY changed)

public:
    explicit NetworkRoute(QObject* parent = nullptr);

    [[nodiscard]] bool ready() const;
    [[nodiscard]] Transport primaryTransport() const;
    [[nodiscard]] Transport ipv4Transport() const;
    [[nodiscard]] Transport ipv6Transport() const;
    [[nodiscard]] bool mixed() const;
    [[nodiscard]] QString primaryInterface() const;

signals:
    void changed();

private slots:
    void handlePropertiesChanged(const QString& iface, const QVariantMap& properties, const QStringList& invalidated);
    void handleNameOwnerChanged(const QString& name, const QString& oldOwner, const QString& newOwner);

private:
    struct Snapshot {
        Transport primary = Transport::None;
        Transport ipv4 = Transport::None;
        Transport ipv6 = Transport::None;
        QString primaryInterface;

        bool operator==(const Snapshot& o) const noexcept;
    };

    // One refresh at a time, with a flag to run again afterwards. Bursts of
    // NetworkManager signals would otherwise each start their own walk of the
    // object tree and land out of order.
    void scheduleRefresh();
    void refresh();
    void finishRefresh(const Snapshot& snapshot);

    void readManager();
    void readActiveConnection(const QString& path, bool isPrimary);
    void readDevice(const QString& connPath, const QString& devicePath);
    void step(int delta);

    void watchObject(const QString& path);

    [[nodiscard]] static std::optional<QDBusConnection> systemBus();
    [[nodiscard]] static Transport transportForDeviceType(uint deviceType);

    bool m_ready = false;
    Snapshot m_current;

    bool m_refreshing = false;
    bool m_refreshQueued = false;
    int m_pending = 0;

    // State being assembled by the in-flight refresh.
    Snapshot m_building;
    QString m_primaryConnection;
    QHash<QString, bool> m_connIsDefault4;
    QHash<QString, bool> m_connIsDefault6;
    QHash<QString, Transport> m_connTransport;
    QHash<QString, QString> m_connInterface;
    QSet<QString> m_watched;
};

} // namespace caelestia::services
