#pragma once

#include <qhash.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qsocketnotifier.h>
#include <qstring.h>
#include <qtmetamacros.h>

#include "../toaster.hpp"

struct udev;
struct udev_monitor;
struct udev_device;

namespace caelestia::services {

class UdevService : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit UdevService(QObject* parent = nullptr);
    ~UdevService() override;

    static UdevService* instance();
    static UdevService* create(QQmlEngine* engine, QJSEngine* jsEngine);

    Q_INVOKABLE static void mount(const QString& devName);
    Q_INVOKABLE static void unmount(const QString& devName);
    Q_INVOKABLE static void open(const QString& devName);

private:
    void init();
    void updateEnabledState();
    void handleBlockDevice(struct udev_device* dev, std::string_view action);
    void handleStorageAdd(struct udev_device* dev);
    void handleStorageRemove(struct udev_device* dev);
    void handleInputDevice(struct udev_device* dev, std::string_view action);
    [[nodiscard]] static QString mountDevice(const QString& devName);

private slots:
    void onSocketActivated();

private:
    struct udev* m_udev = nullptr;
    struct udev_monitor* m_monitor = nullptr;
    QSocketNotifier* m_notifier = nullptr;

    QHash<QString, QString> m_connectedDrives;
    bool m_controllerDebounce = false;
};

} // namespace caelestia::services
