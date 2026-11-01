#pragma once

// Image decoding with stb_image, the decoder the caelestia CLI's quantizer uses. Its implementation
// lives in stb_decode.cc, apart from the rest of the library, as the vendored sources do.

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace caelestia::material {

struct DecodedImage {
    int width = 0;
    int height = 0;
    std::vector<uint32_t> argb; // opaque pixels, row by row
};

// Decodes an encoded image (JPEG, PNG, ...). On failure, returns nothing and sets `failure`.
std::optional<DecodedImage> decodeImage(const unsigned char* data, size_t size, std::string* failure);

} // namespace caelestia::material
