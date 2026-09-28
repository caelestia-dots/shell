#pragma once

#include <qdbusmessage.h>
#include <qfuture.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qthreadpool.h>
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
    Q_INVOKABLE void checkMount(const QString& deviceId, const QString& path);

    Q_INVOKABLE void requestPairing(const QString& deviceId);
    Q_INVOKABLE void acceptPairing(const QString& deviceId);
    // Cancels a pairing request we sent, or rejects one the device sent
    Q_INVOKABLE void cancelPairing(const QString& deviceId);
    Q_INVOKABLE void unpair(const QString& deviceId);

public slots:
    void refresh();

private slots:
    void onPairingFailed(const QString& error, const QDBusMessage& message);

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
    void mountChecked(const QString& deviceId, const QString& path, bool reachable);

    void pairingFailed(const QString& deviceId, const QString& error);

private:
    bool m_available = false;
    QVariantList m_devices;
    // Drops results from refreshes superseded by a newer one
    quint64 m_refreshGeneration = 0;
    bool m_downloading = false;
    qreal m_downloadProgress = 0.0;
    QString m_downloadDevice;
    QFuture<void> m_download;
    // Probes of a dead mount can hang until it is unmounted, so keep them off the
    // global pool which mounting and unmounting run on
    QThreadPool m_probePool;

    void setAvailable(bool available);
    void setDevices(const QVariantList& devices);
    void setDownloading(bool downloading);
    void setDownloadProgress(qreal progress);
    void setDownloadDevice(const QString& deviceId);

    void startUnmount(const QString& deviceId);
    void callDevice(const QString& deviceId, const QString& method);
    void dropDeadMount(const QString& deviceId);
};

} // namespace caelestia::services
