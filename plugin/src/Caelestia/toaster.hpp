#pragma once

#include <qjsengine.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qqmlintegration.h>
#include <qqmllist.h>
#include <qset.h>

namespace caelestia {

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

public:
    enum class Type : quint8 {
        Info = 0,
        Success,
        Warning,
        Error
    };
    Q_ENUM(Type)

    explicit Toast(QString title, QString message, QString icon, Type type, int timeout, QObject* parent = nullptr);

    [[nodiscard]] bool closed() const;
    [[nodiscard]] QString title() const;
    [[nodiscard]] QString message() const;
    [[nodiscard]] QString icon() const;
    [[nodiscard]] int timeout() const;
    [[nodiscard]] Type type() const;

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

    Q_INVOKABLE void toast(const QString& title, const QString& message, const QString& icon = QString(),
        caelestia::Toast::Type type = Toast::Type::Info, int timeout = 5000);

signals:
    void toastsChanged();

private:
    explicit Toaster(QObject* parent = nullptr);

    QList<Toast*> m_toasts;
};

} // namespace caelestia
