#include "appdb.hpp"

#include <qsqldatabase.h>
#include <qsqlquery.h>
#include <quuid.h>

namespace caelestia {

AppEntry::AppEntry(QObject* entry, unsigned int frequency, QObject* parent)
    : QObject(parent)
    , m_entry(entry)
    , m_frequency(frequency) {
    const auto mo = m_entry->metaObject();
    const auto tmo = metaObject();

    for (const auto& prop :
        { "name", "comment", "execString", "startupClass", "genericName", "categories", "keywords" }) {
        const auto metaProp = mo->property(mo->indexOfProperty(prop));
        const auto thisMetaProp = tmo->property(tmo->indexOfProperty(prop));
        QObject::connect(m_entry, metaProp.notifySignal(), this, thisMetaProp.notifySignal());
    }

    QObject::connect(m_entry, &QObject::destroyed, this, [this]() {
        m_entry = nullptr;
        deleteLater();
    });
}

QObject* AppEntry::entry() const {
    return m_entry;
}

quint32 AppEntry::frequency() const {
    return m_frequency;
}

void AppEntry::setFrequency(unsigned int frequency) {
    if (m_frequency != frequency) {
        m_frequency = frequency;
        emit frequencyChanged();
    }
}

void AppEntry::incrementFrequency() {
    m_frequency++;
    emit frequencyChanged();
}

QString AppEntry::id() const {
    if (!m_entry) {
        return "";
    }
    return m_entry->property("id").toString();
}

QString AppEntry::name() const {
    if (!m_entry) {
        return "";
    }
    return m_entry->property("name").toString();
}

QString AppEntry::comment() const {
    if (!m_entry) {
        return "";
    }
    return m_entry->property("comment").toString();
}

QString AppEntry::execString() const {
    if (!m_entry) {
        return "";
    }
    return m_entry->property("execString").toString();
}

QString AppEntry::startupClass() const {
    if (!m_entry) {
        return "";
    }
    return m_entry->property("startupClass").toString();
}

QString AppEntry::genericName() const {
    if (!m_entry) {
        return "";
    }
    return m_entry->property("genericName").toString();
}

QString AppEntry::categories() const {
    if (!m_entry) {
        return "";
    }
    return m_entry->property("categories").toStringList().join(" ");
}

QString AppEntry::keywords() const {
    if (!m_entry) {
        return "";
    }
    return m_entry->property("keywords").toStringList().join(" ");
}

AppDb::AppDb(QObject* parent)
    : QObject(parent)
    , m_timer(new QTimer(this))
    , m_uuid(QUuid::createUuid().toString()) {
    m_timer->setSingleShot(true);
    m_timer->setInterval(300);
    QObject::connect(m_timer, &QTimer::timeout, this, &AppDb::updateApps);

    auto db = QSqlDatabase::addDatabase("QSQLITE", m_uuid);
    db.setDatabaseName(":memory:");
    db.open();

    QSqlQuery query(db);
    query.exec("CREATE TABLE IF NOT EXISTS frequencies (id TEXT PRIMARY KEY, frequency INTEGER)");
}

QString AppDb::uuid() const {
    return m_uuid;
}

QString AppDb::path() const {
    return m_path;
}

void AppDb::setPath(const QString& path) {
    auto newPath = path.isEmpty() ? ":memory:" : path;

    if (m_path == newPath) {
        return;
    }

    m_path = newPath;
    emit pathChanged();

    auto db = QSqlDatabase::database(m_uuid, false);
    db.close();
    db.setDatabaseName(newPath);
    db.open();

    QSqlQuery query(db);
    query.exec("CREATE TABLE IF NOT EXISTS frequencies (id TEXT PRIMARY KEY, frequency INTEGER)");

    updateAppFrequencies();
}

QObjectList AppDb::entries() const {
    return m_entries;
}

void AppDb::setEntries(const QObjectList& entries) {
    if (m_entries == entries) {
        return;
    }

    m_entries = entries;
    emit entriesChanged();

    m_timer->start();
}

QQmlListProperty<AppEntry> AppDb::apps() {
    return QQmlListProperty<AppEntry>(this, &getSortedApps());
}

void AppDb::incrementFrequency(const QString& id) {
    auto db = QSqlDatabase::database(m_uuid);
    QSqlQuery query(db);

    query.prepare("INSERT INTO frequencies (id, frequency) "
                  "VALUES (:id, 1) "
                  "ON CONFLICT (id) DO UPDATE SET frequency = frequency + 1");
    query.bindValue(":id", id);
    query.exec();

    auto* app = m_apps.value(id);
    if (app) {
        const auto before = getSortedApps();

        app->incrementFrequency();

        if (before != getSortedApps()) {
            emit appsChanged();
        }
    } else {
        qWarning() << "AppDb::incrementFrequency: could not find app with id" << id;
    }
}

QList<AppEntry*>& AppDb::getSortedApps() const {
    m_sortedApps = m_apps.values();
    std::sort(m_sortedApps.begin(), m_sortedApps.end(), [](AppEntry* a, AppEntry* b) {
        if (a->frequency() != b->frequency()) {
            return a->frequency() > b->frequency();
        }
        return a->name().localeAwareCompare(b->name()) < 0;
    });
    return m_sortedApps;
}

quint32 AppDb::getFrequency(const QString& id) const {
    auto db = QSqlDatabase::database(m_uuid);
    QSqlQuery query(db);

    query.prepare("SELECT frequency FROM frequencies WHERE id = :id");
    query.bindValue(":id", id);

    if (query.exec() && query.next()) {
        return query.value(0).toUInt();
    }

    return 0;
}

void AppDb::updateAppFrequencies() {
    const auto before = getSortedApps();

    for (auto* app : std::as_const(m_apps)) {
        app->setFrequency(getFrequency(app->id()));
    }

    if (before != getSortedApps()) {
        emit appsChanged();
    }
}

void AppDb::updateApps() {
    bool dirty = false;

    for (const auto& entry : std::as_const(m_entries)) {
        const auto id = entry->property("id").toString();
        if (!m_apps.contains(id)) {
            dirty = true;
            auto* const newEntry = new AppEntry(entry, getFrequency(id), this);
            QObject::connect(newEntry, &QObject::destroyed, this, [id, this]() {
                if (m_apps.remove(id)) {
                    emit appsChanged();
                }
            });
            m_apps.insert(id, newEntry);
        }
    }

    QSet<QString> newIds;
    for (const auto& entry : std::as_const(m_entries)) {
        newIds.insert(entry->property("id").toString());
    }

    for (auto it = m_apps.keyBegin(); it != m_apps.keyEnd(); ++it) {
        const auto& id = *it;
        if (!newIds.contains(id)) {
            dirty = true;
            m_apps.take(id)->deleteLater();
        }
    }

    if (dirty) {
        emit appsChanged();
    }
}

} // namespace caelestia
