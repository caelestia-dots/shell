#include "preview.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qstring.h>

#include "generator.hpp"
#include "thumbnail.hpp"

namespace caelestia::material {

SchemeState appliedScheme() {
    // The CLI's Scheme(None) defaults, used when there's no state yet
    SchemeState scheme{
        .variant = QStringLiteral("tonalspot"),
        .flavour = QStringLiteral("mocha"),
        .mode = QStringLiteral("dark"),
    };

    QString stateDir = qEnvironmentVariable("XDG_STATE_HOME");
    if (stateDir.isEmpty())
        stateDir = QDir::homePath() + QStringLiteral("/.local/state");

    QFile file(stateDir + QStringLiteral("/caelestia/scheme.json"));
    if (!file.open(QIODevice::ReadOnly))
        return scheme;

    const QJsonObject object = QJsonDocument::fromJson(file.readAll()).object();
    if (object.value(QStringLiteral("variant")).isString())
        scheme.variant = object.value(QStringLiteral("variant")).toString();
    if (object.value(QStringLiteral("flavour")).isString())
        scheme.flavour = object.value(QStringLiteral("flavour")).toString();
    if (object.value(QStringLiteral("mode")).isString())
        scheme.mode = object.value(QStringLiteral("mode")).toString();
    return scheme;
}

QByteArray previewJson(const QString& wallpaper, const SchemeState& scheme, QString* error) {
    const QString thumbnail = thumbnailFor(wallpaper, error);
    if (thumbnail.isEmpty())
        return {};

    const std::vector<uint32_t> pixels = decodeThumbnail(thumbnail, error);
    if (pixels.empty())
        return {};

    const Hct primary = scoreImagePixels(pixels);
    const GeneratorOptions options{
        .variant = scheme.variant.toStdString(),
        .flavour = scheme.flavour.toStdString(),
        .light = scheme.mode == QStringLiteral("light"),
    };
    const Colours colours = generateScheme(options, primary);

    QJsonObject coloursObject;
    for (const auto& [name, hex] : colours) {
        coloursObject.insert(QString::fromStdString(name), QString::fromStdString(hex));
    }

    const QJsonObject root{
        { QStringLiteral("name"), QStringLiteral("dynamic") },
        { QStringLiteral("flavour"), scheme.flavour },
        { QStringLiteral("mode"), scheme.mode },
        { QStringLiteral("variant"), scheme.variant },
        { QStringLiteral("colours"), coloursObject },
    };
    return QJsonDocument(root).toJson(QJsonDocument::Compact);
}

} // namespace caelestia::material
