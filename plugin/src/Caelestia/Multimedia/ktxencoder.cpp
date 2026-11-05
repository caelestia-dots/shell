#include "ktxencoder.hpp"

#include <qimagereader.h>
#include <qtconcurrentmap.h>

#include <rgbcx.h>

#include <algorithm>
#include <array>
#include <cstring>
#include <mutex>
#include <numeric>

namespace caelestia::shell::multimedia::ktx {

namespace {

constexpr quint32 k_glRgba = 0x1908;
constexpr quint32 k_glBc3 = 0x83F3;
constexpr quint32 k_rgbcxLevel = 10;
constexpr std::array<quint8, 12> k_identifier = { 0xAB, 'K', 'T', 'X', ' ', '1', '1', 0xBB, '\r', '\n', 0x1A, '\n' };

struct Header {
    std::array<quint8, 12> identifier;
    quint32 endianness;
    quint32 glType;
    quint32 glTypeSize;
    quint32 glFormat;
    quint32 glInternalFormat;
    quint32 glBaseInternalFormat;
    quint32 pixelWidth;
    quint32 pixelHeight;
    quint32 pixelDepth;
    quint32 numberOfArrayElements;
    quint32 numberOfFaces;
    quint32 numberOfMipmapLevels;
    quint32 bytesOfKeyValueData;
};

static_assert(sizeof(Header) == 64);

void initRgbcx() {
    static std::once_flag s_flag;
    std::call_once(s_flag, [] {
        rgbcx::init(rgbcx::bc1_approx_mode::cBC1Ideal);
    });
}

void gatherBlock(const QImage& image, int bx, int by, quint8* out) {
    const int maxX = image.width() - 1;
    const int maxY = image.height() - 1;
    for (int y = 0; y < 4; ++y) {
        const quint8* row = image.constScanLine(std::min(by * 4 + y, maxY));
        for (int x = 0; x < 4; ++x) {
            const qsizetype px = std::min(bx * 4 + x, maxX);
            std::memcpy(out + static_cast<qsizetype>(y * 4 + x) * 4, row + px * 4, 4);
        }
    }
}

} // namespace

Fit fitFor(const QSize& native, const QSize& bucket, Qt::AspectRatioMode mode) {
    auto scaled = mode == Qt::IgnoreAspectRatio ? bucket.boundedTo(native) : native.scaled(bucket, mode);
    if (scaled.width() > native.width() || scaled.height() > native.height())
        scaled = native;

    const auto cropSize = mode == Qt::KeepAspectRatioByExpanding ? bucket.boundedTo(scaled) : scaled;
    const QPoint origin((scaled.width() - cropSize.width()) / 2, (scaled.height() - cropSize.height()) / 2);
    return { .scaled = scaled, .crop = QRect(origin, cropSize) };
}

QImage fitted(const QImage& image, const QSize& bucket, Qt::AspectRatioMode mode) {
    const auto fit = fitFor(image.size(), bucket, mode);
    const auto scaled = image.scaled(fit.scaled, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    return fit.crop.size() == fit.scaled ? scaled : scaled.copy(fit.crop);
}

QImage readFitted(const QString& path, const QSize& bucket, Qt::AspectRatioMode mode) {
    QImageReader reader(path);
    reader.setAutoTransform(true);

    const auto native = reader.size();
    if (!native.isValid())
        return fitted(reader.read(), bucket, mode);

    const auto fit = fitFor(native, bucket, mode);
    reader.setScaledSize(fit.scaled);
    auto image = reader.read();
    if (image.isNull() || fit.crop.size() == fit.scaled)
        return image;
    return image.copy(fit.crop);
}

QByteArray encodeBc3(const QImage& source) {
    initRgbcx();

    const auto image = source.convertToFormat(QImage::Format_RGBA8888);
    const int blocksW = (image.width() + 3) / 4;
    const int blocksH = (image.height() + 3) / 4;
    const auto imageSize = static_cast<quint32>(static_cast<qsizetype>(blocksW) * blocksH * 16);

    Header header{};
    header.identifier = k_identifier;
    header.endianness = 0x04030201;
    header.glTypeSize = 1;
    header.glInternalFormat = k_glBc3;
    header.glBaseInternalFormat = k_glRgba;
    header.pixelWidth = static_cast<quint32>(image.width());
    header.pixelHeight = static_cast<quint32>(image.height());
    header.numberOfFaces = 1;
    header.numberOfMipmapLevels = 1;

    const auto totalSize = static_cast<qsizetype>(sizeof(header) + sizeof(imageSize)) + imageSize;
    QByteArray out(totalSize, Qt::Uninitialized);
    std::memcpy(out.data(), &header, sizeof(header));
    std::memcpy(out.data() + sizeof(header), &imageSize, sizeof(imageSize));
    auto* blocks = reinterpret_cast<quint8*>(out.data() + sizeof(header) + sizeof(imageSize));

    QList<int> rows(blocksH);
    std::iota(rows.begin(), rows.end(), 0);

    QtConcurrent::blockingMap(rows, [&](int by) {
        alignas(16) quint8 pixels[64];
        for (int bx = 0; bx < blocksW; ++bx) {
            gatherBlock(image, bx, by, pixels);
            rgbcx::encode_bc3(k_rgbcxLevel, blocks + (static_cast<qsizetype>(by) * blocksW + bx) * 16, pixels);
        }
    });

    return out;
}

} // namespace caelestia::shell::multimedia::ktx
