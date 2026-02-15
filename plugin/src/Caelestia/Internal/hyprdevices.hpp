#pragma once

#include <qjsonobject.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qqmllist.h>

namespace caelestia::internal::hypr {

class HyprKeyboard : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("HyprKeyboard instances can only be retrieved from a HyprDevices")

    Q_PROPERTY(QVariantHash lastIpcObject READ lastIpcObject NOTIFY lastIpcObjectChanged)
    Q_PROPERTY(QString address READ address NOTIFY addressChanged)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(QString layout READ layout NOTIFY layoutChanged)
    Q_PROPERTY(QString activeKeymap READ activeKeymap NOTIFY activeKeymapChanged)
    Q_PROPERTY(bool capsLock READ capsLock NOTIFY capsLockChanged)
    Q_PROPERTY(bool numLock READ numLock NOTIFY numLockChanged)
    Q_PROPERTY(bool main READ main NOTIFY mainChanged)

public:
    explicit HyprKeyboard(QJsonObject ipcObject, QObject* parent = nullptr);

    [[nodiscard]] QVariantHash lastIpcObject() const;
    [[nodiscard]] QString address() const;
    [[nodiscard]] QString name() const;
    [[nodiscard]] QString layout() const;
    [[nodiscard]] QString activeKeymap() const;
    [[nodiscard]] bool capsLock() const;
    [[nodiscard]] bool numLock() const;
    [[nodiscard]] bool main() const;

    bool updateLastIpcObject(QJsonObject object);

signals:
    void lastIpcObjectChanged();
    void addressChanged();
    void nameChanged();
    void layoutChanged();
    void activeKeymapChanged();
    void capsLockChanged();
    void numLockChanged();
    void mainChanged();

private:
    QJsonObject m_lastIpcObject;
};

class HyprDevices : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("HyprDevices instances can only be retrieved from a HyprExtras")

    Q_PROPERTY(
        QQmlListProperty<caelestia::internal::hypr::HyprKeyboard> keyboards READ keyboards NOTIFY keyboardsChanged)

public:
    explicit HyprDevices(QObject* parent = nullptr);

    [[nodiscard]] QQmlListProperty<HyprKeyboard> keyboards();

    bool updateLastIpcObject(QJsonObject object);

signals:
    void keyboardsChanged();

private:
    QList<HyprKeyboard*> m_keyboards;
};

} // namespace caelestia::internal::hypr
