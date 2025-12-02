pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property list<QtObject> panes: [
        QtObject {
            readonly property string id: "network"
            readonly property string label: "network"
            readonly property string icon: "router"
            readonly property string component: "network/NetworkingPane.qml"
        },
        QtObject {
            readonly property string id: "bluetooth"
            readonly property string label: "bluetooth"
            readonly property string icon: "settings_bluetooth"
            readonly property string component: "bluetooth/BtPane.qml"
        },
        QtObject {
            readonly property string id: "audio"
            readonly property string label: "audio"
            readonly property string icon: "volume_up"
            readonly property string component: "audio/AudioPane.qml"
        },
        QtObject {
            readonly property string id: "appearance"
            readonly property string label: "appearance"
            readonly property string icon: "palette"
            readonly property string component: "appearance/AppearancePane.qml"
        },
        QtObject {
            readonly property string id: "taskbar"
            readonly property string label: "taskbar"
            readonly property string icon: "task_alt"
            readonly property string component: "taskbar/TaskbarPane.qml"
        },
        QtObject {
            readonly property string id: "launcher"
            readonly property string label: "launcher"
            readonly property string icon: "apps"
            readonly property string component: "launcher/LauncherPane.qml"
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

    function getByIndex(index: int): QtObject {
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

    function getByLabel(label: string): QtObject {
        const index = getIndexByLabel(label);
        return getByIndex(index);
    }

    function getById(id: string): QtObject {
        for (let i = 0; i < panes.length; i++) {
            if (panes[i].id === id) {
                return panes[i];
            }
        }
        return null;
    }
}

