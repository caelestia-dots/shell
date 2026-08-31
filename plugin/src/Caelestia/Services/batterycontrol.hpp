#pragma once

#include <qlist.h>
#include <qqmlintegration.h>
#include <qstring.h>

#include "tickingservice.hpp"

namespace caelestia::services {

class BatteryControl : public TickingService {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    enum class ControlType {
        Unsupported = 0,
        BinaryConservation,
        DiscreteTiers,
        ContinuousRange
    };
    Q_ENUM(ControlType)

    Q_PROPERTY(bool isSupported READ isSupported NOTIFY isSupportedChanged)
    Q_PROPERTY(ControlType controlType READ controlType NOTIFY controlTypeChanged)
    Q_PROPERTY(bool enabled READ enabled NOTIFY enabledChanged)
    Q_PROPERTY(int threshold READ threshold NOTIFY thresholdChanged)
    Q_PROPERTY(int minThreshold READ minThreshold CONSTANT)
    Q_PROPERTY(int maxThreshold READ maxThreshold CONSTANT)
    Q_PROPERTY(QList<int> supportedTiers READ supportedTiers NOTIFY supportedTiersChanged)
    Q_PROPERTY(QString title READ title NOTIFY titleChanged)
    Q_PROPERTY(QString subtitle READ subtitle NOTIFY subtitleChanged)
    Q_PROPERTY(QString path READ path NOTIFY pathChanged)

    explicit BatteryControl(QObject* parent = nullptr);

    [[nodiscard]] bool isSupported() const;
    [[nodiscard]] ControlType controlType() const;
    [[nodiscard]] bool enabled() const;
    [[nodiscard]] int threshold() const;
    [[nodiscard]] int minThreshold() const;
    [[nodiscard]] int maxThreshold() const;
    [[nodiscard]] QList<int> supportedTiers() const;
    [[nodiscard]] QString title() const;
    [[nodiscard]] QString subtitle() const;
    [[nodiscard]] QString path() const;

    Q_INVOKABLE void toggle();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void setEnabled(bool enabled);
    Q_INVOKABLE void setThreshold(int threshold);

signals:
    void isSupportedChanged();
    void controlTypeChanged();
    void enabledChanged();
    void thresholdChanged();
    void supportedTiersChanged();
    void titleChanged();
    void subtitleChanged();
    void pathChanged();

protected:
    void tick() override;

private:
    void detectInterface();
    void refreshState();
    bool writeValue(const QString& val);

    QString m_path;
    ControlType m_controlType = ControlType::Unsupported;
    bool m_isSupported = false;
    bool m_enabled = false;
    int m_threshold = 100;
    int m_minThreshold = 50;
    int m_maxThreshold = 100;
    QList<int> m_supportedTiers;
    QString m_title = QStringLiteral("Battery Control");
    QString m_subtitle;
};

} // namespace caelestia::services
