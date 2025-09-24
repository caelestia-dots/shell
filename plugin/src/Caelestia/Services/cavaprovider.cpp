#include "cavaprovider.hpp"

#include "audiocollector.hpp"
#include "audioprovider.hpp"
#include <cava/cavacore.h>
#include <cmath>
#include <cstddef>
#include <qdebug.h>

namespace caelestia::services {

CavaProcessor::CavaProcessor(QObject* parent)
    : AudioProcessor(parent)
    , m_plan(nullptr)
    , m_in(new double[ac::CHUNK_SIZE])
    , m_out(nullptr)
    , m_bars(0) {};

CavaProcessor::~CavaProcessor() {
    cleanup();
    delete[] m_in;
}

void CavaProcessor::process() {
    if (!m_plan || m_bars == 0 || !m_out) {
        return;
    }

    const int count = static_cast<int>(AudioCollector::instance().readChunk(m_in));

    // Process in data via cava
    cava_execute(m_in, count, m_out, m_plan);

    // Apply monstercat filter
    for (int i = 0; i < m_bars; i++) {
        for (int j = i - 1; j >= 0; j--) {
            m_out[j] = std::max(m_out[i] / std::pow(1.5, i - j), m_out[j]);
        }
        for (int j = i + 1; j < m_bars; j++) {
            m_out[j] = std::max(m_out[i] / std::pow(1.5, j - i), m_out[j]);
        }
    }

    // Update values
    QVector<double> values(m_bars);
    std::copy(m_out, m_out + m_bars, values.begin());
    if (values != m_values) {
        m_values = std::move(values);
        emit valuesChanged(m_values);
    }
}

void CavaProcessor::setBars(int bars) {
    if (bars < 0) {
        qWarning() << "CavaProcessor::setBars: bars must be greater than 0. Setting to 0.";
        bars = 0;
    }

    if (m_bars != bars) {
        m_bars = bars;
        reload();
    }
}

void CavaProcessor::reload() {
    cleanup();
    initCava();
}

void CavaProcessor::cleanup() {
    if (m_plan) {
        cava_destroy(m_plan);
        m_plan = nullptr;
    }

    if (m_out) {
        delete[] m_out;
        m_out = nullptr;
    }
}

void CavaProcessor::initCava() {
    if (m_plan || m_bars == 0) {
        return;
    }

    m_plan = cava_init(m_bars, ac::SAMPLE_RATE, 1, 1, 0.85, 50, 10000);

    if (m_plan->status == -1) {
        qWarning() << "CavaProcessor::initCava: failed to initialise cava plan";
        cleanup();
        return;
    }

    m_out = new double[static_cast<size_t>(m_bars)];
}

CavaProvider::CavaProvider(QObject* parent)
    : AudioProvider(parent)
    , m_bars(0)
    , m_values(m_bars, 0.0) {
    m_processor = new CavaProcessor();
    init();

    connect(static_cast<CavaProcessor*>(m_processor), &CavaProcessor::valuesChanged, this, &CavaProvider::updateValues);
}

int CavaProvider::bars() const {
    return m_bars;
}

void CavaProvider::setBars(int bars) {
    if (bars < 0) {
        qWarning() << "CavaProvider::setBars: bars must be greater than 0. Setting to 0.";
        bars = 0;
    }

    if (m_bars == bars) {
        return;
    }

    m_values.resize(bars, 0.0);
    m_bars = bars;
    emit barsChanged();
    emit valuesChanged();

    QMetaObject::invokeMethod(
        static_cast<CavaProcessor*>(m_processor), &CavaProcessor::setBars, Qt::QueuedConnection, bars);
}

QVector<double> CavaProvider::values() const {
    return m_values;
}

void CavaProvider::updateValues(QVector<double> values) {
    if (values != m_values) {
        m_values = values;
        emit valuesChanged();
    }
}

} // namespace caelestia::services
