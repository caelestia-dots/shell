#pragma once

#include <qimage.h>
#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::shell::components {

class ImageExporter : public QObject {
    Q_OBJECT
    QML_ELEMENT

public:
    explicit ImageExporter(QObject* parent = nullptr);

    Q_INVOKABLE void save(const QImage& image);
    Q_INVOKABLE void copy(const QImage& image);

signals:
    void saved(const QString& path);
    void saveFailed();
    void copied(const QString& path);
    void copyFailed();

private:
    void pipeToClipboard(const QImage& image, const QByteArray& png);
};

} // namespace caelestia::shell::components
