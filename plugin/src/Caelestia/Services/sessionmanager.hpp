#pragma once

#include <qdbusconnection.h>
#include <qdbusunixfiledescriptor.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

#include <optional>

namespace caelestia::shell::services {

class SessionManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // Whether a lid switch inhibitor is requested, lidSwitchInhibited is whether one is actually held
    Q_PROPERTY(bool inhibitLidSwitch READ inhibitLidSwitch WRITE setInhibitLidSwitch NOTIFY inhibitLidSwitchChanged)
    Q_PROPERTY(bool lidSwitchInhibited READ lidSwitchInhibited NOTIFY lidSwitchInhibitedChanged)

public:
    explicit SessionManager(QObject* parent = nullptr);

    [[nodiscard]] bool inhibitLidSwitch() const;
    void setInhibitLidSwitch(bool inhibit);

    [[nodiscard]] bool lidSwitchInhibited() const;

    Q_INVOKABLE void logout();
    Q_INVOKABLE void suspend();
    Q_INVOKABLE void suspendThenHibernate();
    Q_INVOKABLE void hibernate();
    Q_INVOKABLE void poweroff();
    Q_INVOKABLE void reboot();

    Q_INVOKABLE bool exec(const QStringList& command);

signals:
    void inhibitLidSwitchChanged();
    void lidSwitchInhibitedChanged();
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
    void acquireLidSwitchLock();
    void setLidSwitchLock(const QDBusUnixFileDescriptor& lock);

    QString m_sessionPath;

    bool m_inhibitLidSwitch = false;
    quint64 m_lidSwitchRequest = 0;
    QDBusUnixFileDescriptor m_lidSwitchLock;
};

} // namespace caelestia::shell::services
