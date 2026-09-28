#pragma once

#include <qdatetime.h>
#include <qhash.h>
#include <qhostaddress.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qtimer.h>
#include <qudpsocket.h>
#include <qvariant.h>

namespace caelestia::services {

// Finds Android wireless debugging services over mDNS, so connecting and pairing
// do not depend on adb being built with mDNS support
class AdbDiscovery : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    // Each service is { name, kind: "connect" or "pairing", address, port }
    Q_PROPERTY(QVariantList services READ services NOTIFY servicesChanged)

public:
    explicit AdbDiscovery(QObject* parent = nullptr);

    [[nodiscard]] bool active() const;
    void setActive(bool active);

    [[nodiscard]] QVariantList services() const;

    // Asks the network again right away, instead of waiting for the next interval
    Q_INVOKABLE void query();

signals:
    void activeChanged();
    void servicesChanged();

private:
    struct Instance {
        QString kind;
        quint16 port = 0;
        QString target;
        QHostAddress sender;
        QDateTime seen;
    };

    struct Record {
        QString name;
        quint16 type = 0;
        quint32 ttl = 0;
        qsizetype offset = 0;
        quint16 length = 0;
    };

    bool m_active = false;
    bool m_bound = false;
    QUdpSocket m_socket;
    QTimer m_queryTimer;
    // Keyed by instance name
    QHash<QString, Instance> m_instances;
    // Keyed by host name
    QHash<QString, QHostAddress> m_hosts;
    QVariantList m_services;

    void bind();
    void readDatagrams();
    void parse(const QByteArray& data, const QHostAddress& sender);
    void handlePtr(const QByteArray& data, const Record& record, const QHostAddress& sender, const QDateTime& now);
    void handleSrv(const QByteArray& data, const Record& record, const QHostAddress& sender, const QDateTime& now);
    void publish();
};

} // namespace caelestia::services
