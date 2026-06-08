#include "storage.hpp"

#include <algorithm>
#include <cmath>
#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qhash.h>
#include <qloggingcategory.h>
#include <qstorageinfo.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>

Q_LOGGING_CATEGORY(lcStorage, "caelestia.services.storage", QtInfoMsg)

namespace caelestia::services {

namespace {

struct Accum {
    quint64 usedBytes = 0;
    quint64 totalBytes = 0;
    bool hasRoot = false;
};

[[nodiscard]] QString sysfsRealPath(uint major, uint minor) {
    const QString link = QStringLiteral("/sys/dev/block/%1:%2").arg(major).arg(minor);
    const QString resolved = QFileInfo(link).canonicalFilePath();
    return resolved;
}

[[nodiscard]] bool readDevtFromSysfs(const QString& sysfsBlockDir, uint& major, uint& minor) {
    QFile f(sysfsBlockDir + QStringLiteral("/dev"));
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return false;
    }
    const QByteArray line = f.readLine().trimmed();
    f.close();

    const qsizetype colon = line.indexOf(':');
    if (colon <= 0) {
        return false;
    }
    bool okM = false;
    bool okN = false;
    major = line.left(colon).toUInt(&okM);
    minor = line.mid(colon + 1).toUInt(&okN);
    return okM && okN;
}

QStringList resolveByDevt(uint major, uint minor, int depth = 0);

QStringList resolveAtNode(const QString& node, int depth) {
    if (node.isEmpty() || depth > 8) {
        return {};
    }

    const QFileInfo nodeInfo(node);
    if (!nodeInfo.exists() || !nodeInfo.isDir()) {
        return {};
    }

    if (QFileInfo::exists(node + QStringLiteral("/partition"))) {
        const QString diskNode = nodeInfo.path();
        return { QFileInfo(diskNode).fileName() };
    }

    const QDir slavesDir(node + QStringLiteral("/slaves"));
    if (slavesDir.exists()) {
        const QStringList slaves = slavesDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        if (!slaves.isEmpty()) {
            QStringList out;
            for (const QString& slave : slaves) {
                uint sm = 0;
                uint sn = 0;
                const QString slaveDir = QStringLiteral("/sys/class/block/") + slave;
                if (!readDevtFromSysfs(slaveDir, sm, sn)) {
                    continue;
                }
                const auto devs = resolveByDevt(sm, sn, depth + 1);
                for (const QString& d : devs) {
                    if (!out.contains(d)) {
                        out.append(d);
                    }
                }
            }
            return out;
        }
    }

    return { nodeInfo.fileName() };
}

QStringList resolveByDevt(uint major, uint minor, int depth) {
    return resolveAtNode(sysfsRealPath(major, minor), depth);
}

} // namespace

Storage::Storage(QObject* parent)
    : TickingService(parent) {}

qreal Storage::percentage() const {
    qreal totalUsed = 0.0;
    qreal totalSize = 0.0;
    for (const DiskInfo* d : m_disks) {
        totalUsed += d->used();
        totalSize += d->total();
    }
    return totalSize > 0.0 ? totalUsed / totalSize : 0.0;
}

bool Storage::sameOrder(const QList<DiskInfo*>& a, const QList<DiskInfo*>& b) {
    if (a.size() != b.size()) {
        return false;
    }
    for (qsizetype i = 0; i < a.size(); ++i) {
        if (a.at(i) != b.at(i)) {
            return false;
        }
    }
    return true;
}

QQmlListProperty<DiskInfo> Storage::disksProp() {
    return QQmlListProperty<DiskInfo>(this, nullptr, &Storage::disksCount, &Storage::disksAt);
}

qsizetype Storage::disksCount(QQmlListProperty<DiskInfo>* prop) {
    return static_cast<Storage*>(prop->object)->m_disks.size();
}

DiskInfo* Storage::disksAt(QQmlListProperty<DiskInfo>* prop, qsizetype i) {
    return static_cast<Storage*>(prop->object)->m_disks.at(i);
}

DiskInfo* Storage::manualPrimaryDisk() const {
    return m_manualPrimaryDisk.data();
}

void Storage::setManualPrimaryDisk(DiskInfo* disk) {
    if (m_manualPrimaryDisk.data() == disk) {
        return;
    }
    m_manualPrimaryDisk = disk;
    Q_EMIT manualPrimaryDiskChanged();
    Q_EMIT primaryDiskChanged();
}

DiskInfo* Storage::primaryDisk() const {
    if (auto* m = m_manualPrimaryDisk.data()) {
        return m;
    }
    return m_disks.isEmpty() ? nullptr : m_disks.first();
}

