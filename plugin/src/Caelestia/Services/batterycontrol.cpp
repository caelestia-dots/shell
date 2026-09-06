#include "batterycontrol.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qloggingcategory.h>
#include <qprocess.h>
#include <qtextstream.h>

#include <algorithm>
#include <utility>

namespace {

Q_LOGGING_CATEGORY(lcBatteryControl, "caelestia.services.batterycontrol", QtInfoMsg)

bool isSafeSysfsPath(const QString& path) {
    const bool prefixOk = path.startsWith(QStringLiteral("/sys/bus/platform/drivers/ideapad_acpi/")) ||
                          path.startsWith(QStringLiteral("/sys/devices/platform/")) ||
                          path.startsWith(QStringLiteral("/sys/class/power_supply/"));
    if (!prefixOk) {
        return false;
    }
    if (path.contains(QStringLiteral(".."))) {
        return false;
    }
    return std::ranges::all_of(path, [](const QChar& c) {
        const char16_t u = c.unicode();
        return (u >= u'a' && u <= u'z') || (u >= u'A' && u <= u'Z') || (u >= u'0' && u <= u'9') || u == u'/' ||
               u == u'_' || u == u'-' || u == u'.' || u == u':';
    });
}

bool isSafeValue(const QString& val) {
    if (val.isEmpty() || val.size() > 3) {
        return false;
    }
    return std::ranges::all_of(val, [](const QChar& c) {
        return c.isDigit();
    });
}

} // namespace

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

bool BatteryControl::isBinary() const {
    return m_controlType == ControlType::BinaryConservation;
}

bool BatteryControl::isTiers() const {
    return m_controlType == ControlType::DiscreteTiers;
}

