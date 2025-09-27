#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::internal {

class LogindManager : public QObject {
    Q_OBJECT
    QML_ELEMENT

public:
    explicit LogindManager(QObject* parent = nullptr);

signals:
    void aboutToSleep();
    void resumed();
    void lockRequested();
    void unlockRequested();

private slots:
    void handlePrepareForSleep(bool sleep);
    void handleLockRequested();
    void handleUnlockRequested();
};

} // namespace caelestia::internal
