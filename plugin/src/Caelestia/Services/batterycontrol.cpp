#include "batterycontrol.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qprocess.h>
#include <qtextstream.h>
#include <qtimer.h>

namespace caelestia::services {

BatteryControl::BatteryControl(QObject* parent)
    : TickingService(parent) {
    detectInterface();
    if (m_isSupported) {
        refreshState();
    }
}

void BatteryControl::tick() {
    refreshState();
}

bool BatteryControl::isSupported() const {
    return m_isSupported;
}

BatteryControl::ControlType BatteryControl::controlType() const {
    return m_controlType;
}

bool BatteryControl::enabled() const {
    return m_enabled;
}

int BatteryControl::threshold() const {
    return m_threshold;
}

int BatteryControl::minThreshold() const {
    return m_minThreshold;
}

int BatteryControl::maxThreshold() const {
    return m_maxThreshold;
}

QList<int> BatteryControl::supportedTiers() const {
    return m_supportedTiers;
}

QString BatteryControl::title() const {
    return m_title;
}

QString BatteryControl::subtitle() const {
    return m_subtitle;
}

QString BatteryControl::path() const {
    return m_path;
}

void BatteryControl::detectInterface() {
    auto check = [this](const QString& path,
                        ControlType type,
                        const QString& title,
                        const QList<int>& tiers = {},
                        int minThresh = 50,
                        int maxThresh = 100) -> bool {
        if (!QFile::exists(path)) {
            return false;
        }

        m_path = path;
        m_controlType = type;
        m_title = title;
        m_supportedTiers = tiers;
        m_minThreshold = minThresh;
        m_maxThreshold = maxThresh;
        m_isSupported = true;
        return true;
    };

    // 1. Lenovo IdeaPad / LOQ / Legion conservation mode
    if (check(QStringLiteral("/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"),
              ControlType::BinaryConservation,
              QStringLiteral("Conservation Mode"))) {
        return;
    }

    // 2. Asus WMI discrete threshold (60%, 80%, 100%)
    if (check(QStringLiteral("/sys/devices/platform/asus-nb-wmi/charge_control_end_threshold"),
              ControlType::DiscreteTiers,
              QStringLiteral("Battery Care Limit"),
              { 60, 80, 100 })) {
        return;
    }

    // 3. LG Laptop battery care limit (80%, 100%)
    if (check(QStringLiteral("/sys/devices/platform/lg-laptop/battery_care_limit"),
              ControlType::DiscreteTiers,
              QStringLiteral("Battery Care Limit"),
              { 80, 100 })) {
        return;
    }

    // 4. Samsung battery life extender
    if (check(QStringLiteral("/sys/devices/platform/samsung/battery_life_extender"),
              ControlType::BinaryConservation,
              QStringLiteral("Battery Life Extender"))) {
        return;
    }

    // 5. Standard Linux power supply charge control end threshold (ThinkPad, Framework, Dell, etc.)
    const QDir powerSupplyDir(QStringLiteral("/sys/class/power_supply"));
    const QStringList batteries = powerSupplyDir.entryList(
        { QStringLiteral("BAT*"), QStringLiteral("battery*") }, QDir::Dirs | QDir::NoDotAndDotDot);
    for (const auto& bat : batteries) {
        const QString threshPath = QStringLiteral("/sys/class/power_supply/%1/charge_control_end_threshold").arg(bat);
        if (check(threshPath,
                  ControlType::ContinuousRange,
                  QStringLiteral("Charge Limit"),
                  { 60, 80, 100 },
                  50,
                  100)) {
            return;
        }
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
    QString newSubtitle;

    if (m_controlType == ControlType::BinaryConservation) {
        newEnabled = (val == 1);
        newThreshold = newEnabled ? 60 : 100;
        newSubtitle = newEnabled ? QStringLiteral("Capped at ~60%") : QStringLiteral("Charges to 100%");
    } else {
        newThreshold = val;
        newEnabled = (val > 0 && val < 100);
        newSubtitle = newEnabled ? QStringLiteral("Capped at %1%").arg(newThreshold) : QStringLiteral("Charges to 100%");
    }

    if (m_enabled != newEnabled) {
        m_enabled = newEnabled;
        emit enabledChanged();
    }

    if (m_threshold != newThreshold) {
        m_threshold = newThreshold;
        emit thresholdChanged();
    }

    if (m_subtitle != newSubtitle) {
        m_subtitle = newSubtitle;
        emit subtitleChanged();
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
    proc->setProcessEnvironment(QProcessEnvironment::systemEnvironment());
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [this, proc](int, QProcess::ExitStatus) {
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

    if (m_controlType == ControlType::BinaryConservation) {
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
