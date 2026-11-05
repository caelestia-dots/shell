#pragma once

#include <qstring.h>
#include <qstringlist.h>

namespace util::media {

[[nodiscard]] bool isImage(const QString& path);
[[nodiscard]] bool isVideo(const QString& path);
[[nodiscard]] QStringList imageGlobs();
[[nodiscard]] QStringList videoGlobs();

} // namespace util::media
