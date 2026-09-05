#include "udevservice.hpp"

#include <qdbusargument.h>
#include <qdbusconnection.h>
#include <qdbusinterface.h>
#include <qdbusmessage.h>
#include <qdbusreply.h>
#include <qfileinfo.h>
#include <qloggingcategory.h>
#include <qprocess.h>
#include <qsocketnotifier.h>
#include <qthread.h>
#include <qtimer.h>

#include <libudev.h>

#include <utility>

#include "config/rootnodes.hpp"

using Qt::StringLiterals::operator""_s;

namespace {

Q_LOGGING_CATEGORY(lcUdev, "caelestia.services.udev", QtInfoMsg)

constexpr std::string_view k_ignoredPrefixes[] = {
    "/dev/loop",
    "/dev/zram",
    "/dev/dm-",
    "/dev/md",
};

bool isValidDevice(const char* devNode) {
    if (!devNode)
        return false;

    const std::string_view node(devNode);
    return std::ranges::none_of(k_ignoredPrefixes, [&node](std::string_view prefix) {
        return node.starts_with(prefix);
    });
}

const char* getDeviceNode(struct udev_device* dev) {
    const char* devNode = udev_device_get_devnode(dev);
    if (!devNode) {
        devNode = udev_device_get_property_value(dev, "DEVNAME");
    }
    return devNode;
}

bool isRemovableDrive(struct udev_device* dev) {
    const char* devNode = getDeviceNode(dev);
    if (!isValidDevice(devNode))
        return false;

    const char* bus = udev_device_get_property_value(dev, "ID_BUS");
    const char* usage = udev_device_get_property_value(dev, "ID_FS_USAGE");
    const char* devType = udev_device_get_devtype(dev);

    const std::string_view busView = bus ? bus : "";
    const std::string_view usageView = usage ? usage : "";
    const std::string_view devTypeView = devType ? devType : "";

    const bool isExternal = (busView == "usb" || busView == "mmc");
    if (!isExternal)
        return false;

    if (devTypeView != "partition" && usageView != "filesystem")
        return false;

    return (usageView == "filesystem");
}

QString getDriveLabel(struct udev_device* dev) {
    // filesystem label
    const char* label = udev_device_get_property_value(dev, "ID_FS_LABEL");
    if (label && *label != '\0') {
        return QString::fromUtf8(label);
    }

    // hardware model
    const char* model = udev_device_get_property_value(dev, "ID_MODEL");
    if (model && *model != '\0') {
        return QString::fromUtf8(model).replace(u'_', u' ');
    }

    // fallback to device node
    const char* devNode = getDeviceNode(dev);
    if (devNode) {
        const QString nodeName = QFileInfo(QString::fromUtf8(devNode)).fileName();
        return u"USB Drive (%1)"_s.arg(nodeName);
    }

    return u"USB Drive"_s;
}

bool isController(struct udev_device* dev) {
    const char* devNode = udev_device_get_devnode(dev);
    if (!devNode)
        return false;

    const std::string_view node(devNode);
    if (!node.starts_with("/dev/input/js"))
        return false;

    // ignore motion sensors and touchpads on DualSense/DualShock/Switch controllers
    const char* name = udev_device_get_property_value(dev, "NAME");
    const std::string_view nameView = name ? name : "";
    if (nameView.find("Motion Sensors") != std::string_view::npos ||
        nameView.find("Touchpad") != std::string_view::npos) {
        return false;
    }

    const char* isAccel = udev_device_get_property_value(dev, "ID_INPUT_ACCELEROMETER");
    if (isAccel && std::string_view(isAccel) == "1")
        return false;

    const char* isTouchpad = udev_device_get_property_value(dev, "ID_INPUT_TOUCHPAD");
    if (isTouchpad && std::string_view(isTouchpad) == "1")
        return false;

    const char* joystick = udev_device_get_property_value(dev, "ID_INPUT_JOYSTICK");
    return joystick && (std::string_view(joystick) == "1");
}

QString getControllerName(struct udev_device* dev) {
    const char* name = udev_device_get_property_value(dev, "NAME");
    if (name && *name != '\0') {
        // remove surrounding double quotes from raw udev string
        QString cleanName = QString::fromUtf8(name);
        if (cleanName.startsWith(u'"') && cleanName.endsWith(u'"')) {
            cleanName = cleanName.mid(1, cleanName.length() - 2);
        }
        return cleanName;
    }

    const char* model = udev_device_get_property_value(dev, "ID_MODEL");
    if (model && *model != '\0') {
        return QString::fromUtf8(model).replace(u'_', u' ');
    }

    return u"Wireless Controller"_s;
}

QString getMountedPath(const QString& objectPath) {
    QDBusMessage msg = QDBusMessage::createMethodCall(
        u"org.freedesktop.UDisks2"_s, objectPath, u"org.freedesktop.DBus.Properties"_s, u"Get"_s);
    msg << u"org.freedesktop.UDisks2.Filesystem"_s << u"MountPoints"_s;

    const QDBusMessage reply = QDBusConnection::systemBus().call(msg);
    if (reply.type() == QDBusMessage::ReplyMessage && !reply.arguments().isEmpty()) {
        const auto dbusVariant = reply.arguments().constFirst().value<QDBusVariant>();
        const QVariant variant = dbusVariant.variant();

        if (variant.canConvert<QDBusArgument>()) {
            const auto arg = variant.value<QDBusArgument>();
            if (arg.currentType() == QDBusArgument::ArrayType) {
                arg.beginArray();
                while (!arg.atEnd()) {
                    QByteArray bytes;
                    arg >> bytes;
                    if (!bytes.isEmpty()) {
                        arg.endArray();
                        return QString::fromUtf8(bytes);
                    }
                }
                arg.endArray();
            }
        } else if (variant.canConvert<QList<QByteArray>>()) {
            const auto list = variant.value<QList<QByteArray>>();
            if (!list.isEmpty()) {
                return QString::fromUtf8(list.constFirst());
            }
        }
    }
    return {};
}

} // namespace

