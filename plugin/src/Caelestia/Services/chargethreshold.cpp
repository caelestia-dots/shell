#include "chargethreshold.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>

namespace caelestia::services {

ChargeThreshold::ChargeThreshold(QObject* parent)
    : TickingService(parent) {}

int ChargeThreshold::threshold() const {
    return m_threshold;
}

qreal ChargeThreshold::limit() const {
    return m_threshold / 100.0;
}

bool ChargeThreshold::isLimited() const {
    return m_threshold > 0 && m_threshold < 100;
}

void ChargeThreshold::tick() {
    if (m_path.isEmpty()) {
        resolvePath();
    }
    if (m_path.isEmpty()) {
        updateThreshold(100);
        return;
    }

    QFile f(m_path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        m_path.clear();
        updateThreshold(100);
        return;
    }
    bool ok = false;
    const int threshold = f.readAll().trimmed().toInt(&ok);
    f.close();

    updateThreshold(ok && threshold > 0 ? threshold : 100);
}

void ChargeThreshold::resolvePath() {
    static const QString files[] = { QStringLiteral("charge_control_end_threshold"),
        QStringLiteral("charge_stop_threshold") };

    const QDir root(QStringLiteral("/sys/class/power_supply"));
    const QStringList supplies = root.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString& file : files) {
        for (const QString& supply : supplies) {
            const QString path = root.filePath(supply + QLatin1Char('/') + file);
            if (QFileInfo(path).isReadable()) {
                m_path = path;
                return;
            }
        }
    }
}

void ChargeThreshold::updateThreshold(int threshold) {
    if (m_threshold == threshold) {
        return;
    }
    m_threshold = threshold;
    emit thresholdChanged();
}

} // namespace caelestia::services
