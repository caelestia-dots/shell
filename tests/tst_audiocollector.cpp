#include <qtest.h>

#include <array>
#include <atomic>
#include <cstring>
#include <thread>

#include "Services/audiocollector.hpp"

using caelestia::services::AudioCollector;
namespace ac = caelestia::services::ac;

// Only exercises the shared buffer (loadChunk/readChunk); the PipeWire thread is never
// started because nothing references the service
class TestAudioCollector : public QObject {
    Q_OBJECT

private slots:

    void roundTrip() {
        auto& collector = AudioCollector::instance();

        std::array<qint16, ac::k_chunkSize> samples{};
        for (quint32 i = 0; i < ac::k_chunkSize; ++i)
            samples[i] = static_cast<qint16>(i * 10);
        collector.loadChunk(samples.data(), ac::k_chunkSize);

        std::array<float, ac::k_chunkSize> out{};
        QCOMPARE(collector.readChunk(out.data()), ac::k_chunkSize);
        QCOMPARE(out[0], 0.0f);
        QCOMPARE(out[100], 1000.0f / 32768.0f);

        std::array<double, ac::k_chunkSize> outD{};
        QCOMPARE(collector.readChunk(outD.data(), 4), 4u);
        QCOMPARE(outD[3], 30.0 / 32768.0);
    }

    void shortChunkZeroesTail() {
        auto& collector = AudioCollector::instance();

        std::array<qint16, ac::k_chunkSize> full;
        full.fill(1000);
        collector.loadChunk(full.data(), ac::k_chunkSize);

        const std::array<qint16, 8> part{ 5, 5, 5, 5, 5, 5, 5, 5 };
        collector.loadChunk(part.data(), part.size());

        std::array<float, ac::k_chunkSize> out{};
        collector.readChunk(out.data());
        QCOMPARE(out[7], 5.0f / 32768.0f);
        QCOMPARE(out[8], 0.0f); // Not left over from the longer chunk
        QCOMPARE(out[ac::k_chunkSize - 1], 0.0f);
    }

    void clampsCount() {
        auto& collector = AudioCollector::instance();
        std::array<float, ac::k_chunkSize> out{};
        QCOMPARE(collector.readChunk(out.data(), 0), ac::k_chunkSize);
        QCOMPARE(collector.readChunk(out.data(), ac::k_chunkSize * 4), ac::k_chunkSize);
    }

    void clearBuffer() {
        auto& collector = AudioCollector::instance();
        std::array<qint16, ac::k_chunkSize> full;
        full.fill(-2000);
        collector.loadChunk(full.data(), ac::k_chunkSize);
        collector.clearBuffer();

        std::array<float, ac::k_chunkSize> out{};
        out.fill(1.0f);
        collector.readChunk(out.data());
        for (const auto v : out)
            QCOMPARE(v, 0.0f);
    }

    // Readers must only ever see whole chunks, never a mix of two writes
    void noTornReads() {
        auto& collector = AudioCollector::instance();
        std::atomic<bool> stop = false;
        std::atomic<int> torn = 0;
        std::atomic<int> reads = 0;

        auto reader = [&] {
            std::array<float, ac::k_chunkSize> out{};
            while (!stop) {
                collector.readChunk(out.data());
                ++reads;
                for (const auto& v : out) {
                    // Exact comparison on purpose: every sample of a chunk is the same value
                    if (std::memcmp(&v, out.data(), sizeof(float)) != 0) {
                        ++torn;
                        break;
                    }
                }
            }
        };

        std::thread r1(reader);
        std::thread r2(reader);

        std::array<qint16, ac::k_chunkSize> samples{};
        for (int n = 0; n < 5000; ++n) {
            samples.fill(static_cast<qint16>(n % 30000));
            collector.loadChunk(samples.data(), ac::k_chunkSize);
            std::this_thread::sleep_for(std::chrono::microseconds(20));
        }

        stop = true;
        r1.join();
        r2.join();

        QVERIFY(reads > 0);
        QCOMPARE(torn.load(), 0);
    }
};

QTEST_GUILESS_MAIN(TestAudioCollector)
#include "tst_audiocollector.moc"
