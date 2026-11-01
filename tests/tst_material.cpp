#include <QCryptographicHash>
#include <QDir>
#include <QFile>
#include <QImage>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTemporaryDir>
#include <QtTest>

#include "Material/generator.hpp"
#include "Material/preview.hpp"
#include "Material/thumbnail.hpp"

using namespace caelestia::material;

namespace {

QJsonObject readJsonObject(const QString& path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return {};
    return QJsonDocument::fromJson(file.readAll()).object();
}

// The wallpaper cache is keyed by the SHA-256 of the file's contents, as the CLI keys it
QString cacheKeyOf(const QString& file) {
    QFile source(file);
    if (!source.open(QIODevice::ReadOnly))
        return {};
    QCryptographicHash hash(QCryptographicHash::Sha256);
    hash.addData(&source);
    return QString::fromLatin1(hash.result().toHex());
}

} // namespace

class TstMaterial : public QObject {
    Q_OBJECT

private slots:
    // Every colour of the CLI's generator, for a slice of its reference cases (both spec versions,
    // all variants, both modes). The fixture comes from materialyoucolor's own output.
    void generatesTheCliColours();

    // The preview of a wallpaper, read from the thumbnail the CLI made, matches the CLI's output
    void previewMatchesTheCli();

    // Without a thumbnail in the cache, one is made, is 128px at most, and is reused afterwards
    void makesMissingThumbnail();

    // The primary colour of an image is scored over its pixels, as the CLI does
    void scoresSolidColour();

    // The applied scheme comes from the CLI's state file, or the CLI's defaults without one
    void readsAppliedScheme();
};

void TstMaterial::generatesTheCliColours() {
    const QJsonObject oracle = readJsonObject(QFINDTESTDATA("data/material/oracle.json"));
    QVERIFY(!oracle.isEmpty());

    QStringList keys;
    for (const QJsonValue& key : oracle.value(QStringLiteral("keys")).toArray())
        keys << key.toString();
    QVERIFY(!keys.isEmpty());

    const QJsonArray cases = oracle.value(QStringLiteral("cases")).toArray();
    QCOMPARE(cases.size(), qsizetype(72));

    int mismatches = 0;
    for (const QJsonValue& value : cases) {
        const QJsonObject tc = value.toObject();
        const auto seed = static_cast<uint32_t>(tc.value(QStringLiteral("seed")).toString().toULong(nullptr, 16));
        const Hct primary(0xFF000000u | seed);

        GeneratorOptions options;
        options.variant = tc.value(QStringLiteral("variant")).toString().toStdString();
        options.flavour = "default";
        options.light = tc.value(QStringLiteral("mode")).toString() == QLatin1String("light");

        const Colours colours = generateScheme(options, primary);
        const QJsonArray expected = tc.value(QStringLiteral("colours")).toArray();
        QCOMPARE(expected.size(), keys.size());

        for (qsizetype i = 0; i < keys.size(); ++i) {
            const auto found = colours.find(keys[i].toStdString());
            const QString actual = found == colours.end() ? QString() : QString::fromStdString(found->second);
            if (actual != expected[i].toString()) {
                if (mismatches < 10) {
                    qWarning() << tc.value(QStringLiteral("seed")).toString() << options.variant.c_str()
                               << tc.value(QStringLiteral("mode")).toString() << keys[i] << "expected"
                               << expected[i].toString() << "got" << actual;
                }
                ++mismatches;
            }
        }
    }
    QCOMPARE(mismatches, 0);
}

