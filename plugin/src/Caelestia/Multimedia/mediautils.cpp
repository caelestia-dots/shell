#include "mediautils.hpp"

#include <caelestia/media/analysis.hpp>

namespace caelestia::shell::multimedia {

bool MediaUtils::isSupported(const QString& path) {
    return media::isSupported(path);
}

} // namespace caelestia::shell::multimedia
