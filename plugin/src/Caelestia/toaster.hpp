#pragma once

#include <qjsengine.h>
#include <qjsvalue.h>
#include <qlist.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qqmlintegration.h>
#include <qqmllist.h>
#include <qset.h>
#include <qstring.h>
#include <qtmetamacros.h>

#include <functional>

namespace caelestia {

struct ToastAction {
    Q_GADGET
    QML_ANONYMOUS

    Q_PROPERTY(QString text MEMBER m_text CONSTANT)
    Q_PROPERTY(QString icon MEMBER m_icon CONSTANT)

public:
    using Callback = std::function<void()>;

    // 1. Default constructor required by Qt for Q_GADGET
    ToastAction() = default;

    // 2. C++ constructor (automatically leaves jsCallback empty)
    ToastAction(QString text, QString icon, Callback cb);

    // 3. QML constructor (automatically leaves callback empty)
    ToastAction(QString text, QString icon, QJSValue jsCb);

    QString m_text;
    QString m_icon;
    Callback m_callback;
    QJSValue m_jsCallback;

    Q_INVOKABLE void invoke() const;
};

class Toast : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Toast instances can only be retrieved from a Toaster")

    Q_PROPERTY(bool closed READ closed NOTIFY closedChanged)
    Q_PROPERTY(QString title READ title CONSTANT)
    Q_PROPERTY(QString message READ message CONSTANT)
    Q_PROPERTY(QString icon READ icon CONSTANT)
    Q_PROPERTY(int timeout READ timeout CONSTANT)
    Q_PROPERTY(Type type READ type CONSTANT)
    Q_PROPERTY(QList<caelestia::ToastAction> actions READ actions CONSTANT)

public:
    enum class Type : quint8 {
        Info = 0,
        Success,
        Warning,
        Error
    };
    Q_ENUM(Type)

    explicit Toast(QString title, QString message, QString icon, Type type, int timeout,
        QList<ToastAction> actions = {}, QObject* parent = nullptr);

    [[nodiscard]] bool closed() const;
    [[nodiscard]] QString title() const;
    [[nodiscard]] QString message() const;
    [[nodiscard]] QString icon() const;
    [[nodiscard]] int timeout() const;
    [[nodiscard]] Type type() const;
    [[nodiscard]] const QList<ToastAction>& actions() const;

    Q_INVOKABLE void close();
    Q_INVOKABLE void lock(QObject* sender);
    Q_INVOKABLE void unlock(QObject* sender);

signals:
    void closedChanged();
    void finishedClose();

private:
    QSet<QObject*> m_locks;

    bool m_closed;
    QString m_title;
    QString m_message;
    QString m_icon;
    Type m_type;
    int m_timeout;
    QList<ToastAction> m_actions;
};

class Toaster : public QObject {

    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QQmlListProperty<caelestia::Toast> toasts READ toasts NOTIFY toastsChanged)

public:
    static Toaster* instance();
    static Toaster* create(QQmlEngine* engine, QJSEngine* jsEngine);

    [[nodiscard]] QQmlListProperty<Toast> toasts();

    // qml entry point
    Q_INVOKABLE void toast(const QString& title, const QString& message, const QString& icon = QString(),
        const QJSValue& actionsOrType = QJSValue(), int timeout = 5000, const QJSValue& actions = QJSValue());

    // C++ entry point (with typed Toast::Type, timeout, and actions)
    void toast(const QString& title, const QString& message, const QString& icon, caelestia::Toast::Type type,
        int timeout = 5000, QList<caelestia::ToastAction> actions = {});

signals:
    void toastsChanged();

private:
    explicit Toaster(QObject* parent = nullptr);

    QList<Toast*> m_toasts;
};

} // namespace caelestia

Q_DECLARE_METATYPE(caelestia::ToastAction)