void TstMaterial::previewMatchesTheCli() {
    QTemporaryDir cache;
    QVERIFY(cache.isValid());
    qputenv("XDG_CACHE_HOME", cache.path().toUtf8());

    const QString wallpaper = QFINDTESTDATA("data/material/wallpaper.png");
    QVERIFY(!wallpaper.isEmpty());
    const QString thumbDir = cache.path() + QStringLiteral("/caelestia/wallpapers/") + cacheKeyOf(wallpaper);
    QVERIFY(QDir().mkpath(thumbDir));
    QVERIFY(QFile::copy(QFINDTESTDATA("data/material/thumbnail.jpg"), thumbDir + QStringLiteral("/thumbnail.jpg")));

    const QJsonObject expected = readJsonObject(QFINDTESTDATA("data/material/preview-expected.json"));
    QVERIFY(!expected.isEmpty());

    const SchemeState scheme{ expected.value(QStringLiteral("variant")).toString(),
        expected.value(QStringLiteral("flavour")).toString(), expected.value(QStringLiteral("mode")).toString() };
    QString error;
    const QByteArray json = previewJson(wallpaper, scheme, &error);
    QVERIFY2(!json.isEmpty(), qPrintable(error));

    const QJsonObject actual = QJsonDocument::fromJson(json).object();
    QCOMPARE(actual.value(QStringLiteral("name")).toString(), expected.value(QStringLiteral("name")).toString());
    QCOMPARE(actual.value(QStringLiteral("flavour")).toString(), expected.value(QStringLiteral("flavour")).toString());
    QCOMPARE(actual.value(QStringLiteral("mode")).toString(), expected.value(QStringLiteral("mode")).toString());
    QCOMPARE(actual.value(QStringLiteral("variant")).toString(), expected.value(QStringLiteral("variant")).toString());
    const QJsonObject actualColours = actual.value(QStringLiteral("colours")).toObject();
    const QJsonObject expectedColours = expected.value(QStringLiteral("colours")).toObject();
    QCOMPARE(actualColours.size(), expectedColours.size());
    for (const QString& name : expectedColours.keys()) {
        QVERIFY2(actualColours.value(name) == expectedColours.value(name),
            qPrintable(QStringLiteral("colour %1 differs").arg(name)));
    }
}

void TstMaterial::makesMissingThumbnail() {
    QTemporaryDir cache;
    QVERIFY(cache.isValid());
    qputenv("XDG_CACHE_HOME", cache.path().toUtf8());

    const QString wallpaper = QFINDTESTDATA("data/material/wallpaper.png");
    QString error;
    const QString thumb = thumbnailFor(wallpaper, &error);
    QVERIFY2(!thumb.isEmpty(), qPrintable(error));
    QVERIFY(thumb.startsWith(cache.path()));

    // A 240x160 image fits 128px wide, keeping its aspect ratio
    const QImage image(thumb);
    QCOMPARE(image.size(), QSize(128, 85));

    // The second call reuses the file it made
    const QDateTime made = QFileInfo(thumb).lastModified();
    QCOMPARE(thumbnailFor(wallpaper, &error), thumb);
    QCOMPARE(QFileInfo(thumb).lastModified(), made);

    const std::vector<uint32_t> pixels = decodeThumbnail(thumb, &error);
    QCOMPARE(pixels.size(), static_cast<size_t>(128 * 85));
    for (const uint32_t pixel : pixels)
        QCOMPARE(pixel >> 24, 0xFFu);
}

void TstMaterial::scoresSolidColour() {
    // The CLI scores a solid (200, 30, 30) field to this colour (the HCT round trip rounds it)
    const std::vector<uint32_t> pixels(64 * 64, 0xFFC81E1Eu);
    QCOMPARE(scoreImagePixels(pixels).ToInt(), 0xFFC81E1Eu);
}

void TstMaterial::readsAppliedScheme() {
    QTemporaryDir state;
    QVERIFY(state.isValid());
    qputenv("XDG_STATE_HOME", state.path().toUtf8());

    // No state yet: the CLI's defaults
    SchemeState scheme = appliedScheme();
    QCOMPARE(scheme.variant, QStringLiteral("tonalspot"));
    QCOMPARE(scheme.flavour, QStringLiteral("mocha"));
    QCOMPARE(scheme.mode, QStringLiteral("dark"));

    QVERIFY(QDir().mkpath(state.path() + QStringLiteral("/caelestia")));
    QFile file(state.path() + QStringLiteral("/caelestia/scheme.json"));
    QVERIFY(file.open(QIODevice::WriteOnly));
    file.write(R"({"name":"monochrome","flavour":"noir","mode":"light","variant":"monochrome","colours":{}})");
    file.close();

    scheme = appliedScheme();
    QCOMPARE(scheme.variant, QStringLiteral("monochrome"));
    QCOMPARE(scheme.flavour, QStringLiteral("noir"));
    QCOMPARE(scheme.mode, QStringLiteral("light"));
}

QTEST_GUILESS_MAIN(TstMaterial)
#include "tst_material.moc"
