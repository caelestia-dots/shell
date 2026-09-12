#pragma once

#include <qlist.h>
#include <qprocess.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qtypes.h>

#include "tickingservice.hpp"

namespace caelestia::services {

class BatteryControl : public TickingService {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    enum class ControlType : quint8 {
        Unsupported = 0,
        BinaryConservation,
        DiscreteTiers,
        ContinuousRange
    };
    Q_ENUM(ControlType)

    Q_PROPERTY(bool isSupported READ isSupported NOTIFY isSupportedChanged)
    Q_PROPERTY(ControlType controlType READ controlType NOTIFY controlTypeChanged)
    Q_PROPERTY(bool isBinary READ isBinary NOTIFY controlTypeChanged)
    Q_PROPERTY(bool isTiers READ isTiers NOTIFY controlTypeChanged)
    Q_PROPERTY(bool isRange READ isRange NOTIFY controlTypeChanged)
    Q_PROPERTY(bool isReadOnly READ isReadOnly NOTIFY isReadOnlyChanged)
    Q_PROPERTY(bool enabled READ enabled NOTIFY enabledChanged)
    Q_PROPERTY(int threshold READ threshold NOTIFY thresholdChanged)
    Q_PROPERTY(int minThreshold READ minThreshold NOTIFY controlTypeChanged)
    Q_PROPERTY(int maxThreshold READ maxThreshold NOTIFY controlTypeChanged)
    Q_PROPERTY(int stepSize READ stepSize NOTIFY stepSizeChanged)
    Q_PROPERTY(QList<int> supportedTiers READ supportedTiers NOTIFY supportedTiersChanged)
    Q_PROPERTY(QString title READ title NOTIFY titleChanged)
    Q_PROPERTY(QString subtitle READ subtitle NOTIFY subtitleChanged)
    Q_PROPERTY(QString path READ path NOTIFY pathChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

    explicit BatteryControl(QObject* parent = nullptr);

    [[nodiscard]] bool isSupported() const;
    [[nodiscard]] ControlType controlType() const;
    [[nodiscard]] bool isBinary() const;
    [[nodiscard]] bool isTiers() const;
    [[nodiscard]] bool isRange() const;
    [[nodiscard]] bool isReadOnly() const;
    [[nodiscard]] bool enabled() const;
    [[nodiscard]] int threshold() const;
    [[nodiscard]] int minThreshold() const;
    [[nodiscard]] int maxThreshold() const;
    [[nodiscard]] int stepSize() const;
    [[nodiscard]] QList<int> supportedTiers() const;
    [[nodiscard]] QString title() const;
    [[nodiscard]] QString subtitle() const;
    [[nodiscard]] QString path() const;
    [[nodiscard]] QString error() const;
    [[nodiscard]] QString lastError() const;
    [[nodiscard]] bool busy() const;

    Q_INVOKABLE void toggle();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void retry();
    Q_INVOKABLE void setEnabled(bool enabled);
    Q_INVOKABLE void setThreshold(int threshold);

signals:
    void isSupportedChanged();
    void controlTypeChanged();
    void isReadOnlyChanged();
    void enabledChanged();
    void thresholdChanged();
    void stepSizeChanged();
    void supportedTiersChanged();
    void titleChanged();
    void subtitleChanged();
    void pathChanged();
    void errorChanged();
    void lastErrorChanged();
    void busyChanged();

protected:
    void tick() override;

private:
    void detectInterface();
    void refreshState();
    bool writeValue(const QString& val);
    void handlePkexecFinished(QProcess* proc, int exitCode, QProcess::ExitStatus exitStatus);
    [[nodiscard]] QString currentControlValue() const;
    void setError(const QString& error);
    void setBusy(bool busy);

    QString m_path;
    ControlType m_controlType = ControlType::Unsupported;
    bool m_isSupported = false;
    bool m_isReadOnly = false;
    bool m_enabled = false;
    int m_threshold = 100;
    int m_minThreshold = 50;
    int m_maxThreshold = 100;
    int m_stepSize = 1;
    QList<int> m_supportedTiers;
    QString m_title = QStringLiteral("Battery Control");
    QString m_subtitle;
    QString m_error;
    QString m_lastError;
    QString m_lastAttemptedValue;
    QString m_queuedValue;
    bool m_busy = false;
};

} // namespace caelestia::services
