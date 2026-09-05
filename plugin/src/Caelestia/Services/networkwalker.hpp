#pragma once

#include <qdbusconnection.h>
#include <qobject.h>
#include <qset.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

#include <optional>

namespace caelestia::services {

// Shared plumbing for the singletons that mirror a NetworkManager object tree
// over D-Bus.
//
// Both of them do the same thing: subscribe to a root object, walk it whenever
// something changes, hold every async read open so a partial tree is never
// published, and drop whatever the walk didn't see. Only the objects being
// walked differ, so that part is left to subclasses.
class NmWalker : public QObject {
    Q_OBJECT

    // False until a full snapshot has been read, so consumers can hold their
    // previous behaviour rather than acting on an empty list.
    Q_PROPERTY(bool ready READ ready NOTIFY changed)

public:
    [[nodiscard]] bool ready() const;

signals:
    void changed();
    void itemsChanged();

protected:
    explicit NmWalker(QString rootPath, QObject* parent = nullptr);

    // Reads the root object and issues a read per child. Called once per walk.
    virtual void readRoot() = 0;
    // Whether a PropertiesChanged on this interface means the tree moved.
    // Interfaces whose objects track themselves should say no.
    [[nodiscard]] virtual bool triggersRefresh(const QString& iface) const = 0;
    // Drops anything whose path isn't in seen(). Should set listChanged() when
    // it removes something.
    virtual void pruneUnseen() = 0;
    // NetworkManager went away; report nothing rather than a stale tree.
    virtual void clearItems() = 0;

    // One walk at a time, with a flag to run again after. Bursts of signals
    // would otherwise each start their own and land out of order.
    void scheduleRefresh();
    // Each async read holds a reference; the result is published when the last
    // one lands. Only for reads belonging to a walk: a read started outside one
    // must not touch this, or it will drive the count to zero mid-walk.
    void step(int delta);
    // Ends a walk that can't start, so the ready flag isn't held back forever.
    void abandonWalk();
    void watchObject(const QString& path);

    [[nodiscard]] bool walking() const;
    [[nodiscard]] QSet<QString>& seen();
    void setListChanged();

    [[nodiscard]] static std::optional<QDBusConnection> systemBus();

private slots:
    void handlePropertiesChanged(const QString& iface, const QVariantMap& properties, const QStringList& invalidated);
    void handleNameOwnerChanged(const QString& name, const QString& oldOwner, const QString& newOwner);

private:
    void refresh();
    void finish();

    QString m_rootPath;
    bool m_ready = false;

    // Paths seen by the walk in progress; anything missing afterwards has gone.
    QSet<QString> m_seen;

    bool m_refreshing = false;
    bool m_refreshQueued = false;
    int m_pending = 0;
    bool m_listChanged = false;

    QSet<QString> m_watched;
};

} // namespace caelestia::services
