#pragma once

#include "service.hpp"
#include <QObject>
#include <QTimer>
#include <qqmlintegration.h>

namespace cava {
extern "C" {
#include <cava/common.h>
}
} // namespace cava

class CavaProvider : public Service {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int bars READ bars WRITE setBars NOTIFY barsChanged)
    Q_PROPERTY(QVector<int> values READ values NOTIFY valuesChanged)

public:
    explicit CavaProvider(QObject* parent = nullptr);
    ~CavaProvider();

    void start() override;
    void stop() override;

    [[nodiscard]] int bars() const;
    void setBars(int bars);

    [[nodiscard]] QVector<int> values() const;

signals:
    void barsChanged();
    void valuesChanged();

private slots:
    void updateValues();

private:
    struct cava::cava_plan* m_plan;
    struct cava::config_params m_params{};
    struct cava::audio_raw m_audioRaw{};
    struct cava::audio_data m_audioData{};
    cava::ptr m_inputSource;

    QTimer m_timer;

    int m_bars;
    QVector<int> m_values;

    void reload();
    void cleanup();
    void init();
    void loadParams();
    void loadPlan();
};
