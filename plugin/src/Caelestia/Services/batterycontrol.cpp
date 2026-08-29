#include "batterycontrol.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qprocess.h>
#include <qtextstream.h>
#include <qtimer.h>

namespace caelestia::services {

BatteryControl::BatteryControl(QObject* parent)
    : Service(parent)
    , m_watcher(new QFileSystemWatcher(this)) {
    detectInterface();
    if (m_isSupported) {
        refreshState();
        m_watcher->addPath(m_path);
        connect(m_watcher, &QFileSystemWatcher::fileChanged, this, [this](const QString& path) {
            refreshState();
            if (!m_watcher->files().contains(path) && QFile::exists(path)) {
                m_watcher->addPath(path);
            }
        });
    }
}

bool BatteryControl::isSupported() const {
    return m_isSupported;
}

bool BatteryControl::enabled() const {
    return m_enabled;
}

int BatteryControl::threshold() const {
    return m_threshold;
}

QString BatteryControl::path() const {
    return m_path;
}

void BatteryControl::detectInterface() {
    auto checkPath = [this](const QString& path, bool isConservation) -> bool {
        if (!QFile::exists(path)) {
            return false;
        }

        m_path = path;
        m_isConservationMode = isConservation;
        m_isSupported = true;
        return true;
    };

    // 1. Lenovo IdeaPad conservation mode
    if (checkPath(QStringLiteral("/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"), true)) {
        return;
    }

    // 2. Standard Linux power supply charge control end threshold (BAT0, BAT1, BATC, BATT, etc.)
    const QDir powerSupplyDir(QStringLiteral("/sys/class/power_supply"));
    const QStringList batteries = powerSupplyDir.entryList(
        { QStringLiteral("BAT*"), QStringLiteral("battery*") }, QDir::Dirs | QDir::NoDotAndDotDot);
    for (const auto& bat : batteries) {
        if (checkPath(QStringLiteral("/sys/class/power_supply/%1/charge_control_end_threshold").arg(bat), false)) {
            return;
        }
    }

    // 3. Asus WMI threshold
    if (checkPath(QStringLiteral("/sys/devices/platform/asus-nb-wmi/charge_control_end_threshold"), false)) {
        return;
    }

    // 4. Huawei WMI thresholds
    if (checkPath(QStringLiteral("/sys/devices/platform/huawei-wmi/charge_control_thresholds"), false)) {
        return;
    }

    // 5. LG Laptop battery care limit
    if (checkPath(QStringLiteral("/sys/devices/platform/lg-laptop/battery_care_limit"), false)) {
        return;
    }

    // 6. Samsung battery life extender
    if (checkPath(QStringLiteral("/sys/devices/platform/samsung/battery_life_extender"), true)) {
        return;
    }
}

void BatteryControl::refresh() {
    refreshState();
}

void BatteryControl::refreshState() {
    if (!m_isSupported || m_path.isEmpty()) {
        return;
    }

    QFile file(m_path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return;
    }

    const QString content = QString::fromUtf8(file.readAll()).trimmed();
    file.close();

    bool ok = false;
    const int val = content.toInt(&ok);
    if (!ok) {
        return;
    }

    bool newEnabled = false;
    int newThreshold = 100;

    if (m_isConservationMode) {
        newEnabled = (val == 1);
        newThreshold = newEnabled ? 60 : 100;
    } else {
        newThreshold = val;
        newEnabled = (val > 0 && val < 100);
    }

    if (m_enabled != newEnabled) {
        m_enabled = newEnabled;
        emit enabledChanged();
    }

    if (m_threshold != newThreshold) {
        m_threshold = newThreshold;
        emit thresholdChanged();
    }
}

bool BatteryControl::writeValue(const QString& val) {
    if (!m_isSupported || m_path.isEmpty()) {
        return false;
    }

    // 1. Attempt direct unprivileged write first (fast path when udev rule is installed)
    QFile file(m_path);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        QTextStream out(&file);
        out << val << "\n";
        file.close();
        refreshState();
        return true;
    }

    // 2. Privilege escalation fallback: run via pkexec so the system polkit agent pops up a password dialog
    const QString cmd = QStringLiteral("echo %1 | pkexec tee %2 > /dev/null").arg(val, m_path);
    auto* proc = new QProcess(this);
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [this, proc]() {
        refreshState();
        proc->deleteLater();
    });
    proc->start(QStringLiteral("sh"), { QStringLiteral("-c"), cmd });
    return true;
}

void BatteryControl::toggle() {
    if (!m_isSupported) {
        return;
    }

    if (m_isConservationMode) {
        writeValue(m_enabled ? QStringLiteral("0") : QStringLiteral("1"));
    } else {
        writeValue(m_enabled ? QStringLiteral("100") : QStringLiteral("80"));
    }
}

void BatteryControl::setEnabled(bool enabled) {
    if (!m_isSupported || m_enabled == enabled) {
        return;
    }
    toggle();
}

void BatteryControl::setThreshold(int threshold) {
    if (!m_isSupported) {
        return;
    }
    writeValue(QString::number(threshold));
}

} // namespace caelestia::services
