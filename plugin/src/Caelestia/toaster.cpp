#include "toaster.hpp"

#include <qdebug.h>
#include <qlogging.h>
#include <qtimer.h>

namespace caelestia {

Toast::Toast(const QString& title, const QString& message, const QString& icon, Type type, int timeout, QObject* parent)
    : QObject(parent)
    , m_closed(false)
    , m_title(title)
    , m_message(message)
    , m_icon(icon)
    , m_type(type)
    , m_timeout(timeout) {
    QTimer::singleShot(timeout, this, &Toast::close);

    if (m_icon.isEmpty()) {
        switch (m_type) {
        case Type::Success:
            m_icon = "check_circle_unread";
            break;
        case Type::Warning:
            m_icon = "warning";
            break;
        case Type::Error:
            m_icon = "error";
            break;
        default:
            m_icon = "info";
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

QQmlListProperty<Toast> Toaster::toasts() {
    return QQmlListProperty<Toast>(this, &m_toasts);
}

void Toaster::toast(const QString& title, const QString& message, const QString& icon, Toast::Type type, int timeout) {
    auto* toast = new Toast(title, message, icon, type, timeout, this);
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
