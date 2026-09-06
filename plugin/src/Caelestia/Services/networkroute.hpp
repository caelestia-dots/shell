#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

#include "config/enums.hpp"
#include "networkwalker.hpp"

namespace caelestia::services {

using Transport = config::NetworkTransport::Enum;

// Which kind of link the system is actually routing through, read from
// NetworkManager rather than reconstructed from the routing table.
//
// "Is a cable plugged in" and "is traffic going over it" are different
// questions, and the routing table alone can't answer the second one either:
// a VPN owns the default route while the traffic underneath it still leaves
// over ethernet or wifi. NetworkManager already tracks this as its primary
// connection, so this follows that to its device and classifies it by type.
class NetworkRoute : public NmWalker {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(caelestia::config::NetworkTransport::Enum primaryTransport READ primaryTransport NOTIFY changed)

public:
    explicit NetworkRoute(QObject* parent = nullptr);

    [[nodiscard]] Transport primaryTransport() const;

protected:
    void readRoot() override;
    [[nodiscard]] bool triggersRefresh(const QString& iface) const override;
    void publish() override;
    void clearItems() override;

private:
    void readActiveConnection(const QString& path);
    void readDevice(const QString& devicePath);

    [[nodiscard]] static Transport transportForDeviceType(uint deviceType);

    Transport m_primary = config::NetworkTransport::None;
    // What the walk in progress has worked out so far.
    Transport m_building = config::NetworkTransport::None;
};

} // namespace caelestia::services
