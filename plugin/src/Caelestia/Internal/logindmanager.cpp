#include "logindmanager.hpp"

#include <QtDBus/qdbusconnection.h>
#include <QtDBus/qdbuserror.h>
#include <QtDBus/qdbusinterface.h>
#include <QtDBus/qdbusreply.h>

namespace caelestia::internal {

LogindManager::LogindManager(QObject* parent)
    : QObject(parent) {
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        qWarning() << "LogindManager::LogindManager: failed to connect to system bus:" << bus.lastError().message();
        return;
    }

    bool ok = bus.connect("org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager",
        "PrepareForSleep", this, SLOT(handlePrepareForSleep(bool)));

    if (!ok) {
        qWarning() << "LogindManager::LogindManager: failed to connect to PrepareForSleep signal:"
                   << bus.lastError().message();
    }

    QDBusInterface login1("org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", bus);
    const QDBusReply<QDBusObjectPath> reply = login1.call("GetSession", "auto");
    if (!reply.isValid()) {
        qWarning() << "LogindManager::LogindManager: failed to get session path";
        return;
    }
    const auto sessionPath = reply.value().path();

    ok = bus.connect("org.freedesktop.login1", sessionPath, "org.freedesktop.login1.Session", "Lock", this,
        SLOT(handleLockRequested()));

    if (!ok) {
        qWarning() << "LogindManager::LogindManager: failed to connect to Lock signal:" << bus.lastError().message();
    }

    ok = bus.connect("org.freedesktop.login1", sessionPath, "org.freedesktop.login1.Session", "Unlock", this,
        SLOT(handleUnlockRequested()));

    if (!ok) {
        qWarning() << "LogindManager::LogindManager: failed to connect to Unlock signal:" << bus.lastError().message();
    }
}

void LogindManager::handlePrepareForSleep(bool sleep) {
    if (sleep) {
        emit aboutToSleep();
    } else {
        emit resumed();
    }
}

void LogindManager::handleLockRequested() {
    emit lockRequested();
}

void LogindManager::handleUnlockRequested() {
    emit unlockRequested();
}

} // namespace caelestia::internal
