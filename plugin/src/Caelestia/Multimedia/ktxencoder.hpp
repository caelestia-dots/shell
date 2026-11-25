#pragma once

#include <qbytearray.h>
#include <qimage.h>
#include <qnamespace.h>
#include <qrect.h>
#include <qsize.h>

namespace caelestia::shell::multimedia::ktx {

struct Fit {
    QSize scaled;
    QRect crop;
};

struct Cover {
    QSize size;
    bool transposed = false;
};

[[nodiscard]] Fit fitFor(const QSize& native, const QSize& bucket, Qt::AspectRatioMode mode);
[[nodiscard]] QImage fitted(const QImage& image, const QSize& bucket, Qt::AspectRatioMode mode);
// The size Qt decodes path to when asked to cover bucket, invalid if unknown
[[nodiscard]] Cover coverFor(const QString& path, const QSize& bucket);
[[nodiscard]] QImage readFitted(const QString& path, const QSize& bucket, Qt::AspectRatioMode mode);
[[nodiscard]] QByteArray encodeBc3(const QImage& source);

} // namespace caelestia::shell::multimedia::ktx
