#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::internal {

class SleepNotifier : public QObject {
    Q_OBJECT
    QML_ELEMENT

public:
    explicit SleepNotifier(QObject* parent = nullptr);

signals:
    void aboutToSleep();
    void resumed();

private slots:
    void handlePrepareForSleep(bool sleep);
};

} // namespace caelestia::internal
