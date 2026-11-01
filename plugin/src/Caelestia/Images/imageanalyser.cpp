#include "imageanalyser.hpp"

#include <qfuturewatcher.h>
#include <qimage.h>
#include <qloggingcategory.h>
#include <qquickitemgrabresult.h>
#include <qquickwindow.h>
#include <qtconcurrentrun.h>

#include <cstddef>
#include <vector>

namespace {

Q_LOGGING_CATEGORY(lcImageAnalyser, "caelestia.imageanalyser", QtInfoMsg)

} // namespace

namespace caelestia::images {

ImageAnalyser::ImageAnalyser(QObject* parent)
    : QObject(parent)
    , m_futureWatcher(new QFutureWatcher<AnalyseResult>(this))
    , m_sourceItem(nullptr)
    , m_rescaleSize(128)
    , m_dominantColour(0, 0, 0)
    , m_luminance(0) {
    QObject::connect(m_futureWatcher, &QFutureWatcher<AnalyseResult>::finished, this, [this] {
        if (!m_futureWatcher->future().isResultReadyAt(0)) {
            return;
        }

        const auto result = m_futureWatcher->result();
        if (m_dominantColour != result.first) {
            m_dominantColour = result.first;
            emit dominantColourChanged();
        }
        if (!qFuzzyCompare(m_luminance + 1.0, result.second + 1.0)) {
            m_luminance = result.second;
            emit luminanceChanged();
        }
    });
}

QString ImageAnalyser::source() const {
    return m_source;
}

void ImageAnalyser::setSource(const QString& source) {
    if (m_source == source) {
        return;
    }

    m_source = source;
    emit sourceChanged();

    if (m_sourceItem) {
        m_sourceItem = nullptr;
        emit sourceItemChanged();
    }

    requestUpdate();
}

QQuickItem* ImageAnalyser::sourceItem() const {
    return m_sourceItem;
}

void ImageAnalyser::setSourceItem(QQuickItem* sourceItem) {
    if (m_sourceItem == sourceItem) {
        return;
    }

    m_sourceItem = sourceItem;
    emit sourceItemChanged();

    if (!m_source.isEmpty()) {
        m_source.clear();
        emit sourceChanged();
    }

    requestUpdate();
}

int ImageAnalyser::rescaleSize() const {
    return m_rescaleSize;
}

void ImageAnalyser::setRescaleSize(int rescaleSize) {
    if (m_rescaleSize == rescaleSize) {
        return;
    }

    m_rescaleSize = rescaleSize;
    emit rescaleSizeChanged();

    requestUpdate();
}

QColor ImageAnalyser::dominantColour() const {
    return m_dominantColour;
}

qreal ImageAnalyser::luminance() const {
    return m_luminance;
}

void ImageAnalyser::requestUpdate() {
    if (m_source.isEmpty() && !m_sourceItem) {
        return;
    }

    if (!m_sourceItem || (m_sourceItem->window() && m_sourceItem->window()->isVisible() && m_sourceItem->width() > 0 &&
                             m_sourceItem->height() > 0)) {
        update();
    } else if (m_sourceItem) {
        if (!m_sourceItem->window()) {
            QObject::connect(m_sourceItem, &QQuickItem::windowChanged, this, &ImageAnalyser::requestUpdate,
                Qt::SingleShotConnection);
        } else if (!m_sourceItem->window()->isVisible()) {
            QObject::connect(m_sourceItem->window(), &QQuickWindow::visibleChanged, this, &ImageAnalyser::requestUpdate,
                Qt::SingleShotConnection);
        }
        if (m_sourceItem->width() <= 0) {
            QObject::connect(
                m_sourceItem, &QQuickItem::widthChanged, this, &ImageAnalyser::requestUpdate, Qt::SingleShotConnection);
        }
        if (m_sourceItem->height() <= 0) {
            QObject::connect(m_sourceItem, &QQuickItem::heightChanged, this, &ImageAnalyser::requestUpdate,
                Qt::SingleShotConnection);
        }
    }
}

void ImageAnalyser::update() {
    if (m_source.isEmpty() && !m_sourceItem) {
        return;
    }

    if (m_futureWatcher->isRunning()) {
        m_futureWatcher->cancel();
    }

    if (m_sourceItem) {
        const QSharedPointer<const QQuickItemGrabResult> grabResult = m_sourceItem->grabToImage();
        if (!grabResult) {
            QObject::connect(m_sourceItem, &QQuickItem::windowChanged, this, &ImageAnalyser::requestUpdate,
                Qt::SingleShotConnection);
            return;
        }
        QObject::connect(grabResult.data(), &QQuickItemGrabResult::ready, this, [grabResult, this] {
            m_futureWatcher->setFuture(QtConcurrent::run(&ImageAnalyser::analyse, grabResult->image(), m_rescaleSize));
        });
    } else {
        m_futureWatcher->setFuture(QtConcurrent::run([=, this](QPromise<AnalyseResult>& promise) {
            const QImage image(m_source);
            analyse(promise, image, m_rescaleSize);
        }));
    }
}

void ImageAnalyser::analyse(QPromise<AnalyseResult>& promise, const QImage& image, int rescaleSize) {
    if (image.isNull()) {
        qCWarning(lcImageAnalyser) << "analyse: image is null";
        return;
    }

    QImage img = image;

    if (rescaleSize > 0 && (img.width() > rescaleSize || img.height() > rescaleSize)) {
        img = img.scaled(rescaleSize, rescaleSize, Qt::KeepAspectRatio, Qt::FastTransformation);
    }

    if (promise.isCanceled()) {
        return;
    }

    if (img.format() != QImage::Format_ARGB32) {
        img = img.convertToFormat(QImage::Format_ARGB32);
    }

    if (promise.isCanceled()) {
        return;
    }

    const uchar* data = img.bits();
    const int width = img.width();
    const int height = img.height();
    const qsizetype bytesPerLine = img.bytesPerLine();

    // Colours are quantised to 5 bits per channel, so a flat 32768 bucket histogram covers
    // them all with one allocation instead of a hash map node per colour
    constexpr std::size_t k_buckets = 1U << 15U;
    std::vector<int> colours(k_buckets, 0);
    qreal totalLuminance = 0.0;
    int count = 0;

    for (int y = 0; y < height; ++y) {
        if (promise.isCanceled()) {
            return;
        }

        const uchar* line = data + y * bytesPerLine;
        for (int x = 0; x < width; ++x) {
            const uchar* pixel = line + (static_cast<qsizetype>(x) * 4);

            if (pixel[3] == 0) {
                continue;
            }

            const auto qr = static_cast<quint32>(pixel[2]) >> 3U;
            const auto qg = static_cast<quint32>(pixel[1]) >> 3U;
            const auto qb = static_cast<quint32>(pixel[0]) >> 3U;
            ++colours[(qr << 10U) | (qg << 5U) | qb];

            const qreal r = pixel[2] / 255.0;
            const qreal g = pixel[1] / 255.0;
            const qreal b = pixel[0] / 255.0;
            totalLuminance += std::sqrt(0.299 * r * r + 0.587 * g * g + 0.114 * b * b);
            ++count;
        }
    }

    quint32 dominantBucket = 0;
    int maxCount = 0;
    for (std::size_t i = 0; i < k_buckets; ++i) {
        if (colours[i] > maxCount) {
            dominantBucket = static_cast<quint32>(i);
            maxCount = colours[i];
        }
    }

    // Back to 8 bits per channel, matching the previous 0xF8 masking
    const quint32 dominantColour = (((dominantBucket >> 10U) & 0x1FU) << 19U) |
                                   (((dominantBucket >> 5U) & 0x1FU) << 11U) | ((dominantBucket & 0x1FU) << 3U);

    promise.addResult(qMakePair(QColor((0xFFu << 24u) | dominantColour), count == 0 ? 0.0 : totalLuminance / count));
}

} // namespace caelestia::images
