#pragma once

#include <qelapsedtimer.h>
#include <qhash.h>
#include <qprocess.h>
#include <qqmlintegration.h>
#include <qstringlist.h>

#include "config/enums.hpp"
#include "tickingservice.hpp"

namespace caelestia::services {

using GpuType = config::GpuType::Enum;

class Gpu : public TickingService {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(caelestia::config::GpuType::Enum type READ type NOTIFY typeChanged)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(bool detecting READ detecting NOTIFY detectingChanged)
    Q_PROPERTY(qreal percentage READ percentage NOTIFY percentageChanged)
    Q_PROPERTY(qreal temperature READ temperature NOTIFY temperatureChanged)

public:
    explicit Gpu(QObject* parent = nullptr);

    [[nodiscard]] GpuType type() const;
    [[nodiscard]] QString name() const;
    [[nodiscard]] bool detecting() const;
    [[nodiscard]] qreal percentage() const;
    [[nodiscard]] qreal temperature() const;

signals:
    void typeChanged();
    void nameChanged();
    void detectingChanged();
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
    void readFdinfoUsage();
    void startNvidiaUsage();
    void readGpuTemperature();
    void resetUsage();

    // Runs a one-shot process, delivering its stdout to callback exactly once (empty
    // output if it fails, crashes or never starts), then tears the process down.
    void runProcess(const QString& program, const QStringList& args, std::function<void(const QByteArray&)> callback);

    void setType(GpuType value);
    void setName(QString value);
    void setDetecting(bool value);

    // The config override, Auto meaning "resolve by probing". Read only to decide
    // whether to probe and which name sources apply; never exposed.
    GpuType m_userType = GpuType::Auto;
    GpuType m_type = GpuType::None;
    // The raw device name, empty while detecting and when there is no GPU to name
    QString m_name;
    bool m_detecting = false;
    qreal m_percentage = 0.0;
    qreal m_temperature = 0.0;

    // /sys/class/drm card busy files, enumerated once at construction (the card
    // set is static at runtime) and reused by resolution and the tick path.
    QStringList m_busyFiles;

    // Usage backend chosen during resolution. Generic covers both the sysfs busy
    // file exposed by amdgpu and the fdinfo engine counters used by Intel iGPUs.
    enum class UsageBackend {
        None,
        BusyFile,
        Fdinfo,
        Nvidia
    };
    UsageBackend m_backend = UsageBackend::None;

    // Last per-client engine counters, used to turn the monotonic fdinfo values
    // into a usage percentage.
    QHash<qint64, QHash<QString, quint64>> m_fdinfoClients;
    QElapsedTimer m_fdinfoTimer;

    // Bumped per resolution so callbacks from a superseded probe are dropped
    int m_generation = 0;
    bool m_nvidiaQuerying = false;
};

} // namespace caelestia::services
