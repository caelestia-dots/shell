#include "thumbnail.hpp"

#include <qbytearray.h>
#include <qcryptographichash.h>
#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qimage.h>
#include <qimagereader.h>
#include <qimagewriter.h>
#include <qstring.h>
#include <quuid.h>

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <filesystem>
#include <functional>
#include <optional>

#include "stb_decode.hpp"

namespace caelestia::material {

namespace {

constexpr int k_thumbnailSize = 128;
constexpr int k_jpegQuality = 75; // PIL's default, which the CLI writes its thumbnails with

// The CLI's wallpapers cache: $XDG_CACHE_HOME/caelestia/wallpapers
QString wallpapersCacheDir() {
    QString base = qEnvironmentVariable("XDG_CACHE_HOME");
    if (base.isEmpty())
        base = QDir::homePath() + QStringLiteral("/.cache");
    return base + QStringLiteral("/caelestia/wallpapers");
}

// The CLI's compute_hash: SHA-256 of the file's contents
std::optional<QString> contentHash(const QString& path, QString* error) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        *error = QStringLiteral("Unable to read %1: %2").arg(path, file.errorString());
        return std::nullopt;
    }
    QCryptographicHash hash(QCryptographicHash::Sha256);
    if (!hash.addData(&file)) {
        *error = QStringLiteral("Unable to hash %1").arg(path);
        return std::nullopt;
    }
    return QString::fromLatin1(hash.result().toHex());
}

// PIL's round_aspect: the nearer of floor and ceil to `value`, judged by how close its aspect
// ratio stays to `aspect`
int roundAspect(double value, const std::function<double(double)>& error) {
    const int low = std::max(1, static_cast<int>(std::floor(value)));
    const int high = std::max(1, static_cast<int>(std::ceil(value)));
    return error(low) <= error(high) ? low : high;
}

// PIL's Image.thumbnail: fits the image inside 128x128 keeping its aspect ratio, never enlarging
QSize thumbnailSize(QSize size) {
    if (size.width() <= k_thumbnailSize && size.height() <= k_thumbnailSize)
        return size;

    const double aspect = static_cast<double>(size.width()) / size.height();
    if (aspect >= 1.0) {
        const int height = roundAspect(k_thumbnailSize / aspect, [aspect](double n) {
            return std::fabs(aspect - k_thumbnailSize / n);
        });
        return { k_thumbnailSize, height };
    }
    const int width = roundAspect(k_thumbnailSize * aspect, [aspect](double n) {
        return std::fabs(aspect - n / k_thumbnailSize);
    });
    return { width, k_thumbnailSize };
}

} // namespace

QString thumbnailFor(const QString& wallpaper, QString* error) {
    const auto hash = contentHash(wallpaper, error);
    if (!hash)
        return {};

    const QString dir = wallpapersCacheDir() + QLatin1Char('/') + *hash;
    QString thumb = dir + QStringLiteral("/thumbnail.jpg");
    if (QFileInfo::exists(thumb))
        return thumb;

    // The first frame of an image, as PIL reads it: no EXIF rotation, alpha dropped
    QImageReader reader(wallpaper);
    reader.setAutoTransform(false);
    QImage image = reader.read();
    if (image.isNull()) {
        *error = QStringLiteral("Unable to decode %1: %2").arg(wallpaper, reader.errorString());
        return {};
    }
    image = image.convertToFormat(QImage::Format_RGB888);
    const QSize size = thumbnailSize(image.size());
    if (size != image.size())
        image = image.scaled(size, Qt::IgnoreAspectRatio, Qt::FastTransformation);

    if (!QDir().mkpath(dir)) {
        *error = QStringLiteral("Unable to create %1").arg(dir);
        return {};
    }

    // Written under a unique name and renamed into place, so the CLI never reads a partial file
    const QString partial = thumb + QStringLiteral(".") + QUuid::createUuid().toString(QUuid::Id128);
    QImageWriter writer(partial);
    writer.setFormat("jpeg");
    writer.setQuality(k_jpegQuality);
    if (!writer.write(image)) {
        *error = QStringLiteral("Unable to write %1: %2").arg(thumb, writer.errorString());
        QFile::remove(partial);
        return {};
    }

    std::error_code code;
    std::filesystem::rename(partial.toStdString(), thumb.toStdString(), code);
    if (code) {
        *error =
            QStringLiteral("Unable to move the thumbnail into place: %1").arg(QString::fromStdString(code.message()));
        QFile::remove(partial);
        return {};
    }
    return thumb;
}

std::vector<uint32_t> decodeThumbnail(const QString& thumbnailPath, QString* error) {
    QFile file(thumbnailPath);
    if (!file.open(QIODevice::ReadOnly)) {
        *error = QStringLiteral("Unable to read %1: %2").arg(thumbnailPath, file.errorString());
        return {};
    }
    const QByteArray bytes = file.readAll();

    std::string failure;
    const auto image = decodeImage(
        reinterpret_cast<const unsigned char*>(bytes.constData()), static_cast<size_t>(bytes.size()), &failure);
    if (!image) {
        *error = QStringLiteral("Unable to decode %1: %2").arg(thumbnailPath, QString::fromStdString(failure));
        return {};
    }
    return image->argb;
}

} // namespace caelestia::material
