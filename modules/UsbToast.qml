import QtQuick
import qs.config
import Caelestia

Item {
    id: root

    // Service injected via shell.qml
    required property var usbService

    /* =======================
     * CONFIGURATION
     * ======================= */

    property bool serviceToastEnabled: Config.utilities?.toasts?.usbServiceToast ?? false
    property bool deviceToastEnabled: Config.utilities?.toasts?.usbNotifications ?? true
    property int toastDuration: 3000

    // Toast throttling to prevent notification spam
    property double lastToastTime: 0
    property int toastDebounceMs: 400

    /* =======================
     * HELPERS
     * ======================= */
    function canToast() {
        const now = Date.now();
        if (now - root.lastToastTime < root.toastDebounceMs)
            return false;
        root.lastToastTime = now;
        return true;
    }

    // Material Symbols icon mapping based on device class
    function deviceIcon(device, isConnected) {
        const type = (device.type || "").toLowerCase();

        const icons = {
            "keyboard": {
                on: "keyboard",
                off: "keyboard_off"
            },
            "mouse": {
                on: "mouse",
                off: "mouse_lock_off"
            },
            "storage": {
                on: "usb",
                off: "usb_off"
            },
            "audio": {
                on: "Media_Output",
                off: "Media_Output_Off"
            },
            "video": {
                on: "videocam",
                off: "videocam_off"
            },
            "hid": {
                on: "usb",
                off: "usb_off"
            },
            "gamepad": {
                on: "videogame_asset",
                off: "videogame_asset_off"
            },
            "phone": {
                on: "mobile_hand",
                off: "mobile_hand_off"
            },
            "default": {
                on: "usb",
                off: "usb_off"
            }
        };

        const iconSet = icons[type] || icons["default"];

        return isConnected ? iconSet.on : iconSet.off;
    }

    function deviceLabel(device) {
        if (!device)
            return qsTr("Dispositivo USB");
        return device.name || qsTr("Dispositivo USB");
    }

    function deviceType(device) {
        if (!device)
            return qsTr("USB");
        return qsTr(device.type || "USB");
    }

    // Formats string as "Device Name • Device Type"
    function deviceSubtitle(device) {
        // Example: "Logitech G502 • Mouse"
        return root.deviceLabel(device) + " • " + root.deviceType(device);
    }

    /* =======================
     * INITIALIZATION
     * ======================= */
    Component.onCompleted: {
        if (!root.serviceToastEnabled)
            return;

        Qt.callLater(() => {
            Toaster.toast(qsTr("Monitor USB"), qsTr("Servicio activo"), "usb", Toast.Info, 2000);
        });
    }

    /* =======================
     * SERVICE EVENT HANDLERS
     * ======================= */

    Connections {
        target: root.deviceToastEnabled ? root.usbService : null

        function onDeviceConnected(device) {
            if (!root.canToast())
                return;
            Toaster.toast(qsTr("Device Connected"), root.deviceSubtitle(device), root.deviceIcon(device, true), Toast.Info, root.toastDuration);
        }

        function onDeviceDisconnected(device) {
            // Throttling skipped for disconnect events to ensure UI feedback
            Toaster.toast(qsTr("Device Disconnected"), root.deviceSubtitle(device), root.deviceIcon(device, false), Toast.Info, root.toastDuration);
        }
    }
}
