#include <qtest.h>

#include "Services/ddc.hpp"

using caelestia::services::Ddc;

class TestDdc : public QObject {
    Q_OBJECT

private slots:

    void noDdcMonitorsOnLaptopPanel() {
        // The only display on the test machine is the built-in panel, which doesn't speak DDC/CI
        Ddc ddc;
        QVERIFY(ddc.monitors().isEmpty());
    }

    void unknownBusReadsNothing() {
        Ddc ddc;
        QVERIFY(ddc.brightness(255).isEmpty());
    }

    void setOnUnknownBusIsHarmless() {
        Ddc ddc;
        ddc.setBrightness(255, 50); // Runs on a worker thread and must not crash
        QTest::qWait(100);
    }
};

QTEST_GUILESS_MAIN(TestDdc)
#include "tst_ddc.moc"
