#pragma once

#include "service.hpp"
#include <atomic>
#include <pipewire/pipewire.h>
#include <qmutex.h>
#include <qqmlintegration.h>
#include <spa/param/audio/format-utils.h>
#include <stop_token>
#include <thread>
#include <vector>

namespace caelestia::services {

namespace ac {

constexpr quint32 SAMPLE_RATE = 44100;
constexpr quint32 CHUNK_SIZE = 512;

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

    [[nodiscard]] unsigned int nextPowerOf2(unsigned int n);
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
    ~AudioCollector();

    std::jthread m_thread;
    std::vector<float> m_buffer1;
    std::vector<float> m_buffer2;
    std::atomic<std::vector<float>*> m_readBuffer;
    std::atomic<std::vector<float>*> m_writeBuffer;
    quint32 m_sampleCount;

    void reload();
    void start() override;
    void stop() override;
};

} // namespace caelestia::services
