#pragma once

#include "service.hpp"
#include <qqmlintegration.h>
#include <qtimer.h>

namespace caelestia::services {

class AudioProcessor : public QObject {
    Q_OBJECT

public:
    explicit AudioProcessor(QObject* parent = nullptr);
    ~AudioProcessor();

    void init();

public slots:
    void start();
    void stop();

protected:
    virtual void process() = 0;

private:
    QTimer* m_timer;
};

class AudioProvider : public Service {
    Q_OBJECT

public:
    explicit AudioProvider(QObject* parent = nullptr);
    ~AudioProvider();

protected:
    AudioProcessor* m_processor;

    void init();

private:
    QThread* m_thread;

    void start() override;
    void stop() override;
};

} // namespace caelestia::services
