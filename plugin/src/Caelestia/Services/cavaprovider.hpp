#pragma once

#include "audioprovider.hpp"
#include <cava/cavacore.h>
#include <qqmlintegration.h>

namespace caelestia::services {

class CavaProcessor : public AudioProcessor {
    Q_OBJECT

private:
    int m_bars;
    QVector<double> m_values;

    void updateValues(QVector<double> values);
};

} // namespace caelestia::services
