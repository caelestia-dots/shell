#include "notifstore.hpp"

#include <qdir.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qloggingcategory.h>
#include <qsqldatabase.h>
#include <qsqlerror.h>
#include <qsqlquery.h>
#include <qstandardpaths.h>
#include <quuid.h>

#include <algorithm>
#include <limits>
#include <utility>

#include "notifpopups.hpp"

namespace {

Q_LOGGING_CATEGORY(lcNotifStore, "caelestia.notifs.store", QtInfoMsg)

} // namespace

namespace caelestia::shell::models {

using Qt::StringLiterals::operator""_s;

namespace {

constexpr qsizetype k_maxPerGroup = 30;
constexpr qsizetype k_maxTotal = 300;
constexpr int k_schemaVersion = 1;

constexpr QStringView k_createTable = uR"(
    CREATE TABLE IF NOT EXISTS notifications (
        id               TEXT    PRIMARY KEY,
        time             INTEGER NOT NULL,
        summary          TEXT    NOT NULL DEFAULT '',
        body             TEXT    NOT NULL DEFAULT '',
        app_icon         TEXT    NOT NULL DEFAULT '',
        app_name         TEXT    NOT NULL DEFAULT '',
        image            TEXT    NOT NULL DEFAULT '',
        expire_timeout   REAL    NOT NULL,
        urgency          INTEGER NOT NULL,
        resident         INTEGER NOT NULL DEFAULT 0,
        has_action_icons INTEGER NOT NULL DEFAULT 0,
        actions          TEXT    NOT NULL DEFAULT '[]',
        progress         INTEGER NOT NULL DEFAULT -1
    )
)";

constexpr QStringView k_upsert = uR"(
    INSERT INTO notifications (
        id, time, summary, body, app_icon, app_name, image,
        expire_timeout, urgency, resident, has_action_icons, actions, progress
    ) VALUES (
        :id, :time, :summary, :body, :app_icon, :app_name, :image,
        :expire_timeout, :urgency, :resident, :has_action_icons, :actions, :progress
    )
    ON CONFLICT (id) DO UPDATE SET
        summary          = excluded.summary,
        body             = excluded.body,
        app_icon         = excluded.app_icon,
        app_name         = excluded.app_name,
        image            = excluded.image,
        expire_timeout   = excluded.expire_timeout,
        urgency          = excluded.urgency,
        resident         = excluded.resident,
        has_action_icons = excluded.has_action_icons,
        actions          = excluded.actions,
        progress         = excluded.progress
)";

constexpr QStringView k_selectAll = uR"(
    SELECT id, time, summary, body, app_icon, app_name, image,
           expire_timeout, urgency, resident, has_action_icons, actions, progress
    FROM notifications
    ORDER BY time ASC
)";

QString serialiseActions(const QList<NotifAction>& actions) {
    QJsonArray array;
    for (const auto& action : actions)
        array << QJsonObject{ { u"id"_s, action.identifier() }, { u"text"_s, action.text() } };
    return QString::fromUtf8(QJsonDocument(array).toJson(QJsonDocument::Compact));
}

QList<NotifAction> deserialiseActions(NotifData* parent, const QString& json) {
    QList<NotifAction> actions;
    const auto array = QJsonDocument::fromJson(json.toUtf8()).array();
    actions.reserve(array.size());

    for (const auto& item : array) {
        const auto obj = item.toObject();
        actions.emplaceBack(parent, obj[u"id"_s].toString(), obj[u"text"_s].toString());
    }

    return actions;
}

// null QString binds as SQL NULL, which violates NOT NULL
QString text(const QString& value) {
    return value.isNull() ? u""_s : value;
}

} // namespace

