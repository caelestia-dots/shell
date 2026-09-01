#include "toaster.hpp"

#include <qjsvalue.h>
#include <qlist.h>
#include <qlogging.h>
#include <qtimer.h>

#include <utility>

namespace caelestia {

using Qt::StringLiterals::operator""_s;

ToastAction::ToastAction(QString text, QString icon, Callback cb)
    : m_text(std::move(text))
    , m_icon(std::move(icon))
    , m_callback(std::move(cb)) {}

ToastAction::ToastAction(QString text, QString icon, QJSValue jsCb)
    : m_text(std::move(text))
    , m_icon(std::move(icon))
    , m_jsCallback(std::move(jsCb)) {}

void ToastAction::invoke() const {
    if (m_callback) {
        m_callback();
    }
    if (m_jsCallback.isCallable()) {
        m_jsCallback.call();
    }
}

Toast::Toast(
    QString title, QString message, QString icon, Type type, int timeout, QList<ToastAction> actions, QObject* parent)
    : QObject(parent)
    , m_closed(false)
    , m_title(std::move(title))
    , m_message(std::move(message))
    , m_icon(std::move(icon))
    , m_type(type)
    , m_timeout(timeout)
    , m_actions(std::move(actions)) {
    QTimer::singleShot(timeout, this, &Toast::close);

    if (m_icon.isEmpty()) {
        switch (m_type) {
        case Type::Success:
            m_icon = u"check_circle_unread"_s;
            break;
        case Type::Warning:
            m_icon = u"warning"_s;
            break;
        case Type::Error:
            m_icon = u"error"_s;
            break;
        default:
            m_icon = u"info"_s;
            break;
        }
    }

    if (timeout <= 0) {
        switch (m_type) {
        case Type::Warning:
            m_timeout = 7000;
            break;
        case Type::Error:
            m_timeout = 10000;
            break;
        default:
            m_timeout = 5000;
            break;
        }
    }
}

bool Toast::closed() const {
    return m_closed;
}

QString Toast::title() const {
    return m_title;
}

QString Toast::message() const {
    return m_message;
}

QString Toast::icon() const {
    return m_icon;
}

int Toast::timeout() const {
    return m_timeout;
}

Toast::Type Toast::type() const {
    return m_type;
}

const QList<ToastAction>& Toast::actions() const {
    return m_actions;
}

void Toast::close() {
    if (!m_closed) {
        m_closed = true;
        emit closedChanged();
    }

    if (m_locks.isEmpty()) {
        emit finishedClose();
    }
}

void Toast::lock(QObject* sender) {
    m_locks << sender;
    QObject::connect(sender, &QObject::destroyed, this, &Toast::unlock);
}

void Toast::unlock(QObject* sender) {
    if (m_locks.remove(sender) && m_closed) {
        close();
    }
}

Toaster::Toaster(QObject* parent)
    : QObject(parent) {}

Toaster* Toaster::instance() {
    static Toaster s_instance;
    return &s_instance;
}

Toaster* Toaster::create(QQmlEngine* engine, QJSEngine* jsEngine) {
    Q_UNUSED(engine);
    Q_UNUSED(jsEngine);

    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

QQmlListProperty<Toast> Toaster::toasts() {
    return { this, &m_toasts };
}

// qml entry point
void Toaster::toast(const QString& title, const QString& message, const QString& icon, const QJSValue& actionsOrType,
    int timeout, const QJSValue& actions) {
    Toast::Type type = Toast::Type::Info;
    QJSValue rawActions = actions;

    if (actionsOrType.isArray()) {
        rawActions = actionsOrType;
    } else if (actionsOrType.isNumber()) {
        type = static_cast<Toast::Type>(actionsOrType.toInt());
    }

    QList<ToastAction> actionList;
    if (rawActions.isArray()) {
        const quint32 length = rawActions.property(u"length"_s).toUInt();
        actionList.reserve(length);

        for (quint32 i = 0; i < length; ++i) {
            const QJSValue item = rawActions.property(i);
            actionList.append(ToastAction(item.property(u"text"_s).toString(), item.property(u"icon"_s).toString(),
                item.property(u"callback"_s)));
        }
    }

    toast(title, message, icon, type, timeout, std::move(actionList));
}

// c++ entry point
void Toaster::toast(const QString& title, const QString& message, const QString& icon, Toast::Type type, int timeout,
    QList<ToastAction> actions) {
    auto* const toast = new Toast(title, message, icon, type, timeout, std::move(actions), this);
    QObject::connect(toast, &Toast::finishedClose, this, [toast, this]() {
        if (m_toasts.removeOne(toast)) {
            emit toastsChanged();
            toast->deleteLater();
        }
    });
    m_toasts.push_front(toast);
    emit toastsChanged();
}

} // namespace caelestia
