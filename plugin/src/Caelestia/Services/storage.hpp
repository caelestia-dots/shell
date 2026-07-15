#pragma once

#include "diskinfo.hpp"
#include "tickingservice.hpp"

#include <qbytearrayview.h>
#include <qqmlintegration.h>
#include <qqmllist.h>
#include <qvariant.h>

namespace caelestia::services {

class Storage : public TickingService {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(qreal percentage READ percentage NOTIFY percentageChanged)
    Q_PROPERTY(QQmlListProperty<caelestia::services::DiskInfo> disks READ disksProp NOTIFY disksChanged)
    Q_PROPERTY(caelestia::services::DiskInfo* manualPrimaryDisk READ manualPrimaryDisk WRITE setManualPrimaryDisk NOTIFY
            manualPrimaryDiskChanged)
    Q_PROPERTY(caelestia::services::DiskInfo* primaryDisk READ primaryDisk NOTIFY primaryDiskChanged)

public:
    explicit Storage(QObject* parent = nullptr);

    [[nodiscard]] qreal percentage() const;
    [[nodiscard]] QQmlListProperty<DiskInfo> disksProp();
    [[nodiscard]] DiskInfo* manualPrimaryDisk() const;
    void setManualPrimaryDisk(DiskInfo* disk);
    [[nodiscard]] DiskInfo* primaryDisk() const;

signals:
    void disksChanged();
    void percentageChanged();
    void manualPrimaryDiskChanged();
    void primaryDiskChanged();

protected:
    void tick() override;

private:
    [[nodiscard]] static QStringList resolveToPhysicalDisks(const QString& devicePath);
    [[nodiscard]] static bool isPseudoFs(QByteArrayView fsType);
    [[nodiscard]] static bool sameOrder(const QList<DiskInfo*>& a, const QList<DiskInfo*>& b);

    static qsizetype disksCount(QQmlListProperty<DiskInfo>* prop);
    static DiskInfo* disksAt(QQmlListProperty<DiskInfo>* prop, qsizetype i);

    QList<DiskInfo*> m_disks;
    QPointer<DiskInfo> m_manualPrimaryDisk;
};

} // namespace caelestia::services
