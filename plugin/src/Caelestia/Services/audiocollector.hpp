#pragma once

#include <qmutex.h>
#include <qqmlintegration.h>

#include <pipewire/pipewire.h>
#include <spa/param/audio/format-utils.h>

#include <atomic>
#include <stop_token>
#include <thread>

#include "util/ringbuffer.hpp"
#include "service.hpp"

namespace caelestia::services {

namespace ac {

constexpr quint32 k_sampleRate = 44100;
constexpr quint32 k_chunkSize = 512;

// Lockable which never makes the RT writer wait, as it only try_locks. Readers spin, they only wait on a short copy.
class SpinLock {
public:
    void lock() {
        while (m_flag.test_and_set(std::memory_order_acquire)) {
            while (m_flag.test(std::memory_order_relaxed))
                std::this_thread::yield();
        }
    }

    bool try_lock() { // NOLINT(readability-identifier-naming): Lockable requirement
        return !m_flag.test_and_set(std::memory_order_acquire);
    }

    void unlock() { m_flag.clear(std::memory_order_release); }

private:
    std::atomic_flag m_flag;
};

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
    util::RingBuffer<float> m_samples;
    ac::SpinLock m_samplesLock;
    util::RingBuffer<float> m_pending; // Writer thread only, holds chunks which arrived while a reader had the lock
    std::atomic<bool> m_discardPending;
    quint32 m_sampleCount;

    template <typename T> quint32 readLatest(T* out, quint32 count);

    void reload();
    void start() override;
    void stop() override;
};

} // namespace caelestia::services
