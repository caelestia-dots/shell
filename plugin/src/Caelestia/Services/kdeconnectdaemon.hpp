#pragma once

#include <qfuture.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qvariant.h>

namespace caelestia::services {

class KdeConnectDaemon : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged)
    Q_PROPERTY(bool downloading READ downloading NOTIFY downloadingChanged)
    Q_PROPERTY(qreal downloadProgress READ downloadProgress NOTIFY downloadProgressChanged)
    Q_PROPERTY(QString downloadDevice READ downloadDevice NOTIFY downloadDeviceChanged)

public:
    explicit KdeConnectDaemon(QObject* parent = nullptr);

    [[nodiscard]] bool available() const;
    [[nodiscard]] QVariantList devices() const;
    [[nodiscard]] bool downloading() const;
    [[nodiscard]] qreal downloadProgress() const;
    [[nodiscard]] QString downloadDevice() const;

    Q_INVOKABLE void share(const QString& deviceId, const QVariantList& urls);
    Q_INVOKABLE void download(const QString& deviceId, const QString& sourcePath);
    Q_INVOKABLE void cancelDownload();

    Q_INVOKABLE void mount(const QString& deviceId);
    Q_INVOKABLE void unmount(const QString& deviceId);
    Q_INVOKABLE void refreshMount(const QString& deviceId);

public slots:
    void refresh();

signals:
    void availableChanged();
    void devicesChanged();
    void downloadingChanged();
    void downloadProgressChanged();
    void downloadDeviceChanged();

    void shared(const QString& deviceId, int count);
    void shareFailed(const QString& deviceId, const QString& error);

    void downloaded(const QString& deviceId, const QString& destinationPath);
    void downloadFailed(const QString& deviceId, const QString& error);
    void downloadCancelled(const QString& deviceId);

    void mountStateChanged(
        const QString& deviceId, bool mounted, const QString& mountPoint, const QVariantMap& directories);
    void mountFailed(const QString& deviceId, const QString& error);

private:
    bool m_available = false;
    QVariantList m_devices;
    bool m_downloading = false;
    qreal m_downloadProgress = 0.0;
    QString m_downloadDevice;
    QFuture<void> m_download;

    void setAvailable(bool available);
    void setDevices(const QVariantList& devices);
    void setDownloading(bool downloading);
    void setDownloadProgress(qreal progress);
    void setDownloadDevice(const QString& deviceId);
};

} // namespace caelestia::services
