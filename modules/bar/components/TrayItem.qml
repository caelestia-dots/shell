pragma ComponentBehavior: Bound

import qs.components.effects
import qs.services
import qs.config
import qs.utils
import Quickshell.Services.SystemTray
import QtQuick

Item {
    id: root

    required property SystemTrayItem modelData

    visible: Icons.getTrayIconVisibility(modelData.id)

    implicitWidth: Appearance.font.size.small * 2
    implicitHeight: Appearance.font.size.small * 2

    MouseArea {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        anchors.fill: parent

        onClicked: event => {
            if (event.button === Qt.LeftButton)
                root.modelData.activate();
            else
                root.modelData.secondaryActivate();
        }

        ColouredIcon {
            id: icon

            anchors.fill: parent
            source: Icons.getTrayIcon(root.modelData.id, root.modelData.icon)
            colour: Colours.palette.m3secondary
            layer.enabled: Config.bar.tray.recolour
        }
    }
}