#pragma once

#include <QObject>
#include <QString>
#include <QVariant>
#include <atomic>
#include <memory>
#include <qqmlintegration.h>

class KdeConnectTransfer : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(bool receiving READ receiving NOTIFY receivingChanged)
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString deviceId READ deviceId NOTIFY deviceIdChanged)

public:
    explicit KdeConnectTransfer(QObject* parent = nullptr);

    [[nodiscard]] bool running() const;
    [[nodiscard]] bool receiving() const;
    [[nodiscard]] qreal progress() const;
    [[nodiscard]] QString deviceId() const;

    Q_INVOKABLE void share(const QString& deviceId, const QVariantList& urls);
    Q_INVOKABLE void download(const QString& deviceId, const QString& sourcePath);
    Q_INVOKABLE void cancel();

    Q_INVOKABLE void mount(const QString& deviceId);
    Q_INVOKABLE void unmount(const QString& deviceId);
    Q_INVOKABLE void refreshMount(const QString& deviceId);

signals:
    void runningChanged();
    void receivingChanged();
    void progressChanged();
    void deviceIdChanged();

    void shared(const QString& deviceId, int count);
    void failed(const QString& deviceId, const QString& error);
    void cancelled(const QString& deviceId);

    void downloaded(const QString& deviceId, const QString& destinationPath);
    void downloadFailed(const QString& deviceId, const QString& error);
    void downloadCancelled(const QString& deviceId);

    void mountStateChanged(
        const QString& deviceId,
        bool mounted,
        const QString& mountPoint,
        const QVariantMap& directories
    );

    void mountFailed(
        const QString& deviceId,
        const QString& error
    );

private:
    void setRunning(bool running);
    void setReceiving(bool receiving);
    void setProgress(qreal progress);
    void setDeviceId(const QString& deviceId);

    bool m_running = false;
    bool m_receiving = false;
    qreal m_progress = 0.0;
    QString m_deviceId;

    std::shared_ptr<std::atomic_bool> m_cancelToken;
};