namespace caelestia::services {

UdevService::UdevService(QObject* parent)
    : QObject(parent) {
    init();
}

UdevService::~UdevService() {
    if (m_monitor) {
        udev_monitor_unref(m_monitor);
    }
    if (m_udev) {
        udev_unref(m_udev);
    }
}

UdevService* UdevService::instance() {
    static UdevService s_instance;
    return &s_instance;
}

UdevService* UdevService::create(QQmlEngine* engine, QJSEngine* jsEngine) {
    Q_UNUSED(engine);
    Q_UNUSED(jsEngine);

    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

void UdevService::updateEnabledState() {
    auto* const toastConfig = config::ConfigSingleton::instance()->utilities()->toasts();
    const bool enabled = toastConfig->removableMediaChanged() || toastConfig->inputDevicesChanged();
    if (m_notifier) {
        m_notifier->setEnabled(enabled);
    }
}

void UdevService::init() {
    m_udev = udev_new();
    if (!m_udev) {
        qCWarning(lcUdev) << "Failed to create udev context";
        return;
    }
    m_monitor = udev_monitor_new_from_netlink(m_udev, "udev");
    if (!m_monitor) {
        qCWarning(lcUdev) << "Failed to create udev monitor context";
        return;
    }

    udev_monitor_filter_add_match_subsystem_devtype(m_monitor, "block", nullptr);
    udev_monitor_filter_add_match_subsystem_devtype(m_monitor, "input", nullptr);

    if (udev_monitor_enable_receiving(m_monitor) < 0) {
        qCWarning(lcUdev) << "Failed to receive device events";
        return;
    }

    const int fd = udev_monitor_get_fd(m_monitor);
    m_notifier = new QSocketNotifier(fd, QSocketNotifier::Read, this);

    auto* const toastConfig = config::ConfigSingleton::instance()->utilities()->toasts();
    connect(
        toastConfig, &config::UtilitiesToasts::removableMediaChangedChanged, this, &UdevService::updateEnabledState);
    connect(toastConfig, &config::UtilitiesToasts::inputDevicesChangedChanged, this, &UdevService::updateEnabledState);

    updateEnabledState();
    connect(m_notifier, &QSocketNotifier::activated, this, &UdevService::onSocketActivated);
}

void UdevService::onSocketActivated() {
    struct udev_device* dev = udev_monitor_receive_device(m_monitor);
    if (!dev) {
        qCWarning(lcUdev) << "Failed to receive device event";
        return;
    }

    const char* action = udev_device_get_action(dev);
    const char* subsystem = udev_device_get_subsystem(dev);
    if (!action || !subsystem) {
        udev_device_unref(dev);
        return;
    }

    const std::string_view actView(action);
    const std::string_view subView(subsystem);

    if (subView == "block") {
        handleBlockDevice(dev, actView);
    } else if (subView == "input") {
        handleInputDevice(dev, actView);
    }

    udev_device_unref(dev);
}

void UdevService::handleBlockDevice(struct udev_device* dev, std::string_view action) {
    if (action == "add") {
        handleStorageAdd(dev);
    } else if (action == "remove") {
        handleStorageRemove(dev);
    }
}

void UdevService::handleStorageAdd(struct udev_device* dev) {
    if (!isRemovableDrive(dev))
        return;

    const char* devNode = getDeviceNode(dev);
    const QString node = devNode ? QString::fromUtf8(devNode) : QString();
    const QString devName =
        node.isEmpty() ? QString::fromUtf8(udev_device_get_sysname(dev)) : QFileInfo(node).fileName();
    const QString label = getDriveLabel(dev);

    m_connectedDrives[devName] = label;

    auto* const toastConfig = config::ConfigSingleton::instance()->utilities()->toasts();
    if (toastConfig->autoOpen()) {
        QTimer::singleShot(300, this, [devName]() {
            UdevService::open(devName);
        });
    } else if (toastConfig->autoMount()) {
        QTimer::singleShot(300, this, [devName]() {
            UdevService::mount(devName);
        });
    }

    if (toastConfig->removableMediaChanged()) {
        QList<ToastAction> actions;

        if (!toastConfig->autoOpen()) {
            actions.append(ToastAction(u"Open files"_s, u"folder"_s, [devName]() {
                UdevService::open(devName);
            }));
        }
        if (!toastConfig->autoMount() && !toastConfig->autoOpen()) {
            actions.append(ToastAction(u"Mount"_s, u"hard_drive_2"_s, [devName]() {
                UdevService::mount(devName);
            }));
        }
        if (toastConfig->autoMount() || toastConfig->autoOpen()) {
            actions.append(ToastAction(u"Unmount"_s, u"eject"_s, [devName]() {
                UdevService::unmount(devName);
            }));
        }

        Toaster::instance()->toast(
            u"USB Drive Connected"_s, label, u"usb"_s, Toast::Type::Info, 5000, std::move(actions));
    }
}

void UdevService::handleStorageRemove(struct udev_device* dev) {
    const char* devNode = getDeviceNode(dev);
    const QString node = devNode ? QString::fromUtf8(devNode) : QString();
    const QString devName =
        node.isEmpty() ? QString::fromUtf8(udev_device_get_sysname(dev)) : QFileInfo(node).fileName();

    if (m_connectedDrives.contains(devName)) {
        const QString label = m_connectedDrives.take(devName);
        if (config::ConfigSingleton::instance()->utilities()->toasts()->removableMediaChanged()) {
            Toaster::instance()->toast(u"USB Drive Removed"_s, label, u"usb"_s, Toast::Type::Info);
        }
    }
}

void UdevService::handleInputDevice(struct udev_device* dev, std::string_view action) {
    if (!isController(dev) || m_controllerDebounce)
        return;

    // Debounce: ignore duplicate sub-device events (gyro/touchpad) within 1.5s
    m_controllerDebounce = true;
    QTimer::singleShot(1500, this, [this]() {
        m_controllerDebounce = false;
    });

    const QString name = getControllerName(dev);
    auto* const toastConfig = config::ConfigSingleton::instance()->utilities()->toasts();

    if (action == "add") {
        if (toastConfig->inputDevicesChanged()) {
            QList<ToastAction> actions = { ToastAction(u"Game Mode"_s, u"sports_esports"_s, []() {
                QProcess::startDetached(u"qs"_s, { u"ipc"_s, u"call"_s, u"gameMode"_s, u"toggle"_s });
            }) };
            Toaster::instance()->toast(
                u"Controller Connected"_s, name, u"sports_esports"_s, Toast::Type::Info, 5000, std::move(actions));
        }
    } else if (action == "remove") {
        if (toastConfig->inputDevicesChanged()) {
            Toaster::instance()->toast(u"Controller Disconnected"_s, name, u"sports_esports"_s, Toast::Type::Info);
        }
    }
}

QString UdevService::mountDevice(const QString& devName) {
    const QString objectPath = u"/org/freedesktop/UDisks2/block_devices/"_s + devName;

    // retry up to 6 times silently while UDisks2 is probing
    for (int attempt = 0; attempt < 6; ++attempt) {
        // check if already mounted
        QString mountedPath = getMountedPath(objectPath);
        if (!mountedPath.isEmpty()) {
            return mountedPath;
        }

        // request UDisks2 to mount
        QDBusMessage mountMsg = QDBusMessage::createMethodCall(
            u"org.freedesktop.UDisks2"_s, objectPath, u"org.freedesktop.UDisks2.Filesystem"_s, u"Mount"_s);
        mountMsg << QVariantMap();

        const QDBusMessage reply = QDBusConnection::systemBus().call(mountMsg);
        if (reply.type() == QDBusMessage::ReplyMessage && !reply.arguments().isEmpty()) {
            return reply.arguments().constFirst().toString();
        }

        const QString errName = reply.errorName();
        // If already mounted, retrieve mount point
        if (errName.contains(u"AlreadyMounted"_s)) {
            QString path = getMountedPath(objectPath);
            if (!path.isEmpty()) {
                return path;
            }
        }

        // if UDisks2 hasnt created the D-Bus object yet, wait silently and retry
        if (errName == u"org.freedesktop.DBus.Error.UnknownObject"_s ||
            errName == u"org.freedesktop.DBus.Error.ServiceUnknown"_s) {
            QThread::msleep(150);
            continue;
        }

        // Real failure
        qCWarning(lcUdev) << "Failed to mount device:" << devName << reply.errorMessage();
        Toaster::instance()->toast(u"Mount Failed"_s, reply.errorMessage(), u"error"_s, Toast::Type::Error);
        return {};
    }

    qCWarning(lcUdev) << "UDisks2 device object was not ready:" << devName;
    Toaster::instance()->toast(u"Mount Failed"_s, u"Device was not ready in time"_s, u"error"_s, Toast::Type::Error);
    return {};
}

void UdevService::mount(const QString& devName) {
    const QString path = mountDevice(devName);
    if (!path.isEmpty()) {
        QList<ToastAction> actions = {
            ToastAction(u"Open files"_s, u"folder"_s,
                [devName]() {
                    UdevService::open(devName);
                }),
            ToastAction(u"Unmount"_s, u"eject"_s,
                [devName]() {
                    UdevService::unmount(devName);
                }),
        };
        Toaster::instance()->toast(u"Drive Mounted"_s, u"Mounted at: %1"_s.arg(path), u"hard_drive_2"_s,
            Toast::Type::Success, 5000, std::move(actions));
    }
}

void UdevService::unmount(const QString& devName) {
    const QString objectPath = u"/org/freedesktop/UDisks2/block_devices/"_s + devName;
    QDBusInterface fsIface(u"org.freedesktop.UDisks2"_s, objectPath, u"org.freedesktop.UDisks2.Filesystem"_s,
        QDBusConnection::systemBus());

    const QDBusReply<void> reply = fsIface.call(u"Unmount"_s, QVariantMap());
    if (reply.isValid()) {
        Toaster::instance()->toast(
            u"Drive Unmounted"_s, u"You can safely remove the device now."_s, u"eject"_s, Toast::Type::Success);
    } else {
        qCWarning(lcUdev) << "Failed to unmount device:" << devName << reply.error().message();
        Toaster::instance()->toast(u"Unmount Failed"_s, reply.error().message(), u"error"_s, Toast::Type::Error);
    }
}

void UdevService::open(const QString& devName) {
    const QString mountPath = mountDevice(devName);
    if (mountPath.isEmpty())
        return;

    auto explorerCmd = config::ConfigSingleton::instance()->general()->apps()->explorer();
    if (!explorerCmd.isEmpty()) {
        const QString program = explorerCmd.takeFirst();
        explorerCmd.append(mountPath);
        QProcess::startDetached(program, explorerCmd);
    }
}

} // namespace caelestia::services
