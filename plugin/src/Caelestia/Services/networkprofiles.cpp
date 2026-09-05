#include "networkprofiles.hpp"

#include <qdbusargument.h>
#include <qdbusextratypes.h>
#include <qdbusmessage.h>
#include <qdbusmetatype.h>
#include <qdbuspendingcall.h>
#include <qdbuspendingreply.h>
#include <qloggingcategory.h>
#include <qtimer.h>

#include <utility>

namespace caelestia::services {

namespace {

Q_LOGGING_CATEGORY(logNetworkProfiles, "caelestia.services.networkprofiles", QtWarningMsg);

constexpr const char* kService = "org.freedesktop.NetworkManager";
constexpr const char* kSettingsPath = "/org/freedesktop/NetworkManager/Settings";
constexpr const char* kSettingsIface = "org.freedesktop.NetworkManager.Settings";
constexpr const char* kConnectionIface = "org.freedesktop.NetworkManager.Settings.Connection";
constexpr const char* kPropsIface = "org.freedesktop.DBus.Properties";

// Setting group names, as NetworkManager keys them in GetSettings.
constexpr const char* kGroupConnection = "connection";
constexpr const char* kGroupWireless = "802-11-wireless";
constexpr const char* kGroupWirelessSecurity = "802-11-wireless-security";

// An `ay` inside a variant arrives as a byte array on most paths, but as a
// nested argument on some, so both are worth handling.
QString byteArrayToString(const QVariant& value) {
    if (value.metaType().id() == QMetaType::QByteArray) {
        return QString::fromUtf8(value.toByteArray());
    }

    if (value.canConvert<QDBusArgument>()) {
        QByteArray bytes;
        value.value<QDBusArgument>() >> bytes;
        return QString::fromUtf8(bytes);
    }

    return {};
}

} // namespace

NmConnection::NmConnection(QString path, QObject* parent)
    : QObject(parent)
    , m_path(std::move(path)) {}

QString NmConnection::path() const {
    return m_path;
}

QString NmConnection::id() const {
    return m_id;
}

QString NmConnection::uuid() const {
    return m_uuid;
}

QString NmConnection::type() const {
    return m_type;
}

QString NmConnection::ssid() const {
    return m_ssid;
}

QString NmConnection::keyMgmt() const {
    return m_keyMgmt;
}

bool NmConnection::autoconnect() const {
    return m_autoconnect;
}

void NmConnection::update(const QMap<QString, QVariantMap>& settings) {
    const auto connection = settings.value(QString::fromUtf8(kGroupConnection));
    const auto wireless = settings.value(QString::fromUtf8(kGroupWireless));
    const auto security = settings.value(QString::fromUtf8(kGroupWirelessSecurity));

    const auto id = connection.value(QStringLiteral("id")).toString();
    const auto uuid = connection.value(QStringLiteral("uuid")).toString();
    const auto type = connection.value(QStringLiteral("type")).toString();
    const auto ssid = byteArrayToString(wireless.value(QStringLiteral("ssid")));
    const auto keyMgmt = security.value(QStringLiteral("key-mgmt")).toString();

    // NetworkManager leaves autoconnect out when it's at its default, which is
    // on, so a missing key is not false.
    const auto autoconnectValue = connection.find(QStringLiteral("autoconnect"));
    const auto autoconnect = autoconnectValue == connection.end() ? true : autoconnectValue.value().toBool();

    if (id == m_id && uuid == m_uuid && type == m_type && ssid == m_ssid && keyMgmt == m_keyMgmt &&
        autoconnect == m_autoconnect) {
        return;
    }

    m_id = id;
    m_uuid = uuid;
    m_type = type;
    m_ssid = ssid;
    m_keyMgmt = keyMgmt;
    m_autoconnect = autoconnect;

    emit changed();
}

void NmConnection::watch() {
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        return;
    }

    bus.connect(
        QString::fromUtf8(kService),
        m_path,
        QString::fromUtf8(kConnectionIface),
        QStringLiteral("Updated"),
        this,
        SLOT(handleUpdated()));
}

void NmConnection::handleUpdated() {
    emit needsReread();
}

NetworkProfiles::NetworkProfiles(QObject* parent)
    : QObject(parent) {
    // GetSettings returns a{sa{sv}}, which needs registering before QtDBus will
    // demarshal it into a nested map.
    qDBusRegisterMetaType<QMap<QString, QVariantMap>>();

    auto bus = systemBus();
    if (!bus) {
        return;
    }

    // NetworkManager may not be up yet, or may restart under us.
    bus->connect(
        QStringLiteral("org.freedesktop.DBus"),
        QStringLiteral("/org/freedesktop/DBus"),
        QStringLiteral("org.freedesktop.DBus"),
        QStringLiteral("NameOwnerChanged"),
        QStringLiteral("sss"),
        this,
        SLOT(handleNameOwnerChanged(QString, QString, QString)));

    watchObject(QString::fromUtf8(kSettingsPath));
    scheduleRefresh();
}

bool NetworkProfiles::ready() const {
    return m_ready;
}

QQmlListProperty<NmConnection> NetworkProfiles::profiles() {
    return { this, &m_profiles };
}

std::optional<QDBusConnection> NetworkProfiles::systemBus() {
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        qCWarning(logNetworkProfiles) << "System bus unavailable";
        return std::nullopt;
    }
    return bus;
}

