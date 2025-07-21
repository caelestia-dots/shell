pragma ComponentBehavior: Bound

import qs.widgets
import qs.config
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import QtQuick

MouseArea {
    id: root

    required property SystemTrayItem modelData

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitWidth: Appearance.font.size.small * 2
    implicitHeight: Appearance.font.size.small * 2

    onClicked: event => {
        if (event.button === Qt.LeftButton)
            modelData.activate();
        else
            modelData.secondaryActivate();
    }

    IconImage {
        id: icon

        source: {
            let icon = root.modelData.icon;
            if (icon.includes("?path=")) {
                const [name, path] = icon.split("?path=");
                icon = `file://${path}/${name.slice(name.lastIndexOf("/") + 1)}`;
            }
            return icon;
        }
        asynchronous: true
        anchors.fill: parent
    }
}