NotifStore::NotifStore(QObject* parent)
    : QObject(parent)
    , m_connectionName(QUuid::createUuid().toString())
    , m_groups(this) {
    m_flushTimer.setSingleShot(true);
    QObject::connect(&m_flushTimer, &QTimer::timeout, this, &NotifStore::flush);
    m_timeStrTimer.setSingleShot(true);
    QObject::connect(&m_timeStrTimer, &QTimer::timeout, this, &NotifStore::refreshTimeStrs);

    const auto dir = QStandardPaths::writableLocation(QStandardPaths::GenericStateLocation) + u"/caelestia"_s;
    QDir().mkpath(dir);

    auto db = QSqlDatabase::addDatabase(u"QSQLITE"_s, m_connectionName);
    db.setDatabaseName(dir + u"/notifs.db"_s);
    if (!db.open()) {
        qCWarning(lcNotifStore) << "Failed to open" << db.databaseName() << db.lastError().text();
        return;
    }

    QSqlQuery query(db);
    query.exec(u"PRAGMA journal_mode = WAL"_s);
    query.exec(u"PRAGMA synchronous = NORMAL"_s);
    if (query.exec(u"PRAGMA user_version"_s) && query.next() && query.value(0).toInt() != k_schemaVersion) {
        query.exec(u"DROP TABLE IF EXISTS notifications"_s);
        query.exec(u"PRAGMA user_version = %1"_s.arg(k_schemaVersion));
    }
    if (!query.exec(k_createTable.toString()))
        qCWarning(lcNotifStore) << "Failed to create table" << query.lastError().text();

    loadNotifs();
}

NotifStore::~NotifStore() {
    flush();
    QSqlDatabase::database(m_connectionName, false).close();
    QSqlDatabase::removeDatabase(m_connectionName);
}

QQmlListProperty<NotifData> NotifStore::notifs() {
    return { this, nullptr,
        [](auto* p) {
            return static_cast<NotifStore*>(p->object)->m_notifs.size();
        },
        [](auto* p, qsizetype i) {
            return static_cast<NotifStore*>(p->object)->m_notifs.at(i);
        } };
}

QQmlListProperty<NotifGroup> NotifStore::groups() {
    return { this, nullptr,
        [](auto* p) {
            return static_cast<NotifStore*>(p->object)->m_groups.list().size();
        },
        [](auto* p, qsizetype i) {
            return static_cast<NotifStore*>(p->object)->m_groups.list().at(i);
        } };
}

NotifData* NotifStore::add(QObject* backer, bool popup) {
    if (!backer) {
        qCWarning(lcNotifStore) << "Attempted to add null backer";
        return nullptr;
    }

    auto* const notif = new NotifData(backer, this);
    m_notifs.prepend(notif);
    track(notif);
    m_groups.add(notif);
    emit groupsChanged();
    markDirty(notif);

    emit notifsChanged();
    if (popup) {
        for (auto* const popups : std::as_const(m_popups))
            popups->offer(notif);
    }

    enforceLimits({ notif->m_appName });
    return notif;
}

void NotifStore::clear() {
    const auto notifs = m_notifs;
    for (auto* const notif : notifs)
        notif->dismiss();
}

void NotifStore::closePopups() {
    for (auto* const notif : std::as_const(m_notifs))
        closePopup(notif);
}

void NotifStore::closePopup(NotifData* notif) {
    for (auto* const popups : std::as_const(m_popups))
        popups->close(notif);
}

void NotifStore::enforceLimits(const QSet<QString>& groups) {
    for (const auto& group : groups) {
        evict(k_maxPerGroup, [&group](const NotifData* n) {
            return n->m_appName == group;
        });
    }
    evict(k_maxTotal, [](const NotifData*) {
        return true;
    });
}

void NotifStore::evict(qsizetype limit, const std::function<bool(const NotifData*)>& inScope) {
    const auto weaker = [](const NotifData* a, const NotifData* b) {
        return a->m_urgency < b->m_urgency || (a->m_urgency == b->m_urgency && a->m_createdAt < b->m_createdAt);
    };

    auto excess = std::ranges::count_if(m_notifs, inScope) - limit;
    while (excess-- > 0) {
        NotifData* victim = nullptr;
        for (auto* const n : std::as_const(m_notifs)) {
            if (inScope(n) && (!victim || weaker(n, victim)))
                victim = n;
        }

        if (!victim)
            return;

        victim->dismiss();
    }
}

void NotifStore::track(NotifData* notif) {
    QObject::connect(notif, &NotifData::changed, this, [this, notif] {
        markDirty(notif);
    });
    QObject::connect(notif, &NotifData::closed, this, [this, notif] {
        remove(notif);
    });
    QObject::connect(notif, &NotifData::appNameChanged, this, [this, notif] {
        regroup(notif);
    });

    notif->refreshTimeStr();
    const auto interval = notif->timeStrInterval();
    if (!m_timeStrTimer.isActive() || m_timeStrTimer.remainingTime() > interval)
        m_timeStrTimer.start(interval);
}

void NotifStore::refreshTimeStrs() {
    if (m_notifs.isEmpty())
        return;

    auto interval = std::numeric_limits<int>::max();
    for (auto* notif : std::as_const(m_notifs)) {
        notif->refreshTimeStr();
        interval = std::min(interval, notif->timeStrInterval());
    }
    m_timeStrTimer.start(interval);
}

