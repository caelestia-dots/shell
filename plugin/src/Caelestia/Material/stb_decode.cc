// stb_image is a single header with its implementation in it. Its JPEG loader trips clang's static
// analyzer, and it's not our code to fix, so it lives in a .cc of its own, as the vendored
// material-color-utilities sources do.

#include "stb_decode.hpp"

// The single stb_image implementation: the same header (v2.29) the CLI's quantizer decodes with
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

namespace caelestia::material {

std::optional<DecodedImage> decodeImage(const unsigned char* data, size_t size, std::string* failure) {
    int width = 0;
    int height = 0;
    int channels = 0;
    stbi_uc* pixels = stbi_load_from_memory(data, static_cast<int>(size), &width, &height, &channels, 4);
    if (pixels == nullptr) {
        *failure = stbi_failure_reason();
        return std::nullopt;
    }

    DecodedImage image;
    image.width = width;
    image.height = height;
    const size_t count = static_cast<size_t>(width) * static_cast<size_t>(height);
    image.argb.reserve(count);
    for (size_t i = 0; i < count; ++i) {
        const stbi_uc* p = pixels + (i * 4);
        image.argb.push_back(0xFF000000u | (static_cast<uint32_t>(p[0]) << 16) | (static_cast<uint32_t>(p[1]) << 8) |
                             static_cast<uint32_t>(p[2]));
    }
    stbi_image_free(pixels);
    return image;
}

} // namespace caelestia::material
