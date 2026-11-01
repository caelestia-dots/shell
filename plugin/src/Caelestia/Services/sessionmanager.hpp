#pragma once

#include <qdbusconnection.h>
#include <qdbusunixfiledescriptor.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qtimer.h>
#include <qvariant.h>

#include <optional>

namespace caelestia::services {

class SessionManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit SessionManager(QObject* parent = nullptr);

    Q_INVOKABLE void logout();
    Q_INVOKABLE void suspend();
    Q_INVOKABLE void suspendThenHibernate();
    Q_INVOKABLE void hibernate();
    Q_INVOKABLE void poweroff();
    Q_INVOKABLE void reboot();

    Q_INVOKABLE bool exec(const QStringList& command);

    // Lets the system go to sleep. Call once the screen is locked after aboutToSleep(), or
    // straight away if nothing needs to happen before sleeping. Released automatically
    // after a short timeout otherwise.
    Q_INVOKABLE void releaseSleepInhibitor();

signals:
    void aboutToSleep();
    void resumed();
    void lockRequested();
    void unlockRequested();

private slots:
    void handlePrepareForSleep(bool sleep);
    void handleLockRequested();
    void handleUnlockRequested();

private:
    [[nodiscard]] static std::optional<QDBusConnection> getSystemBus();
    [[nodiscard]] static bool queryHibernateAvailable();
    void call(const QString& path, const QString& iface, const QString& method, const QVariantList& args = {});
    void callManager(const QString& method);
    void callSession(const QString& method);
    void acquireSleepInhibitor();

    QString m_sessionPath;
    QDBusUnixFileDescriptor m_sleepInhibitor;
    QTimer m_sleepInhibitorTimeout;
};

} // namespace caelestia::services
