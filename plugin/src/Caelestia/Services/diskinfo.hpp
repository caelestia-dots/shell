#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::services {

class DiskInfo : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("DiskInfo is created by DiskUsage")

    Q_PROPERTY(QString mount READ mount CONSTANT)
    Q_PROPERTY(qreal used READ used NOTIFY usedChanged)
    Q_PROPERTY(qreal total READ total NOTIFY totalChanged)
    Q_PROPERTY(qreal free READ free NOTIFY freeChanged)
    Q_PROPERTY(qreal perc READ perc NOTIFY percChanged)
    Q_PROPERTY(bool hasRoot READ hasRoot NOTIFY hasRootChanged)

public:
    DiskInfo(QString mount, quint64 usedBytes, quint64 totalBytes, bool hasRoot, QObject* parent = nullptr);

    [[nodiscard]] QString mount() const;
    [[nodiscard]] qreal used() const;  // KiB
    [[nodiscard]] qreal total() const; // KiB
    [[nodiscard]] qreal free() const;  // KiB
    [[nodiscard]] qreal perc() const;
    [[nodiscard]] bool hasRoot() const;

    void update(quint64 usedBytes, quint64 totalBytes, bool hasRoot);

signals:
    void usedChanged();
    void totalChanged();
    void freeChanged();
    void percChanged();
    void hasRootChanged();

private:
    QString m_mount;
    quint64 m_usedBytes;
    quint64 m_totalBytes;
    bool m_hasRoot;
};

} // namespace caelestia::services
