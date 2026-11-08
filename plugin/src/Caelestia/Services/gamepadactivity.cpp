#include "gamepadactivity.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>

#include <fcntl.h>
#include <linux/joystick.h>
#include <unistd.h>

#include <cerrno>
#include <cstdlib>

namespace caelestia::shell::services {

GamepadActivity::GamepadActivity(QObject* parent)
    : QObject(parent) {
    m_scanTimer.setInterval(1000);
    connect(&m_scanTimer, &QTimer::timeout, this, &GamepadActivity::scan);
    m_scanTimer.start();
    scan();
}

GamepadActivity::~GamepadActivity() {
    const auto paths = m_devices.keys();
    for (const auto& path : paths)
        removeDevice(path);
}

void GamepadActivity::scan() {
    const QDir directory(QStringLiteral("/dev/input"));
    const auto entries = directory.entryList({ QStringLiteral("js*") }, QDir::System | QDir::Files);
    const auto paths = m_devices.keys();
    for (const auto& path : paths) {
        if (!entries.contains(QFileInfo(path).fileName()))
            removeDevice(path);
    }
    for (const auto& entry : entries) {
        const auto path = directory.absoluteFilePath(entry);
        if (m_devices.contains(path))
            continue;
        const int fd = ::open(QFile::encodeName(path).constData(), O_RDONLY | O_NONBLOCK | O_CLOEXEC);
        if (fd < 0)
            continue;
        auto* notifier = new QSocketNotifier(fd, QSocketNotifier::Read, this);
        m_devices.insert(path, { fd, notifier, {} });
        connect(notifier, &QSocketNotifier::activated, this, [this, path] {
            readEvents(path);
        });
    }
}

void GamepadActivity::removeDevice(const QString& path) {
    const auto device = m_devices.take(path);
    device.notifier->setEnabled(false);
    device.notifier->deleteLater();
    ::close(device.fd);
}

void GamepadActivity::readEvents(const QString& path) {
    auto& device = m_devices[path];
    bool active = false;
    js_event event{};
    ssize_t count = 0;
    while ((count = ::read(device.fd, &event, sizeof(event))) == sizeof(event)) {
        if ((event.type & JS_EVENT_INIT) != 0) {
            if ((event.type & JS_EVENT_AXIS) != 0)
                device.axes.insert(event.number, event.value);
            continue;
        }
        if (event.type == JS_EVENT_BUTTON) {
            active = true;
        } else if (event.type == JS_EVENT_AXIS) {
            const int previous = device.axes.value(event.number, event.value);
            if (std::abs(event.value - previous) >= 4000) {
                active = true;
                device.axes.insert(event.number, event.value);
            }
        }
    }
    if (count == 0 || (count < 0 && errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR))
        removeDevice(path);
    if (active)
        emit activity();
}

} // namespace caelestia::shell::services
