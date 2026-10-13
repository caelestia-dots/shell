#include "audiocollector.hpp"

#include <qloggingcategory.h>

#include <pipewire/pipewire.h>

#include <algorithm>
#include <mutex>
#include <span>
#include <stop_token>
#include <utility>
#include <vector>

#include "service.hpp"

namespace {

Q_LOGGING_CATEGORY(lcAcWorker, "caelestia.services.ac.worker", QtInfoMsg)

} // namespace

namespace caelestia::services {

PipeWireWorker::PipeWireWorker(std::stop_token token, AudioCollector* collector)
    : m_loop(nullptr)
    , m_stream(nullptr)
    , m_timer(nullptr)
    , m_idle(true)
    , m_token(std::move(token))
    , m_collector(collector) {
    pw_init(nullptr, nullptr);

    m_loop = pw_main_loop_new(nullptr);
    if (!m_loop) {
        qCWarning(lcAcWorker) << "init: failed to create PipeWire main loop";
        pw_deinit();
        return;
    }

    timespec timeout = { .tv_sec = 0, .tv_nsec = 10 * SPA_NSEC_PER_MSEC };
    m_timer = pw_loop_add_timer(pw_main_loop_get_loop(m_loop), handleTimeout, this);
    if (!m_timer) {
        qCWarning(lcAcWorker) << "init: failed to create timer";
        pw_main_loop_destroy(m_loop);
        pw_deinit();
        return;
    }
    pw_loop_update_timer(pw_main_loop_get_loop(m_loop), m_timer, &timeout, &timeout, false);

    auto* props = pw_properties_new(
        PW_KEY_MEDIA_TYPE, "Audio", PW_KEY_MEDIA_CATEGORY, "Capture", PW_KEY_MEDIA_ROLE, "Music", nullptr);
    pw_properties_set(props, PW_KEY_STREAM_CAPTURE_SINK, "true");
    pw_properties_set(props, PW_KEY_NODE_PASSIVE, "true");
    pw_properties_set(props, PW_KEY_NODE_VIRTUAL, "true");
    pw_properties_set(props, PW_KEY_STREAM_DONT_REMIX, "false");
    pw_properties_set(props, "channelmix.upmix", "true");

    std::vector<uint8_t> buffer(ac::k_chunkSize);
    spa_pod_builder b;
    spa_pod_builder_init(&b, buffer.data(), static_cast<quint32>(buffer.size()));

    spa_audio_info_raw info{};
    info.format = SPA_AUDIO_FORMAT_S16;
    info.rate = ac::k_sampleRate;
    info.channels = 1;

    const spa_pod* params[1];
    params[0] = spa_format_audio_raw_build(&b, SPA_PARAM_EnumFormat, &info);

    pw_stream_events events{};
    events.version = PW_VERSION_STREAM_EVENTS;
    events.state_changed = [](void* data, pw_stream_state, pw_stream_state state, const char*) {
        auto* self = static_cast<PipeWireWorker*>(data);
        self->streamStateChanged(state);
    };
    events.process = [](void* data) {
        auto* self = static_cast<PipeWireWorker*>(data);
        self->processStream();
    };

    m_stream = pw_stream_new_simple(pw_main_loop_get_loop(m_loop), "caelestia-shell", props, &events, this);
    if (!m_stream) {
        qCWarning(lcAcWorker) << "init: failed to create stream";
        pw_main_loop_destroy(m_loop);
        pw_deinit();
        return;
    }

    const auto flags = static_cast<pw_stream_flags>(static_cast<quint32>(PW_STREAM_FLAG_AUTOCONNECT) |
                                                    static_cast<quint32>(PW_STREAM_FLAG_MAP_BUFFERS) |
                                                    static_cast<quint32>(PW_STREAM_FLAG_RT_PROCESS));
    const int success = pw_stream_connect(m_stream, PW_DIRECTION_INPUT, PW_ID_ANY, flags, params, 1);
    if (success < 0) {
        qCWarning(lcAcWorker) << "init: failed to connect stream";
        pw_stream_destroy(m_stream);
        pw_main_loop_destroy(m_loop);
        pw_deinit();
        return;
    }

    pw_main_loop_run(m_loop);

    pw_stream_destroy(m_stream);
    pw_main_loop_destroy(m_loop);
    pw_deinit();
}

void PipeWireWorker::handleTimeout(void* data, uint64_t expirations) {
    auto* self = static_cast<PipeWireWorker*>(data);

    if (self->m_token.stop_requested()) {
        pw_main_loop_quit(self->m_loop);
        return;
    }

    if (!self->m_idle) {
        if (expirations < 10) {
            self->m_collector->clearBuffer();
        } else {
            self->m_idle = true;
            timespec timeout = { .tv_sec = 0, .tv_nsec = 500 * SPA_NSEC_PER_MSEC };
            pw_loop_update_timer(pw_main_loop_get_loop(self->m_loop), self->m_timer, &timeout, &timeout, false);
        }
    }
}

void PipeWireWorker::streamStateChanged(pw_stream_state state) {
    m_idle = false;
    switch (state) {
    case PW_STREAM_STATE_PAUSED: {
        timespec timeout = { .tv_sec = 0, .tv_nsec = 10 * SPA_NSEC_PER_MSEC };
        pw_loop_update_timer(pw_main_loop_get_loop(m_loop), m_timer, &timeout, &timeout, false);
        break;
    }
    case PW_STREAM_STATE_STREAMING:
        pw_loop_update_timer(pw_main_loop_get_loop(m_loop), m_timer, nullptr, nullptr, false);
        break;
    case PW_STREAM_STATE_ERROR:
        pw_main_loop_quit(m_loop);
        break;
    default:
        break;
    }
}

void PipeWireWorker::processStream() {
    if (m_token.stop_requested()) {
        pw_main_loop_quit(m_loop);
        return;
    }

    pw_buffer* const buffer = pw_stream_dequeue_buffer(m_stream);
    if (buffer == nullptr) {
        return;
    }

    const spa_buffer* buf = buffer->buffer;
    const auto* samples = reinterpret_cast<const qint16*>(buf->datas[0].data);
    if (samples != nullptr) {
        const quint32 count = buf->datas[0].chunk->size / sizeof(qint16);
        m_collector->loadChunk(samples, count);
    }

    pw_stream_queue_buffer(m_stream, buffer);
}

AudioCollector& AudioCollector::instance() {
    static AudioCollector s_instance;
    return s_instance;
}

void AudioCollector::clearBuffer() {
    const std::scoped_lock lock(m_samplesLock);
    m_samples.clear();
    m_discardPending.store(true, std::memory_order_release);
}

void AudioCollector::loadChunk(const qint16* samples, quint32 count) {
    if (m_discardPending.exchange(false, std::memory_order_acquire)) {
        m_pending.clear();
    }

    const auto toFloat = [](qint16 sample) {
        return static_cast<float>(sample) / 32768.0f;
    };

    // Called on the RT thread, so stash the chunk until the next callback rather than wait on a reader
    const std::unique_lock lock(m_samplesLock, std::try_to_lock);
    if (!lock.owns_lock()) {
        m_pending.push(std::span(samples, count), toFloat);
        return;
    }

    m_pending.pushTo(m_samples);
    m_pending.clear();
    m_samples.push(std::span(samples, count), toFloat);
}

template <typename T> quint32 AudioCollector::readLatest(T* out, quint32 count) {
    if (count == 0 || count > ac::k_chunkSize) {
        count = ac::k_chunkSize;
    }

    const std::span dest(out, count);
    const std::scoped_lock lock(m_samplesLock);

    // Pad the front with silence until the window has filled after a clear
    const auto available = static_cast<size_t>(std::min(m_samples.count(), static_cast<qsizetype>(count)));
    std::ranges::fill(dest.first(count - available), T(0));
    m_samples.copyLatest(dest.last(available), [](float sample) {
        return static_cast<T>(sample);
    });

    return count;
}

quint32 AudioCollector::readChunk(float* out, quint32 count) {
    return readLatest(out, count);
}

quint32 AudioCollector::readChunk(double* out, quint32 count) {
    return readLatest(out, count);
}

AudioCollector::AudioCollector(QObject* parent)
    : Service(parent)
    , m_samples(ac::k_chunkSize)
    , m_pending(ac::k_chunkSize)
    , m_discardPending(false) {}

AudioCollector::~AudioCollector() {
    AudioCollector::stop();
}

void AudioCollector::start() {
    if (m_thread.joinable()) {
        return;
    }

    clearBuffer();

    m_thread = std::jthread([this](std::stop_token token) {
        const PipeWireWorker worker(std::move(token), this);
    });
}

void AudioCollector::stop() {
    if (m_thread.joinable()) {
        m_thread.request_stop();
        m_thread.join();
    }
}

} // namespace caelestia::services
