pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

MouseArea {
    id: root

    required property SystemTrayItem modelData
    required property int index
    required property var popouts

    // Tweak this to match status icons (bluetooth, etc.).
    readonly property int iconSize: 20
    readonly property int pad: Tokens.padding.extraSmall

    // Cursor (and similar) ship a near-black tray glyph that vanishes on dark bars.
    readonly property bool forceLightIcon: {
        const id = String(modelData.id || "").toLowerCase();
        return id.includes("cursor");
    }
    readonly property bool colourise: Config.bar.tray.recolour || forceLightIcon
    readonly property bool menuOpen: popouts?.hasCurrent && popouts?.currentName === `traymenu${index}`
    readonly property bool highlighted: containsMouse || menuOpen

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitWidth: iconSize + pad * 2
    implicitHeight: iconSize + pad * 2

    onClicked: event => {
        if (event.button === Qt.LeftButton)
            modelData.activate();
        else
            modelData.secondaryActivate();
    }

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.full
        color: root.highlighted ? Colours.palette.m3primary : "transparent"

        Behavior on color {
            CAnim {}
        }
    }

    ColouredIcon {
        id: icon

        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        source: Icons.getTrayIcon(root.modelData.id, root.modelData.icon)
        colour: root.highlighted ? Colours.palette.m3onPrimary : Config.bar.tray.recolour ? Colours.palette.m3secondary : Colours.palette.m3onSurface
        layer.enabled: root.colourise
        asynchronous: true
        mipmap: true
    }
}
