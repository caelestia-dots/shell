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

namespace {

Q_LOGGING_CATEGORY(lcNotifStore, "caelestia.notifs.store", QtInfoMsg)

} // namespace

namespace caelestia::shell::models {

using Qt::StringLiterals::operator""_s;

namespace {

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
        actions          TEXT    NOT NULL DEFAULT '[]'
    )
)";

constexpr QStringView k_upsert = uR"(
    INSERT INTO notifications (
        id, time, summary, body, app_icon, app_name, image,
        expire_timeout, urgency, resident, has_action_icons, actions
    ) VALUES (
        :id, :time, :summary, :body, :app_icon, :app_name, :image,
        :expire_timeout, :urgency, :resident, :has_action_icons, :actions
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
        actions          = excluded.actions
)";

constexpr QStringView k_selectAll = uR"(
    SELECT id, time, summary, body, app_icon, app_name, image,
           expire_timeout, urgency, resident, has_action_icons, actions
    FROM notifications
    ORDER BY time DESC
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

} // namespace

NotifStore::NotifStore(QObject* parent)
    : QObject(parent)
    , m_connectionName(QUuid::createUuid().toString()) {
    m_flushTimer.setSingleShot(true);
    QObject::connect(&m_flushTimer, &QTimer::timeout, this, &NotifStore::flush);

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

NotifData* NotifStore::add(QObject* backer) {
    if (!backer) {
        qCWarning(lcNotifStore) << "Attempted to add null backer";
        return nullptr;
    }

    auto* const notif = new NotifData(backer, this);
    m_notifs.prepend(notif);
    track(notif);
    markDirty(notif);
    emit notifsChanged();
    return notif;
}

void NotifStore::track(NotifData* notif) {
    QObject::connect(notif, &NotifData::changed, this, [this, notif] {
        markDirty(notif);
    });
    QObject::connect(notif, &NotifData::closed, this, [this, notif] {
        remove(notif);
    });
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
    query.bindValue(u":summary"_s, notif->m_summary);
    query.bindValue(u":body"_s, notif->m_body);
    query.bindValue(u":app_icon"_s, notif->m_appIcon);
    query.bindValue(u":app_name"_s, notif->m_appName);
    query.bindValue(u":image"_s, notif->m_image);
    query.bindValue(u":expire_timeout"_s, notif->m_expireTimeout);
    query.bindValue(u":urgency"_s, static_cast<int>(notif->m_urgency));
    query.bindValue(u":resident"_s, notif->m_resident);
    query.bindValue(u":has_action_icons"_s, notif->m_hasActionIcons);
    query.bindValue(u":actions"_s, serialiseActions(notif->m_actions));

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
    notif->deleteLater();
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
        notif->m_expireTimeout = query.value(7).toReal();
        notif->m_urgency = static_cast<NotifData::Urgency>(query.value(8).toInt());
        notif->m_resident = query.value(9).toBool();
        notif->m_hasActionIcons = query.value(10).toBool();
        notif->m_actions = deserialiseActions(notif, query.value(11).toString());
        m_notifs << notif;
        track(notif);
    }

    emit notifsChanged();
}

} // namespace caelestia::shell::models
