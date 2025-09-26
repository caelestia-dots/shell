#include "sleepnotifier.hpp"

#include <QtDBus/qdbusconnection.h>
#include <QtDBus/qdbuserror.h>

namespace caelestia::internal {

SleepNotifier::SleepNotifier(QObject* parent)
    : QObject(parent) {
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        qWarning() << "SleepNotifier::SleepNotifier: failed to connect to system bus:" << bus.lastError().message();
        return;
    }

    const bool ok = bus.connect("org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager",
        "PrepareForSleep", this, SLOT(handlePrepareForSleep(bool)));

    if (!ok) {
        qWarning() << "SleepNotifier::SleepNotifier: failed to connect to dbus:" << bus.lastError().message();
    }
}

void SleepNotifier::handlePrepareForSleep(bool sleep) {
    if (sleep) {
        emit aboutToSleep();
    } else {
        emit resumed();
    }
}

} // namespace caelestia::internal
