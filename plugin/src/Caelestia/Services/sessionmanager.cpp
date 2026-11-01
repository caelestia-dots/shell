#include "sessionmanager.hpp"

#include <qdbusconnection.h>
#include <qdbuserror.h>
#include <qdbusmessage.h>
#include <qdbuspendingcall.h>
#include <qdbuspendingreply.h>
#include <qdbusreply.h>
#include <qloggingcategory.h>
#include <qprocess.h>

#include "core/toaster.hpp"
#include "util/i18n.hpp"

namespace {

Q_LOGGING_CATEGORY(lcSessionManager, "caelestia.services.sessionmanager", QtInfoMsg)

} // namespace

namespace caelestia::services {

using Qt::StringLiterals::operator""_s;
using util::i18n::mark;

namespace {

const QString k_loginService = u"org.freedesktop.login1"_s;
const QString k_loginPath = u"/org/freedesktop/login1"_s;
const QString k_loginIface = u"org.freedesktop.login1.Manager"_s;
const QString k_sessionIface = u"org.freedesktop.login1.Session"_s;

// How long sleep may be held back while the screen locks. logind caps this itself
// (InhibitDelayMaxSec, 5s by default), so this only matters if nothing releases it.
constexpr int k_sleepInhibitorTimeoutMs = 2000;

} // namespace

namespace {

// `loginctl terminate-user <name>` or `loginctl terminate-session <id>` for the user or session the
// shell is running in (an empty target counts as ours, as `terminate-user ''` always has)
bool isOwnSessionTermination(const QStringList& command) {
    if (command.size() != 3 || command.first() != u"loginctl"_s)
        return false;

    const QString& target = command.at(2);
    if (command.at(1) == u"terminate-user"_s)
        return target.isEmpty() || target == qEnvironmentVariable("USER");
    if (command.at(1) == u"terminate-session"_s)
        return target.isEmpty() || target == qEnvironmentVariable("XDG_SESSION_ID");
    return false;
}

} // namespace

SessionManager::SessionManager(QObject* parent)
    : QObject(parent) {
    m_sleepInhibitorTimeout.setSingleShot(true);
    m_sleepInhibitorTimeout.setInterval(k_sleepInhibitorTimeoutMs);
    connect(&m_sleepInhibitorTimeout, &QTimer::timeout, this, &SessionManager::releaseSleepInhibitor);

    auto bus = getSystemBus();
    if (!bus)
        return;

    bool ok = bus->connect(
        k_loginService, k_loginPath, k_loginIface, u"PrepareForSleep"_s, this, SLOT(handlePrepareForSleep(bool)));
    if (!ok)
        qCWarning(lcSessionManager) << "Failed to connect to PrepareForSleep signal:" << bus->lastError().message();
    else
        acquireSleepInhibitor();

    auto sessionMsg = QDBusMessage::createMethodCall(k_loginService, k_loginPath, k_loginIface, u"GetSession"_s);
    sessionMsg.setArguments({ u"auto"_s });
    const QDBusReply<QDBusObjectPath> sessionReply = bus->call(sessionMsg);
    if (!sessionReply.isValid()) {
        qCWarning(lcSessionManager) << "Failed to get session path:" << sessionReply.error().message();
        return;
    }
    m_sessionPath = sessionReply.value().path();

    ok = bus->connect(k_loginService, m_sessionPath, k_sessionIface, u"Lock"_s, this, SLOT(handleLockRequested()));
    if (!ok)
        qCWarning(lcSessionManager) << "Failed to connect to Lock signal:" << bus->lastError().message();

    ok = bus->connect(k_loginService, m_sessionPath, k_sessionIface, u"Unlock"_s, this, SLOT(handleUnlockRequested()));
    if (!ok)
        qCWarning(lcSessionManager) << "Failed to connect to Unlock signal:" << bus->lastError().message();
}

bool SessionManager::exec(const QStringList& command) {
    if (command.isEmpty()) {
        return false;
    }

    static const QHash<QString, void (SessionManager::*)()> k_cmds = {
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
    // Terminating the shell's own user or session is a logout, so it goes through logout() and ends the
    // session through uwsm. Calling loginctl directly would kill the session leader as well.
    if (isOwnSessionTermination(command))
        cmd = u"logout"_s;

    // Normalise command
    cmd = cmd.remove(u'-').remove(u'_').toLower();

    const auto methodPtr = k_cmds.value(cmd, nullptr);
    if (methodPtr) {
        (this->*methodPtr)();
        return true;
    }

    return false;
}

void SessionManager::logout() {
    // Under uwsm the compositor runs as a systemd unit that uwsm stops itself. Terminating the logind
    // session kills the processes under those units without stopping them, and the screen can be left
    // black instead of showing the login screen. So ask uwsm to stop the session when it's the one
    // running, and only fall back to logind otherwise.
    if (QProcess::execute(u"uwsm"_s, { u"check"_s, u"is-active"_s }) == 0) {
        if (QProcess::startDetached(u"uwsm"_s, { u"stop"_s }))
            return;
        qCWarning(lcSessionManager) << "Failed to run uwsm stop, terminating the session instead";
    }

    callSession(u"Terminate"_s);
}

void SessionManager::suspend() {
    callManager(u"Suspend"_s);
}

void SessionManager::suspendThenHibernate() {
    if (queryHibernateAvailable()) {
        callManager(u"SuspendThenHibernate"_s);
    } else {
        // Fall back to suspend when no hibernate
        qCInfo(lcSessionManager) << "SuspendThenHibernate unavailable, falling back to suspend";
        callManager(u"Suspend"_s);
    }
}

void SessionManager::hibernate() {
    if (queryHibernateAvailable()) {
        callManager(u"Hibernate"_s);
    } else {
        qCWarning(lcSessionManager) << "Hibernate unavailable, ignoring hibernate request";

        Toaster::instance()->toast(mark(u"Hibernate failed"_s), mark(u"Enable hibernation to use this feature."_s),
            u"warning"_s, Toast::Type::Warning);
    }
}

void SessionManager::poweroff() {
    callManager(u"PowerOff"_s);
}

void SessionManager::reboot() {
    callManager(u"Reboot"_s);
}

std::optional<QDBusConnection> SessionManager::getSystemBus() {
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        qCWarning(lcSessionManager) << "Failed to connect to system bus:" << bus.lastError().message();
        return std::nullopt;
    }
    return bus;
}

bool SessionManager::queryHibernateAvailable() {
    auto bus = getSystemBus();
    if (!bus)
        return false;

    const auto hibernateMsg =
        QDBusMessage::createMethodCall(k_loginService, k_loginPath, k_loginIface, u"CanHibernate"_s);
    const QDBusReply<QString> hibernateReply = bus->call(hibernateMsg);
    if (!hibernateReply.isValid()) {
        qCWarning(lcSessionManager) << "Failed to query hibernate support:" << hibernateReply.error().message();
    } else {
        const auto state = hibernateReply.value();
        return state == u"yes"_s || state == u"challenge"_s;
    }

    return false;
}

void SessionManager::call(const QString& path, const QString& iface, const QString& method, const QVariantList& args) {
    auto bus = getSystemBus();
    if (!bus)
        return;

    auto msg = QDBusMessage::createMethodCall(k_loginService, path, iface, method);
    msg.setArguments(args);

    // connect() and deleteLater() need a non-const pointer
    // NOLINTNEXTLINE(misc-const-correctness)
    auto* const watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [method](QDBusPendingCallWatcher* self) {
        const QDBusPendingReply<> reply = *self;
        if (reply.isError())
            qCWarning(lcSessionManager) << "Call to" << method << "failed:" << reply.error().message();
        self->deleteLater();
    });
    // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks) watcher is parented and self-deletes
}

