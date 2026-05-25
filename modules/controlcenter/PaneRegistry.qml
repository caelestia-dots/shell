pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property list<QtObject> panes: [
        QtObject {
            readonly property string paneId: "network"
            readonly property string label: "network"
            readonly property string icon: "router"
            readonly property string component: "network/NetworkingPane.qml"
        },
        QtObject {
            readonly property string paneId: "bluetooth"
            readonly property string label: "bluetooth"
            readonly property string icon: "settings_bluetooth"
            readonly property string component: "bluetooth/BtPane.qml"
        },
        QtObject {
            readonly property string paneId: "audio"
            readonly property string label: "audio"
            readonly property string icon: "volume_up"
            readonly property string component: "audio/AudioPane.qml"
        },
        QtObject {
            readonly property string paneId: "appearance"
            readonly property string label: "appearance"
            readonly property string icon: "palette"
            readonly property string component: "appearance/AppearancePane.qml"
        },
        QtObject {
            readonly property string paneId: "taskbar"
            readonly property string label: "taskbar"
            readonly property string icon: "task_alt"
            readonly property string component: "taskbar/TaskbarPane.qml"
        },
        QtObject {
            readonly property string paneId: "notifications"
            readonly property string label: "notifications"
            readonly property string icon: "notifications"
            readonly property string component: "notifications/NotificationsPane.qml"
        },
        QtObject {
            readonly property string paneId: "launcher"
            readonly property string label: "launcher"
            readonly property string icon: "apps"
            readonly property string component: "launcher/LauncherPane.qml"
        },
        QtObject {
            readonly property string paneId: "dashboard"
            readonly property string label: "dashboard"
            readonly property string icon: "dashboard"
            readonly property string component: "dashboard/DashboardPane.qml"
        }
    ]

    readonly property int count: panes.length

    readonly property var labels: {
        const result = [];
        for (let i = 0; i < panes.length; i++) {
            result.push(panes[i].label);
        }
        return result;
    }

    function getByIndex(index: int): var {
        if (index >= 0 && index < panes.length) {
            return panes[index];
        }
        return null;
    }

    function getIndexByLabel(label: string): int {
        for (let i = 0; i < panes.length; i++) {
            if (panes[i].label === label) {
                return i;
            }
        }
        return -1;
    }

    function getByLabel(label: string): var {
        const index = getIndexByLabel(label);
        return getByIndex(index);
    }

    function getById(id: string): var {
        for (let i = 0; i < panes.length; i++) {
            if (panes[i].paneId === id) {
                return panes[i];
            }
        }
        return null;
    }
}
