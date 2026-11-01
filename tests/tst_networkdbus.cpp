#include <qtest.h>

#include "Services/networkdbus.hpp"

using caelestia::services::NetworkDbus;

class TestNetworkDbus : public QObject {
    Q_OBJECT

private slots:

    void snapshotHasEveryKey() {
        NetworkDbus network;
        const auto snap = network.snapshot();
        QVERIFY(snap.value(QStringLiteral("available")).toBool());
        QVERIFY(snap.contains(QStringLiteral("wifiEnabled")));
        QVERIFY(snap.contains(QStringLiteral("wifiDevices")));
        QVERIFY(snap.contains(QStringLiteral("ethernetDevices")));
        QVERIFY(snap.contains(QStringLiteral("savedConnections")));
    }

    void unknownDeviceHasNoDetails() { QVERIFY(NetworkDbus::deviceDetails(QStringLiteral("no-such-iface")).isEmpty()); }

    void unknownProfileIsNotAutoconnect() {
        QVERIFY(!NetworkDbus::autoconnect(QStringLiteral("no-such-profile")));
        QVERIFY(!NetworkDbus::setAutoconnect(QStringLiteral("no-such-profile"), true));
    }

    void unknownProfileHasNoIpv4() { QVERIFY(NetworkDbus::ipv4Config(QStringLiteral("no-such-profile")).isEmpty()); }
};

QTEST_GUILESS_MAIN(TestNetworkDbus)
#include "tst_networkdbus.moc"