bool BatteryControl::isRange() const {
    return m_controlType == ControlType::ContinuousRange;
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

int BatteryControl::stepSize() const {
    return m_stepSize;
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

QString BatteryControl::error() const {
    return m_error;
}

QString BatteryControl::lastError() const {
    return m_lastError;
}

bool BatteryControl::busy() const {
    return m_busy;
}

void BatteryControl::setError(const QString& error) {
    if (m_error != error) {
        m_error = error;
        emit errorChanged();
    }
    if (!error.isEmpty() && m_lastError != error) {
        m_lastError = error;
        emit lastErrorChanged();
    }
}

void BatteryControl::setBusy(bool busy) {
    if (m_busy != busy) {
        m_busy = busy;
        emit busyChanged();
    }
}

void BatteryControl::detectInterface() {
    auto check = [this](const QString& path, ControlType type, const QString& title, const QList<int>& tiers = {},
                     int minThresh = 50, int maxThresh = 100, int stepSize = 1) -> bool {
        if (!QFile::exists(path)) {
            return false;
        }

        m_path = path;
        m_controlType = type;
        m_title = title;
        m_supportedTiers = tiers;
        m_minThreshold = minThresh;
        m_maxThreshold = maxThresh;
        m_stepSize = std::max(1, stepSize);
        m_isSupported = true;
        return true;
    };

    // 1. Lenovo IdeaPad / LOQ / Legion conservation mode
    if (check(QStringLiteral("/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"),
            ControlType::BinaryConservation, QStringLiteral("Conservation Mode"))) {
        return;
    }

    // 2. Asus WMI discrete threshold (60%, 80%, 100%)
    if (check(QStringLiteral("/sys/devices/platform/asus-nb-wmi/charge_control_end_threshold"),
            ControlType::DiscreteTiers, QStringLiteral("Battery Care Limit"), { 60, 80, 100 })) {
        return;
    }

    // 3. LG Laptop battery care limit (80%, 100%)
    if (check(QStringLiteral("/sys/devices/platform/lg-laptop/battery_care_limit"), ControlType::DiscreteTiers,
            QStringLiteral("Battery Care Limit"), { 80, 100 })) {
        return;
    }

    // 4. Samsung battery life extender
    if (check(QStringLiteral("/sys/devices/platform/samsung/battery_life_extender"), ControlType::BinaryConservation,
            QStringLiteral("Battery Life Extender"))) {
        return;
    }

    // 5. Standard Linux power supply charge control end threshold (ThinkPad, Framework, Dell, etc.)
    const QDir powerSupplyDir(QStringLiteral("/sys/class/power_supply"));
    const QStringList batteries = powerSupplyDir.entryList(
        { QStringLiteral("BAT*"), QStringLiteral("battery*") }, QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString& bat : std::as_const(batteries)) {
        const QString threshPath = QStringLiteral("/sys/class/power_supply/%1/charge_control_end_threshold").arg(bat);
        if (check(threshPath, ControlType::ContinuousRange, QStringLiteral("Charge Limit"), { 60, 80, 100 }, 50, 100,
                5)) {
            return;
        }
    }
}

void BatteryControl::refresh() {
    m_lastAttemptedValue.clear();
    setError(QString());
    refreshState();
}

void BatteryControl::retry() {
    if (!m_lastAttemptedValue.isEmpty()) {
        writeValue(m_lastAttemptedValue);
    } else {
        refresh();
    }
}

void BatteryControl::refreshState() {
    if (!m_isSupported || m_path.isEmpty()) {
        return;
    }

    QFile file(m_path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        setError(QStringLiteral("cannot open %1: %2").arg(m_path, file.errorString()));
        return;
    }

    const QString content = QString::fromUtf8(file.readAll()).trimmed();
    file.close();

    bool ok = false;
    const int val = content.toInt(&ok);
    if (!ok) {
        setError(QStringLiteral("invalid value in %1: %2").arg(m_path, content));
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
        newSubtitle =
            newEnabled ? QStringLiteral("Capped at %1%").arg(newThreshold) : QStringLiteral("Charges to 100%");
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

    if (m_lastAttemptedValue.isEmpty() || content == m_lastAttemptedValue ||
        QString::number(val) == m_lastAttemptedValue) {
        m_lastAttemptedValue.clear();
        setError(QString());
    }
}

bool BatteryControl::writeValue(const QString& val) {
    if (!m_isSupported || m_path.isEmpty()) {
        setError(QStringLiteral("battery control not supported"));
        return false;
    }

    if (!isSafeValue(val)) {
        qCWarning(lcBatteryControl) << "Refusing to write unsafe value to" << m_path;
        return false;
    }
    if (!isSafeSysfsPath(m_path)) {
        qCWarning(lcBatteryControl) << "Refusing to write to unexpected sysfs path:" << m_path;
        return false;
    }

    if (m_busy) {
        m_queuedValue = val;
        m_lastAttemptedValue = val;
        return false;
    }

    m_lastAttemptedValue = val;

    // 1. Attempt direct unprivileged write first (fast path when udev rule is installed)
    QFile file(m_path);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        QTextStream out(&file);
        out << val << "\n";
        file.close();
        m_lastAttemptedValue.clear();
        refreshState();
        return true;
    }

    // 2. Privilege escalation fallback: run via pkexec so the system polkit agent pops up a password dialog.
    // Hardened: argument-vector form (no shell), value via stdin, path validated, exit code checked.

    auto* proc = new QProcess(this);
    proc->setProgram(QStringLiteral("pkexec"));
    proc->setArguments({ QStringLiteral("tee"), m_path });
    proc->setStandardOutputFile(QProcess::nullDevice());
    proc->setProcessEnvironment(QProcessEnvironment::systemEnvironment());

    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
        [this, proc](int exitCode, QProcess::ExitStatus exitStatus) {
            handlePkexecFinished(proc, exitCode, exitStatus);
        });
    connect(proc, &QProcess::errorOccurred, this, [this, proc](QProcess::ProcessError err) {
        if (err == QProcess::FailedToStart) {
            qCWarning(lcBatteryControl) << "pkexec failed to start:" << proc->errorString();
            setError(QStringLiteral("pkexec failed to start: %1").arg(proc->errorString()));
            m_queuedValue.clear();
            setBusy(false);
            proc->deleteLater();
        }
        // Other errors are reported via finished().
    });

    setBusy(true);
    proc->start();
    proc->write(val.toUtf8() + '\n');
    proc->closeWriteChannel();
    return true;
}

QString BatteryControl::currentControlValue() const {
    if (m_controlType == ControlType::BinaryConservation) {
        return m_enabled ? QStringLiteral("1") : QStringLiteral("0");
    }
    return QString::number(m_threshold);
}

void BatteryControl::handlePkexecFinished(QProcess* proc, int exitCode, QProcess::ExitStatus exitStatus) {
    const QString err = QString::fromUtf8(proc->readAllStandardError()).trimmed();
    if (exitStatus != QProcess::NormalExit || exitCode != 0) {
        qCWarning(lcBatteryControl) << "pkexec tee failed:" << exitCode << err;
        setError(QStringLiteral("Write failed: %1").arg(err.isEmpty() ? QString::number(exitCode) : err));
        m_queuedValue.clear();
        setBusy(false);
    } else {
        if (!err.isEmpty()) {
            qCWarning(lcBatteryControl) << "pkexec tee stderr:" << err;
        }
        m_lastAttemptedValue.clear();
        refreshState();
        setBusy(false);
        if (!m_queuedValue.isEmpty()) {
            const QString nextVal = m_queuedValue;
            m_queuedValue.clear();
            if (nextVal != currentControlValue()) {
                writeValue(nextVal);
            }
        }
    }
    proc->deleteLater();
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
    if (!m_isSupported || m_path.isEmpty()) {
        return;
    }

    int val = threshold;
    if (m_stepSize > 1) {
        val = static_cast<int>(std::round(static_cast<double>(threshold) / m_stepSize)) * m_stepSize;
    }
    val = std::clamp(val, m_minThreshold, m_maxThreshold);

    if (val == m_threshold) {
        return;
    }

    writeValue(QString::number(val));
}

} // namespace caelestia::services
