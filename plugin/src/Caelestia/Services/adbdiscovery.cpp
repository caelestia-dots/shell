#include "adbdiscovery.hpp"

#include <qbytearray.h>
#include <qnetworkdatagram.h>

#include <optional>

namespace caelestia::services {

using Qt::StringLiterals::operator""_s;

namespace {

// 224.0.0.251, the mDNS multicast group
constexpr quint32 k_group = 0xE00000FB;
constexpr quint16 k_port = 5353;
constexpr int k_queryIntervalMs = 3000;
// Services not seen for this long are dropped, e.g. once pairing is closed on the phone
constexpr qint64 k_expiryMs = 10000;
constexpr int k_maxPointerJumps = 16;

constexpr quint16 k_typeA = 1;
constexpr quint16 k_typePtr = 12;
constexpr quint16 k_typeSrv = 33;
// Class IN with the top bit asking for a direct reply
constexpr quint16 k_classInUnicast = 0x8001;

const QString k_connectType = u"_adb-tls-connect._tcp.local"_s;
const QString k_pairingType = u"_adb-tls-pairing._tcp.local"_s;

quint16 readUint16(const QByteArray& data, qsizetype offset) {
    return static_cast<quint16>((static_cast<quint8>(data.at(offset)) << 8) | static_cast<quint8>(data.at(offset + 1)));
}

quint32 readUint32(const QByteArray& data, qsizetype offset) {
    return (static_cast<quint32>(readUint16(data, offset)) << 16) | readUint16(data, offset + 2);
}

// Reads a possibly compressed name, returning it and the offset after it
std::optional<std::pair<QString, qsizetype>> readName(const QByteArray& data, qsizetype offset) {
    QStringList labels;
    qsizetype end = -1;

    for (int jumps = 0; jumps <= k_maxPointerJumps;) {
        if (offset >= data.size())
            return std::nullopt;

        const auto length = static_cast<quint8>(data.at(offset));

        if ((length & 0xC0) == 0xC0) {
            if (offset + 1 >= data.size())
                return std::nullopt;
            if (end < 0)
                end = offset + 2;
            offset = ((length & 0x3F) << 8) | static_cast<quint8>(data.at(offset + 1));
            ++jumps;
            continue;
        }

        if (length == 0)
            return std::pair{ labels.join(u'.'), end < 0 ? offset + 1 : end };

        if (offset + 1 + length > data.size())
            return std::nullopt;

        labels << QString::fromUtf8(data.mid(offset + 1, length));
        offset += 1 + length;
    }

    return std::nullopt;
}

// The service kind of a type name, or of an instance name ending in the type
QString kindOf(const QString& name, bool instance) {
    const auto matches = [&](const QString& type) {
        return instance ? name.endsWith(u'.' + type) : name == type;
    };

    if (matches(k_connectType))
        return u"connect"_s;
    if (matches(k_pairingType))
        return u"pairing"_s;
    return {};
}

QByteArray encodeName(const QString& name) {
    QByteArray result;
    const auto labels = name.split(u'.');
    for (const auto& label : labels) {
        const auto bytes = label.toUtf8();
        result.append(static_cast<char>(bytes.size()));
        result.append(bytes);
    }
    result.append('\0');
    return result;
}

void appendUint16(QByteArray& data, quint16 value) {
    data.append(static_cast<char>(value >> 8));
    data.append(static_cast<char>(value & 0xFF));
}

} // namespace

AdbDiscovery::AdbDiscovery(QObject* parent)
    : QObject(parent) {
    m_queryTimer.setInterval(k_queryIntervalMs);
    connect(&m_queryTimer, &QTimer::timeout, this, &AdbDiscovery::query);
    connect(&m_socket, &QUdpSocket::readyRead, this, &AdbDiscovery::readDatagrams);
}

bool AdbDiscovery::active() const {
    return m_active;
}

void AdbDiscovery::setActive(bool active) {
    if (m_active == active)
        return;

    m_active = active;
    emit activeChanged();

    if (active) {
        bind();
        query();
        m_queryTimer.start();
    } else {
        m_queryTimer.stop();
        m_socket.close();
        m_bound = false;
        m_instances.clear();
        m_hosts.clear();
        publish();
    }
}

QVariantList AdbDiscovery::services() const {
    return m_services;
}

void AdbDiscovery::bind() {
    if (m_bound)
        return;

    // Share the port with avahi or other responders. If that is not possible, a
    // random port still gets the direct replies the queries ask for.
    if (m_socket.bind(QHostAddress::AnyIPv4, k_port, QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint))
        m_socket.joinMulticastGroup(QHostAddress(k_group));
    else
        m_socket.bind(QHostAddress::AnyIPv4, 0);

    m_bound = true;
}

void AdbDiscovery::query() {
    if (!m_active)
        return;

    QByteArray packet;
    appendUint16(packet, 0); // id
    appendUint16(packet, 0); // flags
    appendUint16(packet, 2); // questions
    appendUint16(packet, 0);
    appendUint16(packet, 0);
    appendUint16(packet, 0);

    for (const auto& type : { k_connectType, k_pairingType }) {
        packet.append(encodeName(type));
        appendUint16(packet, k_typePtr);
        appendUint16(packet, k_classInUnicast);
    }

    m_socket.writeDatagram(packet, QHostAddress(k_group), k_port);
    publish();
}

void AdbDiscovery::readDatagrams() {
    bool changed = false;

    while (m_socket.hasPendingDatagrams()) {
        const auto datagram = m_socket.receiveDatagram();
        const auto before = m_instances.size();
        parse(datagram.data(), datagram.senderAddress());
        changed = changed || m_instances.size() != before || !m_instances.isEmpty();
    }

    if (changed)
        publish();
}

void AdbDiscovery::parse(const QByteArray& data, const QHostAddress& sender) {
    // Only responses, which also skips our own queries coming back
    if (data.size() < 12 || (readUint16(data, 2) & 0x8000) == 0)
        return;

    const int questions = readUint16(data, 4);
    const int records = readUint16(data, 6) + readUint16(data, 8) + readUint16(data, 10);
    qsizetype offset = 12;

    for (int i = 0; i < questions; ++i) {
        const auto name = readName(data, offset);
        if (!name)
            return;
        offset = name->second + 4;
    }

    const auto now = QDateTime::currentDateTimeUtc();

    for (int i = 0; i < records; ++i) {
        const auto name = readName(data, offset);
        if (!name || name->second + 10 > data.size())
            return;

        const Record record{
            .name = name->first,
            .type = readUint16(data, name->second),
            .ttl = readUint32(data, name->second + 4),
            .offset = name->second + 10,
            .length = readUint16(data, name->second + 8),
        };

        offset = record.offset + record.length;
        if (offset > data.size())
            return;

        if (record.type == k_typePtr)
            handlePtr(data, record, sender, now);
        else if (record.type == k_typeSrv)
            handleSrv(data, record, sender, now);
        else if (record.type == k_typeA && record.length == 4)
            m_hosts.insert(record.name, QHostAddress(readUint32(data, record.offset)));
    }
}

void AdbDiscovery::handlePtr(
    const QByteArray& data, const Record& record, const QHostAddress& sender, const QDateTime& now) {
    const auto kind = kindOf(record.name, false);
    const auto instance = readName(data, record.offset);
    if (kind.isEmpty() || !instance)
        return;

    // A TTL of 0 means the service went away
    if (record.ttl == 0) {
        m_instances.remove(instance->first);
        return;
    }

    auto& entry = m_instances[instance->first];
    entry.kind = kind;
    entry.sender = sender;
    entry.seen = now;
}

void AdbDiscovery::handleSrv(
    const QByteArray& data, const Record& record, const QHostAddress& sender, const QDateTime& now) {
    const auto kind = kindOf(record.name, true);
    if (kind.isEmpty() || record.length < 7)
        return;

    const auto target = readName(data, record.offset + 6);
    if (!target)
        return;

    if (record.ttl == 0) {
        m_instances.remove(record.name);
        return;
    }

    auto& entry = m_instances[record.name];
    entry.kind = kind;
    entry.port = readUint16(data, record.offset + 4);
    entry.target = target->first;
    entry.sender = sender;
    entry.seen = now;
}

void AdbDiscovery::publish() {
    const auto now = QDateTime::currentDateTimeUtc();
    QVariantList services;

    m_instances.removeIf([&now](const QHash<QString, Instance>::iterator& it) {
        return it->seen.msecsTo(now) > k_expiryMs;
    });

    for (auto it = m_instances.cbegin(); it != m_instances.cend(); ++it) {
        // The port is only known once the SRV record arrived
        if (it->port != 0) {
            // Prefer the advertised address, falling back to where the reply came from
            const auto address = m_hosts.value(it->target, it->sender);
            const auto suffix = it->kind == u"connect"_s ? k_connectType : k_pairingType;

            services << QVariantMap{
                { u"name"_s, it.key().chopped(suffix.size() + 1) },
                { u"kind"_s, it->kind },
                { u"address"_s, QHostAddress(address.toIPv4Address()).toString() },
                { u"port"_s, it->port },
            };
        }
    }

    if (services != m_services) {
        m_services = services;
        emit servicesChanged();
    }
}

} // namespace caelestia::services
