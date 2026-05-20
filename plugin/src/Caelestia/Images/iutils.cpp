#include "iutils.hpp"

#include "cachingimageprovider.hpp"

#include <qfileinfo.h>

namespace caelestia::images {

namespace {

IUtils* s_instance = nullptr;

} // namespace

IUtils* IUtils::getInstance() {
    return s_instance;
}

IUtils* IUtils::create(QQmlEngine* engine, QJSEngine* jsEngine) {
    Q_UNUSED(jsEngine);

    engine->addImageProvider(QStringLiteral("ccache"), new CachingImageProvider(CachingImageProvider::FillMode::Crop));
    engine->addImageProvider(QStringLiteral("fcache"), new CachingImageProvider(CachingImageProvider::FillMode::Fit));
    engine->addImageProvider(
        QStringLiteral("scache"), new CachingImageProvider(CachingImageProvider::FillMode::Stretch));

    s_instance = new IUtils(engine);
    return s_instance;
}

QUrl IUtils::urlForPath(const QString& path, int fillMode) {
    if (path.isEmpty())
        return QUrl();

    QString prefix;
    switch (fillMode) {
    case 1: // Image.PreserveAspectFit
        prefix = QStringLiteral("fcache");
        break;
    case 2: // Image.PreserveAspectCrop
        prefix = QStringLiteral("ccache");
        break;
    default: // Image.Stretch or any other ones
        prefix = QStringLiteral("scache");
        break;
    }

    QUrl url;
    url.setScheme(QStringLiteral("image"));
    url.setHost(prefix);
    url.setPath(path.startsWith(QLatin1Char('/')) ? path : QLatin1Char('/') + path);
    return url;
}

bool IUtils::fileExists(const QString& path) const {
    return QFileInfo::exists(path);
}

bool IUtils::isGif(const QString& path) {
    if (path.isEmpty())
        return false;
    
    const QString suffix = QFileInfo(path).suffix().toLower();
    return suffix == QStringLiteral("gif");
}

bool IUtils::isVideo(const QString& path) {
    if (path.isEmpty())
        return false;
    
    const QString suffix = QFileInfo(path).suffix().toLower();
    static const QStringList videoExtensions = { "mp4", "webm", "mkv", "avi", "mov", "wmv", "flv" };
    return videoExtensions.contains(suffix);
}

} // namespace caelestia::images