void SessionManager::callManager(const QString& method) {
    call(k_loginPath, k_loginIface, method, { /* interactive = */ true });
}

void SessionManager::callSession(const QString& method) {
    if (m_sessionPath.isEmpty()) {
        qCWarning(lcSessionManager) << "Cannot call" << method << "- no session path";
        return;
    }

    call(m_sessionPath, k_sessionIface, method);
}

void SessionManager::acquireSleepInhibitor() {
    if (m_sleepInhibitor.isValid())
        return;

    auto bus = getSystemBus();
    if (!bus)
        return;

    // A delay lock makes logind wait (up to InhibitDelayMaxSec) before sleeping, so the
    // lock screen can be up before the system suspends instead of racing with it
    auto msg = QDBusMessage::createMethodCall(k_loginService, k_loginPath, k_loginIface, u"Inhibit"_s);
    msg.setArguments({ u"sleep"_s, u"Caelestia Shell"_s, u"Locking the screen before sleep"_s, u"delay"_s });

    const auto* const watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher* self) {
        const QDBusPendingReply<QDBusUnixFileDescriptor> reply = *self;
        if (reply.isError())
            qCWarning(lcSessionManager) << "Failed to take sleep inhibitor:" << reply.error().message();
        else
            m_sleepInhibitor = reply.value();
        self->deleteLater();
    });
    // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks) watcher is parented and self-deletes
}

void SessionManager::releaseSleepInhibitor() {
    m_sleepInhibitorTimeout.stop();
    // Dropping the last copy of the fd closes it, which releases the inhibitor
    m_sleepInhibitor = QDBusUnixFileDescriptor();
}

void SessionManager::handlePrepareForSleep(bool sleep) {
    if (sleep) {
        if (m_sleepInhibitor.isValid())
            m_sleepInhibitorTimeout.start();
        emit aboutToSleep();
    } else {
        releaseSleepInhibitor();
        acquireSleepInhibitor();
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
