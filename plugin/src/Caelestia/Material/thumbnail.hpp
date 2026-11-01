#pragma once

// The 128px thumbnail the caelestia CLI takes a wallpaper's colours from, in the CLI's cache
// (wallpapers/<sha256 of the file>/thumbnail.jpg). It's read when it exists and made here when it
// doesn't, so the CLI and the shell use the same file.

#include <qstring.h>

#include <cstdint>
#include <vector>

namespace caelestia::material {

// Path of the wallpaper's thumbnail, creating it when missing. Empty, with `error` set, on failure.
QString thumbnailFor(const QString& wallpaper, QString* error);

// The thumbnail's pixels as opaque ARGB, decoded with the same stb_image the CLI's quantizer uses
std::vector<uint32_t> decodeThumbnail(const QString& thumbnailPath, QString* error);

} // namespace caelestia::material
