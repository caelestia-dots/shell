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

constexpr const char* k_service = "org.freedesktop.NetworkManager";
constexpr const char* k_settingsPath = "/org/freedesktop/NetworkManager/Settings";
constexpr const char* k_settingsIface = "org.freedesktop.NetworkManager.Settings";
constexpr const char* k_connectionIface = "org.freedesktop.NetworkManager.Settings.Connection";
constexpr const char* k_propsIface = "org.freedesktop.DBus.Properties";

// Setting group names, as NetworkManager keys them in GetSettings.
constexpr const char* k_groupConnection = "connection";
constexpr const char* k_groupWireless = "802-11-wireless";
constexpr const char* k_groupWirelessSecurity = "802-11-wireless-security";
constexpr const char* k_groupIpv4 = "ipv4";

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

// The legacy ipv4.dns is an array of in_addr values, i.e. already in network
// byte order, so the low byte is the first octet. NetworkManager publishes
// dns-data alongside it as plain strings and prefers that; this is only for
// older daemons that send the packed form.
QStringList packedDnsToStrings(const QVariant& value) {
    if (!value.canConvert<QDBusArgument>()) {
        return {};
    }

    QList<uint> packed;
    value.value<QDBusArgument>() >> packed;

    QStringList dns;
    dns.reserve(packed.size());
    for (const auto address : std::as_const(packed)) {
        dns.append(QStringLiteral("%1.%2.%3.%4")
                .arg(address & 0xff)
                .arg((address >> 8) & 0xff)
                .arg((address >> 16) & 0xff)
                .arg((address >> 24) & 0xff));
    }
    return dns;
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

QString NmConnection::ipv4Method() const {
    return m_ipv4Method;
}

QString NmConnection::ipv4Address() const {
    return m_ipv4Address;
}

QString NmConnection::ipv4Gateway() const {
    return m_ipv4Gateway;
}

QStringList NmConnection::ipv4Dns() const {
    return m_ipv4Dns;
}

bool NmConnection::ipv4IgnoreAutoDns() const {
    return m_ipv4IgnoreAutoDns;
}

void NmConnection::update(const QMap<QString, QVariantMap>& settings) {
    const auto connection = settings.value(QString::fromUtf8(k_groupConnection));
    const auto wireless = settings.value(QString::fromUtf8(k_groupWireless));
    const auto security = settings.value(QString::fromUtf8(k_groupWirelessSecurity));
    const auto ipv4 = settings.value(QString::fromUtf8(k_groupIpv4));

    const auto id = connection.value(QStringLiteral("id")).toString();
    const auto uuid = connection.value(QStringLiteral("uuid")).toString();
    const auto type = connection.value(QStringLiteral("type")).toString();
    const auto ssid = byteArrayToString(wireless.value(QStringLiteral("ssid")));
    const auto keyMgmt = security.value(QStringLiteral("key-mgmt")).toString();

    // NetworkManager leaves autoconnect out when it's at its default, which is
    // on, so a missing key is not false.
    const auto autoconnectValue = connection.find(QStringLiteral("autoconnect"));
    const auto autoconnect = autoconnectValue == connection.end() ? true : autoconnectValue.value().toBool();

    const auto ipv4Method = ipv4.value(QStringLiteral("method")).toString();
    const auto ipv4Gateway = ipv4.value(QStringLiteral("gateway")).toString();
    const auto ipv4IgnoreAutoDns = ipv4.value(QStringLiteral("ignore-auto-dns")).toBool();

    QList<QVariantMap> addresses;
    ipv4.value(QStringLiteral("address-data")).value<QDBusArgument>() >> addresses;

    QString ipv4Address;
    if (!addresses.isEmpty()) {
        ipv4Address = QStringLiteral("%1/%2")
                          .arg(addresses.first().value(QStringLiteral("address")).toString())
                          .arg(addresses.first().value(QStringLiteral("prefix")).toInt());
    }

    // dns-data is what NetworkManager publishes now; dns is the deprecated
    // packed form, still sent by older daemons.
    const auto dnsData = ipv4.find(QStringLiteral("dns-data"));
    const auto ipv4Dns =
        dnsData == ipv4.end() ? packedDnsToStrings(ipv4.value(QStringLiteral("dns"))) : dnsData.value().toStringList();

    if (id == m_id && uuid == m_uuid && type == m_type && ssid == m_ssid && keyMgmt == m_keyMgmt &&
        autoconnect == m_autoconnect && ipv4Method == m_ipv4Method && ipv4Address == m_ipv4Address &&
        ipv4Gateway == m_ipv4Gateway && ipv4Dns == m_ipv4Dns && ipv4IgnoreAutoDns == m_ipv4IgnoreAutoDns) {
        return;
    }

    m_id = id;
    m_uuid = uuid;
    m_type = type;
    m_ssid = ssid;
    m_keyMgmt = keyMgmt;
    m_autoconnect = autoconnect;
    m_ipv4Method = ipv4Method;
    m_ipv4Address = ipv4Address;
    m_ipv4Gateway = ipv4Gateway;
    m_ipv4Dns = ipv4Dns;
    m_ipv4IgnoreAutoDns = ipv4IgnoreAutoDns;

    emit changed();
}

void NmConnection::watch() {
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        return;
    }

    bus.connect(QString::fromUtf8(k_service), m_path, QString::fromUtf8(k_connectionIface), QStringLiteral("Updated"),
        this, SLOT(handleUpdated()));
}

