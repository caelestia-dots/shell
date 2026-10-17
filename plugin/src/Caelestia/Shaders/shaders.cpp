#include "shaders.hpp"

namespace caelestia::shaders {

using Qt::StringLiterals::operator""_s;

QUrl Shaders::crossfade() {
    return u"qrc:/shaders/crossfade.frag.qsb"_s;
}

} // namespace caelestia::shaders
