#pragma once

#include <qhash.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qsocketnotifier.h>
#include <qtimer.h>

namespace caelestia::shell::services {

class GamepadActivity : public QObject {
    Q_OBJECT
    QML_ELEMENT

public:
    explicit GamepadActivity(QObject* parent = nullptr);
    ~GamepadActivity() override;

signals:
    void activity();

private:
    struct Device {
        int fd;
        QSocketNotifier* notifier;
        QHash<unsigned char, int> axes;
    };

    QHash<QString, Device> m_devices;
    QTimer m_scanTimer;

    void scan();
    void readEvents(const QString& path);
    void removeDevice(const QString& path);
};

} // namespace caelestia::shell::services