void NmConnection::handleUpdated() {
    emit needsReread();
}

NetworkProfiles::NetworkProfiles(QObject* parent)
    : NmWalker(QString::fromUtf8(k_settingsPath), parent) {
    // GetSettings returns a{sa{sv}}, which needs registering before QtDBus will
    // demarshal it into a nested map.
    qDBusRegisterMetaType<QMap<QString, QVariantMap>>();
}

// Profiles re-read themselves when edited, so this only needs to catch
// profiles being added or removed.
bool NetworkProfiles::triggersRefresh(const QString& iface) const {
    return iface == QString::fromUtf8(k_settingsIface);
}

void NetworkProfiles::clearItems() {
    for (auto* profile : std::as_const(m_profiles)) {
        profile->deleteLater();
    }
    m_profiles.clear();
    m_byPath.clear();
}

// Anything not seen by this walk is gone.
void NetworkProfiles::pruneUnseen() {
    for (qsizetype i = m_profiles.size() - 1; i >= 0; i--) {
        auto* profile = m_profiles.at(i);
        if (!seen().contains(profile->path())) {
            m_byPath.remove(profile->path());
            m_profiles.removeAt(i);
            profile->deleteLater();
            setListChanged();
        }
    }
}

QQmlListProperty<NmConnection> NetworkProfiles::profiles() {
    return { this, &m_profiles };
}

void NetworkProfiles::readRoot() {
    auto bus = systemBus();
    if (!bus) {
        abandonWalk();
        return;
    }

    auto msg = QDBusMessage::createMethodCall(QString::fromUtf8(k_service), QString::fromUtf8(k_settingsPath),
        QString::fromUtf8(k_propsIface), QStringLiteral("GetAll"));
    msg << QString::fromUtf8(k_settingsIface);

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

        for (const auto& path : std::as_const(paths)) {
            readProfile(path.path(), Read::Walk);
        }

        step(-1);
    });
    // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks) watcher is parented and self-deletes
}

void NetworkProfiles::readProfile(const QString& path, Read read) {
    auto bus = systemBus();
    if (!bus) {
        return;
    }

    auto msg = QDBusMessage::createMethodCall(
        QString::fromUtf8(k_service), path, QString::fromUtf8(k_connectionIface), QStringLiteral("GetSettings"));

    const auto walk = read == Read::Walk;
    if (walk) {
        step(1);
    }

    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, path, walk](QDBusPendingCallWatcher* call) {
        call->deleteLater();

        const QDBusPendingReply<QMap<QString, QVariantMap>> reply = *call;
        if (reply.isError()) {
            // Profiles get deleted while a read is in flight; that's expected.
            qCDebug(logNetworkProfiles) << "Skipping profile" << path << ":" << reply.error().message();
            if (walk) {
                step(-1);
            }
            return;
        }

        auto* profile = m_byPath.value(path);

        if (!walk) {
            // A reread only refreshes what's already held. If the profile has
            // gone, the walk that noticed will deal with it.
            if (profile != nullptr) {
                profile->update(reply.value());
            }
            return;
        }

        seen().insert(path);

        if (profile == nullptr) {
            profile = new NmConnection(path, this);
            profile->watch();
            // An edit only affects the one profile, so re-read that one rather
            // than walking everything.
            connect(profile, &NmConnection::needsReread, this, [this, path]() {
                readProfile(path, Read::Detached);
            });

            m_byPath.insert(path, profile);
            m_profiles.append(profile);
            setListChanged();
        }

        profile->update(reply.value());

        step(-1);
    });
    // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks) watcher is parented and self-deletes
}

} // namespace caelestia::services
