#pragma once

#include <QObject>
#include <QString>
#include <QVariant>
#include <qqmlintegration.h>

class KdeConnectTransfer : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString deviceId READ deviceId NOTIFY deviceIdChanged)

public:
    explicit KdeConnectTransfer(QObject* parent = nullptr);

    [[nodiscard]] bool running() const;
    [[nodiscard]] qreal progress() const;
    [[nodiscard]] QString deviceId() const;

    Q_INVOKABLE void share(const QString& deviceId, const QVariantList& urls);

signals:
    void runningChanged();
    void progressChanged();
    void deviceIdChanged();

    void shared(const QString& deviceId, int count);
    void failed(const QString& deviceId, const QString& error);

private:
    void setRunning(bool running);
    void setProgress(qreal progress);
    void setDeviceId(const QString& deviceId);

    bool m_running = false;
    qreal m_progress = 0.0;
    QString m_deviceId;
};
