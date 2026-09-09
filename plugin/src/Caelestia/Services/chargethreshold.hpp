#pragma once

#include <qqmlintegration.h>

#include "tickingservice.hpp"

namespace caelestia::services {

class ChargeThreshold : public TickingService {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int threshold READ threshold NOTIFY thresholdChanged)
    Q_PROPERTY(qreal limit READ limit NOTIFY thresholdChanged)
    Q_PROPERTY(bool isLimited READ isLimited NOTIFY thresholdChanged)

public:
    explicit ChargeThreshold(QObject* parent = nullptr);

    [[nodiscard]] int threshold() const;
    [[nodiscard]] qreal limit() const;
    [[nodiscard]] bool isLimited() const;

signals:
    void thresholdChanged();

protected:
    void tick() override;

private:
    void resolvePath();
    void updateThreshold(int threshold);

    QString m_path;
    int m_threshold = 100;
};

} // namespace caelestia::services