void NetworkProfiles::watchObject(const QString& path) {
    if (path.isEmpty() || path == QStringLiteral("/") || m_watched.contains(path)) {
        return;
    }

    auto bus = systemBus();
    if (!bus) {
        return;
    }

    if (bus->connect(
            QString::fromUtf8(kService),
            path,
            QString::fromUtf8(kPropsIface),
            QStringLiteral("PropertiesChanged"),
            this,
            SLOT(handlePropertiesChanged(QString, QVariantMap, QStringList)))) {
        m_watched.insert(path);
    }
}

void NetworkProfiles::handlePropertiesChanged(
    const QString& iface, const QVariantMap& properties, const QStringList& invalidated) {
    Q_UNUSED(properties);
    Q_UNUSED(invalidated);

    // Profiles re-read themselves when edited, so this only needs to catch
    // profiles being added or removed.
    if (iface == QString::fromUtf8(kSettingsIface)) {
        scheduleRefresh();
    }
}

void NetworkProfiles::handleNameOwnerChanged(const QString& name, const QString& oldOwner, const QString& newOwner) {
    Q_UNUSED(oldOwner);

    if (name != QString::fromUtf8(kService)) {
        return;
    }

    m_watched.clear();

    if (newOwner.isEmpty()) {
        // NetworkManager went away; report nothing rather than stale profiles.
        clearProfiles();
        m_ready = false;
        emit profilesChanged();
        emit changed();
        return;
    }

    // Fresh objects on the new owner, so the old subscriptions are worthless.
    watchObject(QString::fromUtf8(kSettingsPath));
    scheduleRefresh();
}

void NetworkProfiles::clearProfiles() {
    for (auto* profile : std::as_const(m_profiles)) {
        profile->deleteLater();
    }
    m_profiles.clear();
    m_byPath.clear();
}

void NetworkProfiles::scheduleRefresh() {
    if (m_refreshing) {
        m_refreshQueued = true;
        return;
    }

    m_refreshing = true;
    QTimer::singleShot(0, this, [this]() {
        refresh();
    });
}

void NetworkProfiles::refresh() {
    m_seen.clear();
    m_listChanged = false;
    m_pending = 0;

    readSettings();
}

// Each async read holds a reference; the result is published when the last one
// lands, so a partial walk is never visible.
void NetworkProfiles::step(int delta) {
    m_pending += delta;
    if (m_pending > 0) {
        return;
    }

    finish();
}

void NetworkProfiles::finish() {
    // Anything not seen by this walk is gone.
    for (int i = m_profiles.size() - 1; i >= 0; i--) {
        auto* profile = m_profiles.at(i);
        if (!m_seen.contains(profile->path())) {
            m_byPath.remove(profile->path());
            m_profiles.removeAt(i);
            profile->deleteLater();
            m_listChanged = true;
        }
    }

    const bool wasReady = m_ready;
    m_ready = true;

    if (m_listChanged) {
        emit profilesChanged();
    }
    if (!wasReady || m_listChanged) {
        emit changed();
    }

    m_refreshing = false;
    if (m_refreshQueued) {
        m_refreshQueued = false;
        scheduleRefresh();
    }
}

void NetworkProfiles::readSettings() {
    auto bus = systemBus();
    if (!bus) {
        finish();
        return;
    }

    auto msg = QDBusMessage::createMethodCall(
        QString::fromUtf8(kService),
        QString::fromUtf8(kSettingsPath),
        QString::fromUtf8(kPropsIface),
        QStringLiteral("GetAll"));
    msg << QString::fromUtf8(kSettingsIface);

    step(1);
    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher* call) {
        call->deleteLater();

        const QDBusPendingReply<QVariantMap> reply = *call;
        if (reply.isError()) {
            qCWarning(logNetworkProfiles) << "Failed to read settings properties:" << reply.error().message();
            step(-1);
            return;
        }

        const auto connections = reply.value().value(QStringLiteral("Connections")).value<QDBusArgument>();
        QList<QDBusObjectPath> paths;
        connections >> paths;

        for (const auto& path : paths) {
            readProfile(path.path());
        }

        step(-1);
    });
}

void NetworkProfiles::readProfile(const QString& path) {
    auto bus = systemBus();
    if (!bus) {
        return;
    }

    auto msg = QDBusMessage::createMethodCall(
        QString::fromUtf8(kService), path, QString::fromUtf8(kConnectionIface), QStringLiteral("GetSettings"));

    step(1);
    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, path](QDBusPendingCallWatcher* call) {
        call->deleteLater();

        const QDBusPendingReply<QMap<QString, QVariantMap>> reply = *call;
        if (reply.isError()) {
            // Profiles get deleted while a walk is in flight; that's expected.
            qCDebug(logNetworkProfiles) << "Skipping profile" << path << ":" << reply.error().message();
            step(-1);
            return;
        }

        m_seen.insert(path);

        auto* profile = m_byPath.value(path);
        if (profile == nullptr) {
            profile = new NmConnection(path, this);
            profile->watch();
            // An edit only affects the one profile, so re-read it rather than
            // walking everything.
            connect(profile, &NmConnection::needsReread, this, [this, path]() {
                readProfile(path);
            });

            m_byPath.insert(path, profile);
            m_profiles.append(profile);
            m_listChanged = true;
        }

        profile->update(reply.value());

        step(-1);
    });
}

} // namespace caelestia::services
