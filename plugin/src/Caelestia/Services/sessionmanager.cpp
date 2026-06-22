#include "sessionmanager.hpp"

#include <QtDBus/qdbusconnection.h>
#include <QtDBus/qdbuserror.h>
#include <QtDBus/qdbusinterface.h>
#include <QtDBus/qdbusmessage.h>
#include <QtDBus/qdbuspendingcall.h>
#include <QtDBus/qdbuspendingreply.h>
#include <QtDBus/qdbusreply.h>
#include <qelapsedtimer.h>
#include <qloggingcategory.h>

Q_LOGGING_CATEGORY(lcSessionManager, "caelestia.services.sessionmanager", QtInfoMsg)

namespace caelestia::services {

namespace {

constexpr const char* LOGIN_SERVICE = "org.freedesktop.login1";
constexpr const char* LOGIN_PATH = "/org/freedesktop/login1";
constexpr const char* LOGIN_IFACE = "org.freedesktop.login1.Manager";
constexpr const char* SESSION_IFACE = "org.freedesktop.login1.Session";

} // namespace

SessionManager::SessionManager(QObject* parent)
    : QObject(parent) {
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        qCWarning(lcSessionManager) << "Failed to connect to system bus:" << bus.lastError().message();
        return;
    }

    bool ok =
        bus.connect(LOGIN_SERVICE, LOGIN_PATH, LOGIN_IFACE, "PrepareForSleep", this, SLOT(handlePrepareForSleep(bool)));

    if (!ok) {
        qCWarning(lcSessionManager) << "Failed to connect to PrepareForSleep signal:" << bus.lastError().message();
    }

    QDBusInterface login1(LOGIN_SERVICE, LOGIN_PATH, LOGIN_IFACE, bus);

    const QDBusReply<QString> hibernateReply = login1.call("CanHibernate");
    if (!hibernateReply.isValid()) {
        qCWarning(lcSessionManager) << "Failed to query hibernate support:" << hibernateReply.error().message();
    } else {
        const auto state = hibernateReply.value();
        const bool available = state == "yes" || state == "challenge";
        if (m_hibernateAvailable != available) {
            m_hibernateAvailable = available;
            emit hibernateAvailableChanged();
        }
    }

    const QDBusReply<QDBusObjectPath> sessionReply = login1.call("GetSession", "auto");
    if (!sessionReply.isValid()) {
        qCWarning(lcSessionManager) << "Failed to get session path";
        return;
    }
    m_sessionPath = sessionReply.value().path();

    ok = bus.connect(LOGIN_SERVICE, m_sessionPath, SESSION_IFACE, "Lock", this, SLOT(handleLockRequested()));
    if (!ok) {
        qCWarning(lcSessionManager) << "Failed to connect to Lock signal:" << bus.lastError().message();
    }

    ok = bus.connect(LOGIN_SERVICE, m_sessionPath, SESSION_IFACE, "Unlock", this, SLOT(handleUnlockRequested()));
    if (!ok) {
        qCWarning(lcSessionManager) << "Failed to connect to Unlock signal:" << bus.lastError().message();
    }
}

bool SessionManager::hibernateAvailable() const {
    return m_hibernateAvailable;
}

bool SessionManager::exec(const QStringList& command) {
    if (command.isEmpty()) {
        return false;
    }

    const auto cmd = command.first();
    if (cmd == "logout") {
        logout();
    } else if (cmd == "suspend") {
        suspend();
    } else if (cmd == "suspendThenHibernate") {
        suspendThenHibernate();
    } else if (cmd == "hibernate") {
        hibernate();
    } else if (cmd == "poweroff") {
        poweroff();
    } else if (cmd == "reboot") {
        reboot();
    } else {
        return false;
    }

    return true;
}

void SessionManager::logout() {
    callSession("Terminate");
}

void SessionManager::suspend() {
    callManager("Suspend");
}

void SessionManager::suspendThenHibernate() {
    // Fall back to suspend when no hibernate
    callManager(m_hibernateAvailable ? "SuspendThenHibernate" : "Suspend");
}

void SessionManager::hibernate() {
    callManager("Hibernate");
}

void SessionManager::poweroff() {
    callManager("PowerOff");
}

void SessionManager::reboot() {
    callManager("Reboot");
}

void SessionManager::call(const QString& path, const QString& iface, const QString& method, const QVariantList& args) {
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        qCWarning(lcSessionManager) << "Cannot call" << method << "- not connected to system bus";
        return;
    }

    QDBusMessage msg = QDBusMessage::createMethodCall(LOGIN_SERVICE, path, iface, method);
    msg.setArguments(args);

    auto* watcher = new QDBusPendingCallWatcher(bus.asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [method](QDBusPendingCallWatcher* self) {
        const QDBusPendingReply<> reply = *self;
        if (reply.isError()) {
            qCWarning(lcSessionManager) << "Call to" << method << "failed:" << reply.error().message();
        }
        self->deleteLater();
    });
}

void SessionManager::callManager(const QString& method) {
    call(LOGIN_PATH, LOGIN_IFACE, method, { /* interactive = */ true });
}

void SessionManager::callSession(const QString& method) {
    if (m_sessionPath.isEmpty()) {
        qCWarning(lcSessionManager) << "Cannot call" << method << "- no session path";
        return;
    }

    call(m_sessionPath, SESSION_IFACE, method);
}

void SessionManager::handlePrepareForSleep(bool sleep) {
    if (sleep) {
        emit aboutToSleep();
    } else {
        emit resumed();
    }
}

void SessionManager::handleLockRequested() {
    emit lockRequested();
}

void SessionManager::handleUnlockRequested() {
    emit unlockRequested();
}

} // namespace caelestia::services
