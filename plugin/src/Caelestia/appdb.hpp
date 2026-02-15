#pragma once

#include <qhash.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qqmllist.h>
#include <qtimer.h>

namespace caelestia {

class AppEntry : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("AppEntry instances can only be retrieved from an AppDb")

    // The actual DesktopEntry, but we don't have access to the type so it's a QObject
    Q_PROPERTY(QObject* entry READ entry CONSTANT)

    Q_PROPERTY(quint32 frequency READ frequency NOTIFY frequencyChanged)
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(QString comment READ comment NOTIFY commentChanged)
    Q_PROPERTY(QString execString READ execString NOTIFY execStringChanged)
    Q_PROPERTY(QString startupClass READ startupClass NOTIFY startupClassChanged)
    Q_PROPERTY(QString genericName READ genericName NOTIFY genericNameChanged)
    Q_PROPERTY(QString categories READ categories NOTIFY categoriesChanged)
    Q_PROPERTY(QString keywords READ keywords NOTIFY keywordsChanged)

public:
    explicit AppEntry(QObject* entry, quint32 frequency, QObject* parent = nullptr);

    [[nodiscard]] QObject* entry() const;

    [[nodiscard]] quint32 frequency() const;
    void setFrequency(quint32 frequency);
    void incrementFrequency();

    [[nodiscard]] QString id() const;
    [[nodiscard]] QString name() const;
    [[nodiscard]] QString comment() const;
    [[nodiscard]] QString execString() const;
    [[nodiscard]] QString startupClass() const;
    [[nodiscard]] QString genericName() const;
    [[nodiscard]] QString categories() const;
    [[nodiscard]] QString keywords() const;

signals:
    void frequencyChanged();
    void nameChanged();
    void commentChanged();
    void execStringChanged();
    void startupClassChanged();
    void genericNameChanged();
    void categoriesChanged();
    void keywordsChanged();

private:
    QObject* m_entry;
    quint32 m_frequency;
};

class AppDb : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString uuid READ uuid CONSTANT)
    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged REQUIRED)
    Q_PROPERTY(QObjectList entries READ entries WRITE setEntries NOTIFY entriesChanged REQUIRED)
    Q_PROPERTY(QQmlListProperty<caelestia::AppEntry> apps READ apps NOTIFY appsChanged)

public:
    explicit AppDb(QObject* parent = nullptr);

    [[nodiscard]] QString uuid() const;

    [[nodiscard]] QString path() const;
    void setPath(const QString& path);

    [[nodiscard]] QObjectList entries() const;
    void setEntries(const QObjectList& entries);

    [[nodiscard]] QQmlListProperty<AppEntry> apps();

    Q_INVOKABLE void incrementFrequency(const QString& id);

signals:
    void pathChanged();
    void entriesChanged();
    void appsChanged();

private:
    QTimer* m_timer;

    const QString m_uuid;
    QString m_path;
    QObjectList m_entries;
    QHash<QString, AppEntry*> m_apps;
    mutable QList<AppEntry*> m_sortedApps;

    QList<AppEntry*>& getSortedApps() const;
    quint32 getFrequency(const QString& id) const;
    void updateAppFrequencies();
    void updateApps();
};

} // namespace caelestia
