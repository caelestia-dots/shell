#pragma once

#include "../Config/enums.hpp"
#include "tickingservice.hpp"

#include <qprocess.h>
#include <qqmlintegration.h>
#include <qstringlist.h>

namespace caelestia::services {

using GpuType = config::GpuType::Enum;

class Gpu : public TickingService {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(caelestia::config::GpuType::Enum type READ type NOTIFY typeChanged)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(qreal percentage READ percentage NOTIFY percentageChanged)
    Q_PROPERTY(qreal temperature READ temperature NOTIFY temperatureChanged)

public:
    explicit Gpu(QObject* parent = nullptr);

    [[nodiscard]] GpuType type() const;
    [[nodiscard]] QString name() const;
    [[nodiscard]] qreal percentage() const;
    [[nodiscard]] qreal temperature() const;

signals:
    void typeChanged();
    void nameChanged();
    void percentageChanged();
    void temperatureChanged();

protected:
    void tick() override;

private:
    // Applies the user override, or probes for the type when it is Auto. Supersedes any
    // chain still in flight and drops the old name until the new source answers.
    void resolveGpu();

    // One past the last name source the running chain may advance to
    [[nodiscard]] int probeEnd() const;

    void tryNameSource(int index, int generation);
    void finishNameSource(int index, int generation, QString name);

    void readGenericUsage();
    void startNvidiaUsage();
    void readGpuTemperature();
    void resetUsage();

    // Runs a one-shot process, delivering its stdout to callback exactly once (empty
    // output if it fails, crashes or never starts), then tears the process down.
    void runProcess(const QString& program, const QStringList& args, std::function<void(const QByteArray&)> callback);

    void setType(GpuType value);
    void setName(QString value);

    // The config override, Auto meaning "resolve by probing". Read only to decide
    // whether to probe and which name sources apply; never exposed.
    GpuType m_userType = GpuType::Auto;
    GpuType m_type = GpuType::None;
    QString m_name;
    qreal m_percentage = 0.0;
    qreal m_temperature = 0.0;

    // /sys/class/drm card busy files, enumerated once at construction (the card
    // set is static at runtime) and reused by resolution and the tick path.
    QStringList m_busyFiles;

    // Bumped per resolution so callbacks from a superseded probe are dropped
    int m_generation = 0;
    bool m_nvidiaQuerying = false;
};

} // namespace caelestia::services
