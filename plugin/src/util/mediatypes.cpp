#include "util/mediatypes.hpp"

#include <qimagereader.h>
#include <qmediaformat.h>
#include <qmimedatabase.h>
#include <qset.h>

namespace util::media {

using Qt::StringLiterals::operator""_s;

namespace {

struct VideoTypes {
    QSet<QString> mimeTypes;
    QStringList globs;
};

const VideoTypes& videoTypes() {
    static const VideoTypes k_types = [] {
        VideoTypes types;
        const auto formats = QMediaFormat().supportedFileFormats(QMediaFormat::Decode);
        for (const auto format : formats) {
            const auto mimeType = QMediaFormat(format).mimeType();
            if (!mimeType.name().startsWith(u"video/"))
                continue;

            types.mimeTypes << mimeType.name();
            types.globs << mimeType.globPatterns();
        }
        return types;
    }();
    return k_types;
}

} // namespace

bool isImage(const QString& path) {
    return QImageReader(path).canRead();
}

bool isVideo(const QString& path) {
    static const QMimeDatabase k_db;
    return videoTypes().mimeTypes.contains(k_db.mimeTypeForFile(path).name());
}

QStringList imageGlobs() {
    static const QStringList k_globs = [] {
        QStringList globs;
        const auto formats = QImageReader::supportedImageFormats();
        for (const auto& format : formats)
            globs << u"*."_s + QString::fromUtf8(format);
        return globs;
    }();
    return k_globs;
}

QStringList videoGlobs() {
    return videoTypes().globs;
}

} // namespace util::media
