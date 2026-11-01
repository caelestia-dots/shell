#include "hyprextras.hpp"

#include <qdir.h>
#include <qjsonarray.h>
#include <qlocalsocket.h>
#include <qloggingcategory.h>
#include <qtimer.h>
#include <qvariant.h>

#include <memory>

#include "hyprdevices.hpp"

namespace {

Q_LOGGING_CATEGORY(lcHypr, "caelestia.services.hypr", QtInfoMsg)

} // namespace

namespace caelestia::services::hypr {

using Qt::StringLiterals::operator""_s;

HyprExtras::HyprExtras(QObject* parent)
    : QObject(parent)
    , m_socket(nullptr)
    , m_socketValid(false)
    , m_devices(new HyprDevices(this)) {
    const auto his = qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE");
    if (his.isEmpty()) {
        qCWarning(lcHypr) << "$HYPRLAND_INSTANCE_SIGNATURE is unset. Unable to connect to Hyprland socket.";
        return;
    }

    auto hyprDir = u"%1/hypr/%2"_s.arg(qEnvironmentVariable("XDG_RUNTIME_DIR"), his);
    if (!QDir(hyprDir).exists()) {
        hyprDir = u"/tmp/hypr/"_s + his;

        if (!QDir(hyprDir).exists()) {
            qCWarning(lcHypr) << "Hyprland socket directory does not exist. Unable to connect to Hyprland socket.";
            return;
        }
    }

    m_requestSocket = hyprDir + u"/.socket.sock"_s;
    m_eventSocket = hyprDir + u"/.socket2.sock"_s;

    refreshOptions();
    refreshDevices();

    m_socket = new QLocalSocket(this);

    QObject::connect(m_socket, &QLocalSocket::errorOccurred, this, &HyprExtras::socketError);
    QObject::connect(m_socket, &QLocalSocket::stateChanged, this, &HyprExtras::socketStateChanged);
    QObject::connect(m_socket, &QLocalSocket::readyRead, this, &HyprExtras::readEvent);

    m_socket->connectToServer(m_eventSocket, QLocalSocket::ReadOnly);
}

QVariantHash HyprExtras::options() const {
    return m_options;
}

HyprDevices* HyprExtras::devices() const {
    return m_devices;
}

void HyprExtras::message(const QString& message) {
    if (message.isEmpty()) {
        return;
    }

    makeRequest(message, [](bool success, const QByteArray& res) {
        if (!success) {
            qCWarning(lcHypr) << "message: request error:" << QString::fromUtf8(res);
        }
    });
}

void HyprExtras::batchMessage(const QStringList& messages) {
    if (messages.isEmpty()) {
        return;
    }

    makeRequest(u"[[BATCH]]"_s + messages.join(u";"_s), [](bool success, const QByteArray& res) {
        if (!success) {
            qCWarning(lcHypr) << "batchMessage: request error:" << QString::fromUtf8(res);
        }
    });
}

void HyprExtras::applyOptions(const QVariantHash& options) {
    if (options.isEmpty()) {
        return;
    }

    QString request;
    request.reserve(12 + options.size() * 40);
    request += u"[[BATCH]]"_s;
    for (auto it = options.constBegin(); it != options.constEnd(); ++it) {
        if (!m_usingLua) {
            request += u"keyword "_s + it.key() + u' ' + it.value().toString() + u';';
        } else {
            auto const parts = it.key().split(u':');
            request += u"eval hl.config({ "_s + parts.join(u" = { "_s) + u" = "_s + it.value().toString() +
                       u" }"_s.repeated(parts.size() - 1) + u" });"_s;
        }
    }

    makeRequest(request, [this](bool success, const QByteArray& res) {
        if (success) {
            refreshOptions();
        } else {
            qCWarning(lcHypr) << "applyOptions: request error" << QString::fromUtf8(res);
        }
    });
}

void HyprExtras::refreshOptions() {
    if (!m_optionsRefresh.isNull()) {
        // Abort the previous request without running its callback
        m_optionsRefresh->disconnect();
        m_optionsRefresh->close();
    }

    m_optionsRefresh = makeRequestJson(u"descriptions"_s, [this](bool success, const QJsonDocument& response) {
        m_optionsRefresh.reset();
        if (!success) {
            return;
        }

        const auto options = response.array();
        bool dirty = false;

        for (const auto& o : std::as_const(options)) {
            const auto obj = o.toObject();
            // Older Hyprland: { value: <name>, data: { current } }; newer: { name, current }
            const auto data = obj.value(u"data"_s).toObject();
            const auto key =
                obj.contains(u"name"_s) ? obj.value(u"name"_s).toString() : obj.value(u"value"_s).toString();
            const auto value =
                (data.contains(u"current"_s) ? data.value(u"current"_s) : obj.value(u"current"_s)).toVariant();
            if (key.isEmpty())
                continue;
            if (m_options.value(key) != value) {
                dirty = true;
                m_options.insert(key, value);
            }
        }

        if (dirty) {
            emit optionsChanged();
        }
    });
}

void HyprExtras::refreshDevices() {
    if (!m_devicesRefresh.isNull()) {
        // Abort the previous request without running its callback
        m_devicesRefresh->disconnect();
        m_devicesRefresh->close();
    }

    m_devicesRefresh = makeRequestJson(u"devices"_s, [this](bool success, const QJsonDocument& response) {
        m_devicesRefresh.reset();
        if (success) {
            m_devices->updateLastIpcObject(response.object());
        }
    });
}

void HyprExtras::socketError(QLocalSocket::LocalSocketError error) const {
    if (!m_socketValid) {
        qCWarning(lcHypr) << "socketError: unable to connect to Hyprland event socket:" << error;
    } else {
        qCWarning(lcHypr) << "socketError: Hyprland event socket error:" << error;
    }
}

void HyprExtras::socketStateChanged(QLocalSocket::LocalSocketState state) {
    if (state == QLocalSocket::UnconnectedState && m_socketValid) {
        qCWarning(lcHypr) << "socketStateChanged: Hyprland event socket disconnected.";
    }

    m_socketValid = state == QLocalSocket::ConnectedState;
}

void HyprExtras::readEvent() {
    // Only consume complete lines, a partial event stays buffered until the rest arrives
    while (m_socket->canReadLine()) {
        auto rawEvent = m_socket->readLine();
        rawEvent.chop(1); // Remove trailing \n
        const auto sep = rawEvent.indexOf(">>");
        if (sep < 0) {
            qCWarning(lcHypr) << "readEvent: malformed event (no >> separator):" << rawEvent;
            continue;
        }
        handleEvent(QString::fromUtf8(QByteArrayView(rawEvent.data(), sep)));
    }
}

void HyprExtras::handleEvent(const QString& event) {
    if (event == u"configreloaded"_s) {
        refreshOptions();
    } else if (event == u"activelayout"_s) {
        refreshDevices();
    }
}

HyprExtras::SocketPtr HyprExtras::makeRequestJson(
    const QString& request, const std::function<void(bool, QJsonDocument)>& callback) {
    return makeRequest(u"j/"_s + request, [callback](bool success, const QByteArray& response) {
        const auto doc = QJsonDocument::fromJson(response);
        callback(success && !doc.isNull(), doc);
    });
}

HyprExtras::SocketPtr HyprExtras::makeRequest(
    const QString& request, const std::function<void(bool, QByteArray)>& callback) {
    if (m_requestSocket.isEmpty()) {
        return {};
    }

    // Owned only by the shared pointer (not also by a QObject parent, which could delete it a
    // second time on shutdown). deleteLater keeps it safe to drop the last reference while the
    // socket is emitting.
    auto socket = SocketPtr(new QLocalSocket(), &QObject::deleteLater);

    // Hyprland closes the connection once the whole reply is written. Large replies (e.g.
    // j/descriptions) arrive in several chunks, so collect everything until then.
    const auto response = std::make_shared<QByteArray>();
    const auto finished = std::make_shared<bool>(false);
    const auto finish = [this, socket, callback, response, finished](bool success) {
        if (*finished)
            return;
        *finished = true;
        response->append(socket->readAll());
        callback(success, success ? std::move(*response) : QByteArray());
        socket->close();
        // The handlers below keep the socket alive, drop them once it is done to break the
        // cycle. Deferred so the handler running this isn't destroyed mid-call.
        QTimer::singleShot(0, this, [socket] {
            socket->disconnect();
        });
    };

    QObject::connect(socket.data(), &QLocalSocket::connected, this, [socket, request] {
        socket->write(request.toUtf8());
        socket->flush();
    });

    QObject::connect(socket.data(), &QLocalSocket::readyRead, this, [socket, response] {
        response->append(socket->readAll());
    });

    QObject::connect(socket.data(), &QLocalSocket::disconnected, this, [finish] {
        finish(true);
    });

    QObject::connect(
        socket.data(), &QLocalSocket::errorOccurred, this, [finish, request](QLocalSocket::LocalSocketError err) {
            // The server closing the connection is how a reply ends, not a failure
            if (err == QLocalSocket::PeerClosedError) {
                finish(true);
                return;
            }

            qCWarning(lcHypr) << "makeRequest: error making request:" << err << "| request:" << request;
            finish(false);
        });

    socket->connectToServer(m_requestSocket);

    return socket;
}

} // namespace caelestia::services::hypr
