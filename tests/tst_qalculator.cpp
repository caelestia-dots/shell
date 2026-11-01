#include <qsignalspy.h>
#include <qtest.h>

#include "qalculator.hpp"

using caelestia::Qalculator;

class TestQalculator : public QObject {
    Q_OBJECT

private slots:

    void syncEval() {
        QCOMPARE(Qalculator::eval(QStringLiteral("2 + 2"), false), QStringLiteral("4"));
        QCOMPARE(Qalculator::eval(QStringLiteral("2 + 2")), QStringLiteral("2 + 2 = 4"));
        QVERIFY(Qalculator::eval({}).isEmpty());
    }

    void asyncEvalIsNonBlockingAndLatestWins() {
        Qalculator calc;
        QSignalSpy busy(&calc, &Qalculator::busyChanged);

        // Only the last of several quick requests may set the result
        calc.evalAsync(QStringLiteral("1 + 1"));
        calc.evalAsync(QStringLiteral("10 * 10"));
        QVERIFY(calc.busy());

        QTRY_VERIFY(!calc.busy());
        QCOMPARE(calc.rawResult(), QStringLiteral("100"));
    }

    void errorsAreReported() {
        Qalculator calc;
        calc.evalAsync(QStringLiteral("1 +* 2 )"));
        QTRY_VERIFY(!calc.busy());
        QVERIFY(!calc.result().isEmpty());
    }

    void emptyClears() {
        Qalculator calc;
        calc.evalAsync(QStringLiteral("3 * 3"));
        QTRY_VERIFY(!calc.busy());
        calc.evalAsync({});
        QVERIFY(calc.result().isEmpty());
        QVERIFY(!calc.busy());
    }
};

QTEST_GUILESS_MAIN(TestQalculator)
#include "tst_qalculator.moc"
