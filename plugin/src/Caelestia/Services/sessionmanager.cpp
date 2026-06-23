#include "sessionmanager.hpp"

#include <QtDBus/qdbusconnection.h>
#include <QtDBus/qdbuserror.h>
#include <QtDBus/qdbusmessage.h>
#include <QtDBus/qdbuspendingcall.h>
#include <QtDBus/qdbuspendingreply.h>
#include <QtDBus/qdbusreply.h>
#include <qloggingcategory.h>

#include "../toaster.hpp"

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
    auto bus = getSystemBus();
    if (!bus)
        return;

    bool ok = bus->connect(
        LOGIN_SERVICE, LOGIN_PATH, LOGIN_IFACE, "PrepareForSleep", this, SLOT(handlePrepareForSleep(bool)));
    if (!ok)
        qCWarning(lcSessionManager) << "Failed to connect to PrepareForSleep signal:" << bus->lastError().message();

    auto sessionMsg = QDBusMessage::createMethodCall(LOGIN_SERVICE, LOGIN_PATH, LOGIN_IFACE, "GetSession");
    sessionMsg.setArguments({ "auto" });
    const QDBusReply<QDBusObjectPath> sessionReply = bus->call(sessionMsg);
    if (!sessionReply.isValid()) {
        qCWarning(lcSessionManager) << "Failed to get session path:" << sessionReply.error().message();
        return;
    }
    m_sessionPath = sessionReply.value().path();

    ok = bus->connect(LOGIN_SERVICE, m_sessionPath, SESSION_IFACE, "Lock", this, SLOT(handleLockRequested()));
    if (!ok)
        qCWarning(lcSessionManager) << "Failed to connect to Lock signal:" << bus->lastError().message();

    ok = bus->connect(LOGIN_SERVICE, m_sessionPath, SESSION_IFACE, "Unlock", this, SLOT(handleUnlockRequested()));
    if (!ok)
        qCWarning(lcSessionManager) << "Failed to connect to Unlock signal:" << bus->lastError().message();
}

bool SessionManager::exec(const QStringList& command) {
    if (command.isEmpty()) {
        return false;
    }

    using Qt::StringLiterals::operator""_s;
    static const QHash<QString, void (SessionManager::*)()> cmds = {
        { u"logout"_s, &SessionManager::logout },
        { u"suspend"_s, &SessionManager::suspend },
        { u"suspendthenhibernate"_s, &SessionManager::suspendThenHibernate },
        { u"hibernate"_s, &SessionManager::hibernate },
        { u"poweroff"_s, &SessionManager::poweroff },
        { u"reboot"_s, &SessionManager::reboot },
    };

    auto cmd = command.first();
    // Alias systemctl and loginctl to raw dbus calls (only match exact command)
    if ((cmd == u"systemctl"_s || cmd == u"loginctl"_s) && command.size() == 2)
        cmd = command.at(1);
    if (cmd == u"loginctl"_s && command.size() == 3 && command.at(1) == u"terminate-user"_s && command.at(2).isEmpty())
        cmd = u"logout"_s; // Manual alias `loginctl terminate-user ''` -> logout

    // Normalise command
    cmd = cmd.remove("-").remove("_").toLower();

    const auto methodPtr = cmds.value(cmd, nullptr);
    if (methodPtr) {
        (this->*methodPtr)();
        return true;
    }

    return false;
}

void SessionManager::logout() {
    callSession("Terminate");
}

void SessionManager::suspend() {
    callManager("Suspend");
}

void SessionManager::suspendThenHibernate() {
    if (queryHibernateAvailable()) {
        callManager("SuspendThenHibernate");
    } else {
        // Fall back to suspend when no hibernate
        qCInfo(lcSessionManager) << "SuspendThenHibernate unavailable, falling back to suspend";
        callManager("Suspend");
    }
}

void SessionManager::hibernate() {
    if (queryHibernateAvailable()) {
        callManager("Hibernate");
    } else {
        qCWarning(lcSessionManager) << "Hibernate unavailable, ignoring hibernate request";

        auto* const engine = qmlEngine(this);
        if (!engine)
            return;
        auto* const toaster = engine->singletonInstance<Toaster*>("Caelestia", "Toaster");
        if (!toaster)
            return;
        toaster->toast(
            tr("Hibernate failed"), tr("Enable hibernation to use this feature."), "warning", Toast::Type::Warning);
    }
}

void SessionManager::poweroff() {
    callManager("PowerOff");
}

void SessionManager::reboot() {
    callManager("Reboot");
}

std::optional<QDBusConnection> SessionManager::getSystemBus() const {
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        qCWarning(lcSessionManager) << "Failed to connect to system bus:" << bus.lastError().message();
        return std::nullopt;
    }
    return bus;
}

bool SessionManager::queryHibernateAvailable() const {
    auto bus = getSystemBus();
    if (!bus)
        return false;

    auto hibernateMsg = QDBusMessage::createMethodCall(LOGIN_SERVICE, LOGIN_PATH, LOGIN_IFACE, "CanHibernate");
    const QDBusReply<QString> hibernateReply = bus->call(hibernateMsg);
    if (!hibernateReply.isValid()) {
        qCWarning(lcSessionManager) << "Failed to query hibernate support:" << hibernateReply.error().message();
    } else {
        const auto state = hibernateReply.value();
        return state == "yes" || state == "challenge";
    }

    return false;
}

void SessionManager::call(const QString& path, const QString& iface, const QString& method, const QVariantList& args) {
    auto bus = getSystemBus();
    if (!bus)
        return;

    auto msg = QDBusMessage::createMethodCall(LOGIN_SERVICE, path, iface, method);
    msg.setArguments(args);

    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [method](QDBusPendingCallWatcher* self) {
        const QDBusPendingReply<> reply = *self;
        if (reply.isError())
            qCWarning(lcSessionManager) << "Call to" << method << "failed:" << reply.error().message();
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