void NotifStore::regroup(NotifData* notif) {
    const auto removed = m_groups.remove(notif);
    const auto added = m_groups.add(notif);
    if (removed || added)
        emit groupsChanged();

    for (auto* const popups : std::as_const(m_popups))
        popups->regroup(notif);
}

void NotifStore::markDirty(NotifData* notif) {
    m_dirty.insert(notif);
    m_flushTimer.start();
}

void NotifStore::flush() {
    m_flushTimer.stop();
    if (m_dirty.isEmpty())
        return;

    auto db = QSqlDatabase::database(m_connectionName);
    if (!db.transaction())
        qCWarning(lcNotifStore) << "Flush transaction failed" << db.lastError().text();

    for (const auto* notif : std::as_const(m_dirty))
        save(notif);
    m_dirty.clear();

    if (!db.commit())
        qCWarning(lcNotifStore) << "Flush commit failed" << db.lastError().text();
}

void NotifStore::save(const NotifData* notif) {
    QSqlQuery query(QSqlDatabase::database(m_connectionName));
    query.prepare(k_upsert.toString());
    query.bindValue(u":id"_s, notif->m_id);
    query.bindValue(u":time"_s, notif->m_createdAt);
    query.bindValue(u":summary"_s, text(notif->m_summary));
    query.bindValue(u":body"_s, text(notif->m_body));
    query.bindValue(u":app_icon"_s, text(notif->m_appIcon));
    query.bindValue(u":app_name"_s, text(notif->m_appName));
    query.bindValue(u":image"_s, text(notif->m_image));
    query.bindValue(u":expire_timeout"_s, notif->m_expireTimeout);
    query.bindValue(u":urgency"_s, static_cast<int>(notif->m_urgency));
    query.bindValue(u":resident"_s, notif->m_resident);
    query.bindValue(u":has_action_icons"_s, notif->m_hasActionIcons);
    query.bindValue(u":actions"_s, serialiseActions(notif->m_actions));
    query.bindValue(u":progress"_s, notif->m_progress);

    if (!query.exec())
        qCWarning(lcNotifStore) << "Failed to save" << notif->m_id << query.lastError().text();
}

void NotifStore::remove(NotifData* notif) {
    m_dirty.remove(notif);
    QSqlQuery query(QSqlDatabase::database(m_connectionName));
    query.prepare(u"DELETE FROM notifications WHERE id = :id"_s);
    query.bindValue(u":id"_s, notif->m_id);
    if (!query.exec())
        qCWarning(lcNotifStore) << "Failed to remove" << notif->m_id << query.lastError().text();

    if (m_notifs.removeOne(notif))
        emit notifsChanged();
    if (m_groups.remove(notif))
        emit groupsChanged();
    closePopup(notif);
}

void NotifStore::loadNotifs() {
    QSqlQuery query(QSqlDatabase::database(m_connectionName));
    if (!query.exec(k_selectAll.toString())) {
        qCWarning(lcNotifStore) << "Failed to load notifs:" << query.lastError().text();
        return;
    }

    for (auto* notif : std::as_const(m_notifs))
        notif->deleteLater();
    m_notifs.clear();

    while (query.next()) {
        auto* const notif = new NotifData(this);
        notif->m_id = query.value(0).toString();
        notif->m_createdAt = query.value(1).toLongLong();
        notif->m_summary = query.value(2).toString();
        notif->m_body = query.value(3).toString();
        notif->m_appIcon = query.value(4).toString();
        notif->m_appName = query.value(5).toString();
        notif->m_image = query.value(6).toString();
        notif->m_expireTimeout = query.value(7).toInt();
        notif->m_urgency = static_cast<NotifData::Urgency>(query.value(8).toInt());
        notif->m_resident = query.value(9).toBool();
        notif->m_hasActionIcons = query.value(10).toBool();
        notif->m_actions = deserialiseActions(notif, query.value(11).toString());
        notif->m_progress = query.value(12).toInt();
        m_notifs.prepend(notif);
        track(notif);
        m_groups.add(notif);
    }

    emit notifsChanged();
    emit groupsChanged();

    QSet<QString> groups;
    for (const auto* notif : std::as_const(m_notifs))
        groups << notif->m_appName;
    enforceLimits(groups);
}

} // namespace caelestia::shell::models
