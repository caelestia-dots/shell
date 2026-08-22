#include "lockconfig.hpp"

#include <qjsonarray.h>
#include <qjsonobject.h>
#include <qtest.h>

#include <utility>

using namespace caelestia;
using namespace caelestia::config;

class TestConfig : public settings::ObjectNode {
    CONFIG_NODE(TestConfig, settings::ObjectNode)

    CONFIG_SUBOBJECT(LockConfig, lock)
};

class LockConfigTest : public QObject {
    Q_OBJECT

private:
    static QStringList command(const LockConfig* config, const QString& field);

private slots:
    void decodesValidHooks();
    void quarantinesInvalidHooks();
    void resetsHooksOnSubsequentSync();
    void retainsGlobalFallbackInOverlays();
};

QStringList LockConfigTest::command(const LockConfig* config, const QString& field) {
    return field == QStringLiteral("onSecure") ? config->onSecure() : config->onRelease();
}

void LockConfigTest::decodesValidHooks() {
    const QList<std::pair<QString, QStringList>> hooks{
        { QStringLiteral("onSecure"), { QStringLiteral("hook"), QStringLiteral("secure") } },
        { QStringLiteral("onRelease"), { QStringLiteral("hook"), QStringLiteral("release") } },
    };

    for (const auto& [field, expected] : hooks) {
        TestConfig config;
        auto* const lock = config.lock();
        QList<settings::Diagnostic> diagnostics;

        QVERIFY(lock->syncJson(QJsonObject{ { field, QJsonArray::fromStringList(expected) } }, diagnostics));
        QCOMPARE(command(lock, field), expected);
        QVERIFY(diagnostics.isEmpty());
        QVERIFY(!lock->quarantine());

        diagnostics.clear();
        QVERIFY(lock->syncJson(QJsonObject{ { field, QJsonArray{} } }, diagnostics));
        QCOMPARE(command(lock, field), QStringList());
        QVERIFY(diagnostics.isEmpty());
        QVERIFY(!lock->quarantine());
    }

    for (const auto& blank : { QStringList{ QStringLiteral("") }, QStringList{ QStringLiteral("   ") } }) {
        for (const auto& field : { QStringLiteral("onSecure"), QStringLiteral("onRelease") }) {
            TestConfig config;
            auto* const lock = config.lock();
            QList<settings::Diagnostic> diagnostics;

            QVERIFY(lock->syncJson(QJsonObject{ { field, QJsonArray::fromStringList(blank) } }, diagnostics));
            QCOMPARE(command(lock, field), blank);
            QVERIFY(diagnostics.isEmpty());
            QVERIFY(!lock->quarantine());
        }
    }
}

void LockConfigTest::quarantinesInvalidHooks() {
    const QList<QJsonValue> invalidValues{
        QJsonValue(QStringLiteral("hook")),
        QJsonValue(QJsonObject{}),
        QJsonValue(QJsonValue::Null),
        QJsonValue(QJsonArray{ QStringLiteral("hook"), QJsonValue(1) }),
    };

    for (const auto& field : { QStringLiteral("onSecure"), QStringLiteral("onRelease") }) {
        for (const auto& value : invalidValues) {
            TestConfig config;
            auto* const lock = config.lock();
            QList<settings::Diagnostic> diagnostics;

            QVERIFY(lock->syncJson(QJsonObject{ { field, value } }, diagnostics));
            QCOMPARE(command(lock, field), QStringList());
            QCOMPARE(diagnostics.size(), 1);
            QCOMPARE(diagnostics.constFirst().type, settings::DiagnosticType::TypeMismatch);
            QCOMPARE(diagnostics.constFirst().option, QStringLiteral("lock.%1").arg(field));
            QVERIFY(lock->quarantine());
            QCOMPARE(lock->toJson(false).toObject().value(field), value);
        }
    }
}

void LockConfigTest::resetsHooksOnSubsequentSync() {
    for (const auto& field : { QStringLiteral("onSecure"), QStringLiteral("onRelease") }) {
        TestConfig config;
        auto* const lock = config.lock();
        QList<settings::Diagnostic> diagnostics;

        const auto oldCommand = QStringList{ QStringLiteral("hook"), QStringLiteral("old") };
        const auto newCommand = QStringList{ QStringLiteral("hook"), QStringLiteral("new") };
        QVERIFY(lock->syncJson(QJsonObject{ { field, QJsonArray::fromStringList(oldCommand) } }, diagnostics));
        QCOMPARE(command(lock, field), oldCommand);

        diagnostics.clear();
        QVERIFY(lock->syncJson(QJsonObject{ { field, QJsonArray::fromStringList(newCommand) } }, diagnostics));
        QCOMPARE(command(lock, field), newCommand);

        diagnostics.clear();
        QVERIFY(lock->syncJson(QJsonObject{}, diagnostics));
        QCOMPARE(command(lock, field), QStringList());
        QVERIFY(diagnostics.isEmpty());

        diagnostics.clear();
        QVERIFY(lock->syncJson(QJsonObject{ { field, QJsonArray::fromStringList(oldCommand) } }, diagnostics));
        QCOMPARE(command(lock, field), oldCommand);

        diagnostics.clear();
        const auto malformed = QJsonObject{};
        QVERIFY(lock->syncJson(QJsonObject{ { field, malformed } }, diagnostics));
        QCOMPARE(command(lock, field), QStringList());
        QCOMPARE(diagnostics.size(), 1);
        QCOMPARE(diagnostics.constFirst().type, settings::DiagnosticType::TypeMismatch);
        QVERIFY(lock->quarantine());
        QCOMPARE(lock->toJson(false).toObject().value(field), QJsonValue(malformed));
    }
}

void LockConfigTest::retainsGlobalFallbackInOverlays() {
    for (const auto& field : { QStringLiteral("onSecure"), QStringLiteral("onRelease") }) {
        TestConfig global;
        auto* const globalLock = global.lock();
        const auto globalCommand = QStringList{ QStringLiteral("hook"), QStringLiteral("global") };
        QList<settings::Diagnostic> diagnostics;

        QVERIFY(globalLock->syncJson(QJsonObject{ { field, QJsonArray::fromStringList(globalCommand) } }, diagnostics));
        QVERIFY(diagnostics.isEmpty());

        TestConfig overlay(&global);
        auto* const overlayLock = overlay.lock();
        diagnostics.clear();
        const auto overlayValue = QJsonArray{ QStringLiteral("hook"), QStringLiteral("overlay") };
        QVERIFY(overlayLock->syncJson(QJsonObject{ { field, overlayValue } }, diagnostics));
        QCOMPARE(command(overlayLock, field), globalCommand);
        QCOMPARE(diagnostics.size(), 1);
        QCOMPARE(diagnostics.constFirst().type, settings::DiagnosticType::GlobalOption);
        QCOMPARE(diagnostics.constFirst().option, QStringLiteral("lock.%1").arg(field));
        QVERIFY(overlayLock->quarantine());
        QCOMPARE(overlayLock->toJson(false).toObject().value(field), QJsonValue(overlayValue));
    }
}

QTEST_APPLESS_MAIN(LockConfigTest)

#include "test_lockconfig.moc"
