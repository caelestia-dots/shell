#include "mediautils.hpp"

#include <caelestia/media/analysis.hpp>

#include "util/mediatypes.hpp"

namespace caelestia::shell::multimedia {

bool MediaUtils::isSupported(const QString& path) {
    return media::isSupported(path);
}

bool MediaUtils::isImage(const QString& path) {
    return util::media::isImage(path);
}

bool MediaUtils::isVideo(const QString& path) {
    return util::media::isVideo(path);
}

} // namespace caelestia::shell::multimedia
