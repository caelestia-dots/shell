pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

// Mirrors StatusIcons EntryWrapper: hover fills a content-sized cell (vertical pill),
// not the full bar width.
Item {
    id: root

    required property SystemTrayItem modelData
    required property int index
    required property var popouts

    readonly property int iconSize: 20
    // Same pad as StatusIcons EntryWrapper
    readonly property int iconPad: Tokens.padding.extraSmall
    // MaterialIcon cells are taller than wide (font metrics) → vertical pill hover
    readonly property int statusIconH: Math.round(Tokens.font.icon.medium.pixelSize)

    readonly property string trayId: String(modelData.id || "").toLowerCase()
    readonly property string trayIcon: String(modelData.icon || "").toLowerCase()

    // Cursor / Steam (and similar) ship a near-black tray glyph that vanishes on dark bars.
    readonly property bool forceLightIcon: trayId.includes("cursor") || trayId.includes("steam") || trayIcon.includes("steam")
    readonly property bool colourise: Config.bar.tray.recolour || forceLightIcon
    readonly property bool menuOpen: popouts?.hasCurrent && popouts?.currentName === `traymenu${index}`
    readonly property bool highlighted: hover.containsMouse || menuOpen

    implicitWidth: iconSize + iconPad * 2
    implicitHeight: Math.max(iconSize, statusIconH) + iconPad * 2

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.full
        color: root.highlighted ? Colours.palette.m3primary : "transparent"
        z: -1

        Behavior on color {
            CAnim {}
        }
    }

    ColouredIcon {
        id: icon

        anchors.centerIn: parent
        implicitSize: root.iconSize
        width: root.iconSize
        height: root.iconSize
        source: Icons.getTrayIcon(root.modelData.id, root.modelData.icon)
        colour: root.highlighted ? Colours.palette.m3onPrimary : Config.bar.tray.recolour ? Colours.palette.m3secondary : Colours.palette.m3onSurface
        layer.enabled: root.colourise
        asynchronous: true
        mipmap: true
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: event => {
            if (event.button === Qt.LeftButton)
                root.modelData.activate();
            else
                root.modelData.secondaryActivate();
        }
    }
}
