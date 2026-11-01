#pragma once

#include <qmutex.h>
#include <qqmlintegration.h>

#include <pipewire/pipewire.h>
#include <spa/param/audio/format-utils.h>

#include <array>
#include <atomic>
#include <stop_token>
#include <thread>

#include "service.hpp"

namespace caelestia::services {

namespace ac {

constexpr quint32 k_sampleRate = 44100;
constexpr quint32 k_chunkSize = 512;

} // namespace ac

class AudioCollector;

class PipeWireWorker {
public:
    explicit PipeWireWorker(std::stop_token token, AudioCollector* collector);

    void run();

private:
    pw_main_loop* m_loop;
    pw_stream* m_stream;
    spa_source* m_timer;
    bool m_idle;

    std::stop_token m_token;
    AudioCollector* m_collector;

    static void handleTimeout(void* data, uint64_t expirations);
    void streamStateChanged(pw_stream_state state);
    void processStream();

    [[nodiscard]] static unsigned int nextPowerOf2(unsigned int n);
};

class AudioCollector : public Service {
    Q_OBJECT

public:
    AudioCollector(const AudioCollector&) = delete;
    AudioCollector& operator=(const AudioCollector&) = delete;

    static AudioCollector& instance();

    void clearBuffer();
    void loadChunk(const qint16* samples, quint32 count);
    quint32 readChunk(float* out, quint32 count = 0);
    quint32 readChunk(double* out, quint32 count = 0);

private:
    explicit AudioCollector(QObject* parent = nullptr);
    ~AudioCollector() override;

    std::jthread m_thread;

    // Latest chunk, shared through a seqlock: the PipeWire thread (sole writer) never
    // blocks, and readers retry if a write happened while they were copying. The samples
    // are relaxed atomics so concurrent access is well defined (plain loads/stores in practice).
    std::array<std::atomic<float>, ac::k_chunkSize> m_samples;
    std::atomic<quint64> m_seq;

    template <typename T> quint32 readChunkImpl(T* out, quint32 count);

    void reload();
    void start() override;
    void stop() override;
};

} // namespace caelestia::services