bool Storage::isPseudoFs(QByteArrayView fsType) {
    static constexpr const char* kPseudo[] = {
        "tmpfs",
        "devtmpfs",
        "proc",
        "sysfs",
        "cgroup",
        "cgroup2",
        "overlay",
        "squashfs",
        "devpts",
        "mqueue",
        "ramfs",
        "rpc_pipefs",
        "autofs",
        "configfs",
        "debugfs",
        "tracefs",
        "securityfs",
        "pstore",
        "bpf",
        "binfmt_misc",
        "hugetlbfs",
        "fusectl",
        "efivarfs",
        "selinuxfs",
    };
    for (const char* p : kPseudo) {
        if (fsType == QByteArrayView(p)) {
            return true;
        }
    }
    return fsType.startsWith(QByteArrayView("fuse."));
}

QStringList Storage::resolveToPhysicalDisks(const QString& devicePath) {
    if (devicePath.isEmpty() || !devicePath.startsWith(QLatin1Char('/'))) {
        return {};
    }
    struct stat st{};
    if (::stat(devicePath.toLocal8Bit().constData(), &st) != 0) {
        return {};
    }
    if (!S_ISBLK(st.st_mode)) {
        return {};
    }
    return resolveByDevt(major(st.st_rdev), minor(st.st_rdev));
}

void Storage::tick() {
    const qreal prevPercentage = percentage();
    QHash<QString, Accum> byDisk;

    // Multiple mounts can share a single backing filesystem (btrfs subvolumes,
    // bind mounts, etc.) and each one reports identical bytesTotal/bytesAvailable.
    // Dedupe by source device so the filesystem only contributes once per disk.
    struct DeviceEntry {
        quint64 totalBytes = 0;
        quint64 usedBytes = 0;
        bool hasRoot = false;
        QByteArray device;
    };

    QHash<QByteArray, DeviceEntry> byDevice;

    const auto mountedVols = QStorageInfo::mountedVolumes();
    for (const QStorageInfo& v : mountedVols) {
        if (!v.isReady() || !v.isValid() || v.bytesTotal() <= 0) {
            continue;
        }
        if (isPseudoFs(QByteArrayView(v.fileSystemType()))) {
            continue;
        }

        const QByteArray device = v.device();
        const auto totalBytes = static_cast<quint64>(v.bytesTotal());
        const auto availBytes = static_cast<quint64>(v.bytesAvailable());
        const quint64 usedBytes = totalBytes > availBytes ? totalBytes - availBytes : 0;
        const bool isRoot = v.rootPath() == QStringLiteral("/");

        DeviceEntry& e = byDevice[device];
        e.device = device;
        e.totalBytes = totalBytes;
        e.usedBytes = usedBytes;
        e.hasRoot = e.hasRoot || isRoot;
    }

    for (auto it = byDevice.constBegin(); it != byDevice.constEnd(); ++it) {
        const DeviceEntry& e = it.value();
        const QStringList disks = resolveToPhysicalDisks(QString::fromLocal8Bit(e.device));
        if (disks.isEmpty()) {
            continue;
        }
        for (const QString& d : disks) {
            if (d.startsWith(QStringLiteral("zram"))) {
                continue;
            }
            Accum& a = byDisk[d];
            a.usedBytes += e.usedBytes;
            a.totalBytes += e.totalBytes;
            a.hasRoot = a.hasRoot || e.hasRoot;
        }
    }

    QHash<QString, DiskInfo*> existing;
    existing.reserve(m_disks.size());
    for (DiskInfo* d : std::as_const(m_disks)) {
        existing.insert(d->mount(), d);
    }

    QList<DiskInfo*> next;
    next.reserve(byDisk.size());
    for (auto it = byDisk.constBegin(); it != byDisk.constEnd(); ++it) {
        if (DiskInfo* survivor = existing.take(it.key())) {
            survivor->update(it.value().usedBytes, it.value().totalBytes, it.value().hasRoot);
            next.append(survivor);
        } else {
            next.append(new DiskInfo(it.key(), it.value().usedBytes, it.value().totalBytes, it.value().hasRoot, this));
        }
    }

    std::sort(next.begin(), next.end(), [](const DiskInfo* a, const DiskInfo* b) {
        if (a->hasRoot() != b->hasRoot()) {
            return a->hasRoot();
        }
        return a->mount() < b->mount();
    });

    bool manualCleared = false;
    if (DiskInfo* m = m_manualPrimaryDisk.data(); m && existing.contains(m->mount())) {
        m_manualPrimaryDisk.clear();
        manualCleared = true;
    }
    for (DiskInfo* stale : std::as_const(existing)) {
        stale->deleteLater();
    }

    const bool listChanged = !sameOrder(m_disks, next);
    DiskInfo* prevPrimary = primaryDisk();
    m_disks = next;

    if (listChanged) {
        Q_EMIT disksChanged();
    }
    if (std::abs(percentage() - prevPercentage) > 0.0001) {
        Q_EMIT percentageChanged();
    }
    if (manualCleared) {
        Q_EMIT manualPrimaryDiskChanged();
    }
    if (primaryDisk() != prevPrimary) {
        Q_EMIT primaryDiskChanged();
    }
}

} // namespace caelestia::services
