#include "cavaprovider.hpp"

#include "service.hpp"
#include <QObject>

namespace cava {
extern "C" {
#include <cava/common.h>
}
} // namespace cava

CavaProvider::CavaProvider(QObject* parent)
    : Service(parent)
    , m_plan(nullptr)
    , m_bars(45) {
    connect(&m_timer, &QTimer::timeout, this, &CavaProvider::updateValues);
    init();
}

CavaProvider::~CavaProvider() {
    stop();
}

void CavaProvider::start() {
    init();
    m_timer.start();
}

void CavaProvider::stop() {
    m_timer.stop();
    cleanup();
}

int CavaProvider::bars() const {
    return m_bars;
}

void CavaProvider::setBars(int bars) {
    if (m_bars == bars) {
        return;
    }

    m_bars = bars;
    emit barsChanged();

    if (m_plan) {
        reload();
    }
}

QVector<int> CavaProvider::values() const {
    return m_values;
}

void CavaProvider::updateValues() {
    if (!m_plan) {
        return;
    }

    m_inputSource(&m_audioData);
    cava::cava_execute(m_audioData.cava_in, m_audioData.samples_counter, m_audioRaw.cava_out, m_plan);
    if (m_audioData.samples_counter > 0) {
        m_audioData.samples_counter = 0;
    }

    cava::audio_raw_fetch(&m_audioRaw, &m_params, m_plan);

    QVector<int> newValues(m_audioRaw.number_of_bars);
    for (int i = 0; i < m_audioRaw.number_of_bars; i++) {
        m_audioRaw.previous_frame[i] = m_audioRaw.bars[i];

        if (m_audioRaw.bars[i] > m_params.ascii_range) {
            newValues[i] = m_params.ascii_range;
        } else {
            newValues[i] = m_audioRaw.bars[i];
        }
    }

    if (newValues != m_values) {
        m_values = newValues;
        emit valuesChanged();
    }
}

void CavaProvider::reload() {
    cleanup();
    init();
}

void CavaProvider::cleanup() {
    if (!m_plan) {
        return;
    }

    free(m_params.raw_target);
    free(m_params.data_format);
    free(m_params.audio_source);
    delete[] m_params.userEQ;

    delete m_plan;
    m_plan = nullptr;
    delete[] m_audioData.source;
    delete[] m_audioData.cava_in;
}

void CavaProvider::init() {
    loadParams();
    loadPlan();
}

void CavaProvider::loadParams() {
    m_params.monstercat = 1;
    m_params.waves = 0;
    m_params.integral = 77;
    m_params.gravity = 120;
    m_params.ignore = 0;
    m_params.noise_reduction = 85;

    m_params.fixedbars = m_bars;
    m_params.bar_width = 2;
    m_params.bar_spacing = 1;
    m_params.bar_height = 32;
    m_params.framerate = 60;
    m_params.sens = 100;
    m_params.autosens = 1;
    m_params.overshoot = 20;
    m_params.lower_cut_off = 50;
    m_params.upper_cut_off = 10000;
    m_params.sleep_timer = 3;

    m_params.reverse = 0;
    m_params.raw_target = strdup("/dev/stdout");
    m_params.data_format = strdup("ascii");
    m_params.bar_delim = 59;
    m_params.frame_delim = 10;
    m_params.ascii_range = 100;
    m_params.bit_format = 16;

    m_params.inAtty = 0;
    m_params.continuous_rendering = 0;
    m_params.disable_blanking = 0;
    m_params.show_idle_bar_heads = 1;
    m_params.waveform = 0;
    m_params.sync_updates = 0;

    m_params.userEQ_enabled = 1;
    m_params.userEQ_keys = 5;
    m_params.userEQ = new double[5]{ 0.8, 0.9, 1.0, 1.1, 1.2 };

    m_params.samplerate = 44100;
    m_params.samplebits = 16;
    m_params.channels = 1;
    m_params.autoconnect = 2;

    m_params.output = cava::output_method::OUTPUT_RAW;
    m_params.orientation = cava::ORIENT_TOP;
    m_params.xaxis = cava::xaxis_scale::NONE;
    m_params.mono_opt = cava::AVERAGE;
    m_params.input = cava::INPUT_PIPEWIRE;
    m_params.audio_source = strdup("auto");
}

void CavaProvider::loadPlan() {
    m_plan = new cava::cava_plan{};

    m_audioRaw.height = m_params.ascii_range;
    m_audioData.format = -1;
    m_audioData.source = new char[1 + strlen(m_params.audio_source)];
    m_audioData.source[0] = '\0';
    strcpy(m_audioData.source, m_params.audio_source);

    m_audioData.rate = 0;
    m_audioData.samples_counter = 0;
    m_audioData.channels = 2;
    m_audioData.IEEE_FLOAT = 0;

    m_audioData.input_buffer_size = BUFFER_SIZE * static_cast<int>(m_audioData.channels);
    m_audioData.cava_buffer_size = m_audioData.input_buffer_size * 8;

    m_audioData.cava_in = new double[static_cast<size_t>(m_audioData.cava_buffer_size)]{ 0.0 };

    m_audioData.terminate = 0;
    m_audioData.suspendFlag = false;
    m_inputSource = cava::get_input(&m_audioData, &m_params);

    if (!m_inputSource) {
        qWarning() << "CavaProvider::start: cava API didn't provide input audio source method";
        return;
    }

    // Init cava plan and audio_raw struct
    audio_raw_init(&m_audioData, &m_audioRaw, &m_params, m_plan);
    if (!m_plan) {
        qWarning() << "CavaProvider::start: cava API didn't provide plan";
        return;
    }

    m_audioRaw.previous_frame[0] = -1;

    m_timer.setInterval(1000 / m_params.framerate);
}
