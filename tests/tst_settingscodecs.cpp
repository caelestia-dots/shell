#include <qjsonarray.h>
#include <qtest.h>

#include "Settings/codecs.hpp"

using caelestia::settings::ExpectedType;
using caelestia::settings::ValueCodec;

class TestSettingsCodecs : public QObject {
    Q_OBJECT

private slots:

    void boolIsStrict() {
        const auto* codec = ValueCodec::codecFor(QMetaType::fromType<bool>());
        QVERIFY(codec);
        QCOMPARE(codec->expected(), ExpectedType::Bool);

        const auto ok = codec->decode(true);
        QVERIFY(!ok.error);
        QCOMPARE(ok.value.toBool(), true);

        // 1 and "true" are not booleans
        QVERIFY(codec->decode(1).error);
        QVERIFY(codec->decode(QStringLiteral("true")).error);
    }

    void intRejectsReals() {
        const auto* codec = ValueCodec::codecFor(QMetaType::fromType<int>());
        QVERIFY(codec);

        const auto ok = codec->decode(42);
        QVERIFY(!ok.error);
        QCOMPARE(ok.value.toInt(), 42);

        QVERIFY(codec->decode(1.5).error);
        QVERIFY(codec->decode(QStringLiteral("42")).error);
        QVERIFY(codec->decode(1e12).error); // Out of int range
    }

    void realAcceptsIntegers() {
        const auto* codec = ValueCodec::codecFor(QMetaType::fromType<qreal>());
        QVERIFY(codec);

        const auto ok = codec->decode(3);
        QVERIFY(!ok.error);
        QCOMPARE(ok.value.toReal(), 3.0);
        QVERIFY(codec->decode(true).error);
    }

    void stringRoundTrip() {
        const auto* codec = ValueCodec::codecFor(QMetaType::fromType<QString>());
        QVERIFY(codec);

        const auto res = codec->decode(QStringLiteral("caelestia"));
        QVERIFY(!res.error);
        QCOMPARE(codec->encode(res.value).toString(), QStringLiteral("caelestia"));
        QVERIFY(codec->decode(0).error);
    }

    void listReportsFailingIndex() {
        const auto* codec = ValueCodec::codecFor(QMetaType::fromType<QStringList>());
        QVERIFY(codec);

        const auto ok = codec->decode(QJsonArray{ QStringLiteral("a"), QStringLiteral("b") });
        QVERIFY(!ok.error);
        QCOMPARE(ok.value.toStringList(), (QStringList{ QStringLiteral("a"), QStringLiteral("b") }));

        const auto bad = codec->decode(QJsonArray{ QStringLiteral("a"), 2, QStringLiteral("c") });
        QVERIFY(bad.error);
        QCOMPARE(bad.indexPath, QList<qsizetype>{ 1 });
    }

    void realListAcceptsIntegers() {
        const auto* codec = ValueCodec::codecFor(QMetaType::fromType<QList<qreal>>());
        QVERIFY(codec);

        const auto ok = codec->decode(QJsonArray{ 1, 2.5 });
        QVERIFY(!ok.error);
        QCOMPARE(ok.value.value<QList<qreal>>(), (QList<qreal>{ 1.0, 2.5 }));
    }

    void unsupportedListElement() {
        // Only string and real lists are supported
        QCOMPARE(ValueCodec::codecFor(QMetaType::fromType<QList<int>>()), nullptr);
    }

    void unsupportedType() { QCOMPARE(ValueCodec::codecFor(QMetaType::fromType<QObject*>()), nullptr); }
};

QTEST_GUILESS_MAIN(TestSettingsCodecs)
#include "tst_settingscodecs.moc"
