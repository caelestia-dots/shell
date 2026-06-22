#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace caelestia::services {

class SessionManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool hibernateAvailable READ hibernateAvailable NOTIFY hibernateAvailableChanged)

public:
    explicit SessionManager(QObject* parent = nullptr);

    [[nodiscard]] bool hibernateAvailable() const;

    Q_INVOKABLE void logout();
    Q_INVOKABLE void suspend();
    Q_INVOKABLE void suspendThenHibernate();
    Q_INVOKABLE void hibernate();
    Q_INVOKABLE void poweroff();
    Q_INVOKABLE void reboot();

    Q_INVOKABLE bool exec(const QStringList& command);

signals:
    void hibernateAvailableChanged();
    void aboutToSleep();
    void resumed();
    void lockRequested();
    void unlockRequested();

private slots:
    void handlePrepareForSleep(bool sleep);
    void handleLockRequested();
    void handleUnlockRequested();

private:
    void call(const QString& path, const QString& iface, const QString& method, const QVariantList& args = {});
    void callManager(const QString& method);
    void callSession(const QString& method);

    QString m_sessionPath;
    bool m_hibernateAvailable = false;
};

} // namespace caelestia::services
