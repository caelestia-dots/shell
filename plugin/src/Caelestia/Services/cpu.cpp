#include "cpu.hpp"

#include "sensorslib.hpp"

#include <cmath>
#include <qfile.h>
#include <qregularexpression.h>

namespace caelestia::services {

Cpu::Cpu(QObject* parent)
    : TickingService(parent) {
    readNameOnce();
}

QString Cpu::name() const {
    return m_name;
}

qreal Cpu::percentage() const {
    return m_percentage;
}

qreal Cpu::temperature() const {
    return m_temperature;
}

void Cpu::tick() {
    if (!m_nameLoaded) {
        readNameOnce();
    }
    refreshPercentage();
    refreshTemperature();
}

void Cpu::readNameOnce() {
    QFile f(QStringLiteral("/proc/cpuinfo"));
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return;
    }
    const QByteArray data = f.readAll();
    f.close();

    static const QRegularExpression re(QStringLiteral("model name\\s*:\\s*(.+)"));
    const auto match = re.match(QString::fromLatin1(data));
    if (!match.hasMatch()) {
        return;
    }

    const QString cleaned = cleanName(match.captured(1));
    m_nameLoaded = true;
    if (cleaned == m_name) {
        return;
    }
    m_name = cleaned;
    Q_EMIT nameChanged();
}

void Cpu::refreshPercentage() {
    QFile f(QStringLiteral("/proc/stat"));
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return;
    }
    const QByteArray data = f.readAll();
    f.close();

    static const QRegularExpression re(
        QStringLiteral("^cpu\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)"));
    const auto match = re.match(QString::fromLatin1(data));
    if (!match.hasMatch()) {
        return;
    }

    quint64 total = 0;
    quint64 idle = 0;
    for (int i = 1; i <= 7; ++i) {
        const quint64 v = match.captured(i).toULongLong();
        total += v;
        if (i == 4 || i == 5) {
            idle += v;
        }
    }

    const quint64 totalDiff = total > m_lastTotal ? total - m_lastTotal : 0;
    const quint64 idleDiff = idle > m_lastIdle ? idle - m_lastIdle : 0;
    const qreal newPerc = totalDiff > 0 ? 1.0 - static_cast<qreal>(idleDiff) / static_cast<qreal>(totalDiff) : 0.0;

    m_lastTotal = total;
    m_lastIdle = idle;

    if (std::abs(newPerc - m_percentage) > 0.0001) {
        m_percentage = newPerc;
        Q_EMIT percentageChanged();
    }
}

void Cpu::refreshTemperature() {
    const auto t = sensorslib::cpuPackageTemp();
    const qreal newTemp = t.value_or(0.0);
    if (std::abs(newTemp - m_temperature) > 0.05) {
        m_temperature = newTemp;
        Q_EMIT temperatureChanged();
    }
}

QString Cpu::cleanName(QString s) {
    static const QRegularExpression noise(
        QStringLiteral("\\(R\\)|\\(TM\\)|CPU|\\d+(?:th|nd|rd|st) Gen |Core |Processor"),
        QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression spaces(QStringLiteral("\\s+"));

    s.replace(noise, QString());
    s.replace(spaces, QStringLiteral(" "));
    return s.trimmed();
}

} // namespace caelestia::services
