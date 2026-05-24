pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components.effects
import qs.services
import qs.utils

MouseArea {
    id: root

    required property SystemTrayItem modelData

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitWidth: Tokens.font.size.small * 2
    implicitHeight: Tokens.font.size.small * 2

    onClicked: event => {
        if (event.button === Qt.LeftButton)
            modelData.activate();
        else
            modelData.secondaryActivate();
    }

    ColouredIcon {
        id: icon

        readonly property var candidates: Icons.getTrayIconCandidates(root.modelData.id, root.modelData.icon)
        property int candidateIndex: 0

        anchors.fill: parent
        source: candidates[candidateIndex] ?? ""
        colour: Colours.palette.m3secondary
        layer.enabled: Config.bar.tray.recolour

        onCandidatesChanged: candidateIndex = 0
        onStatusChanged: {
            if (status === Image.Error && candidateIndex < candidates.length - 1)
                candidateIndex++;
        }
    }
}
