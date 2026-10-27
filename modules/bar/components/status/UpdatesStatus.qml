pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property color colour

    // Vertical stack so the count fits the narrow status pill
    implicitWidth: Math.max(icon.implicitWidth, badge.implicitWidth)
    implicitHeight: icon.implicitHeight + (badge.visible ? badge.implicitHeight - Tokens.padding.extraSmall : 0)

    MaterialIcon {
        id: icon

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        animate: true
        text: Updates.installing ? "install_desktop" : Updates.glyph
        fill: Updates.hasUpdates || Updates.installing ? 1 : 0
        color: root.colour
        opacity: Updates.busy || Updates.installing ? 0.55 : 1

        SequentialAnimation on opacity {
            running: Updates.busy || Updates.installing
            loops: Animation.Infinite
            alwaysRunToEnd: true
            Anim {
                from: 1
                to: 0.35
                duration: Tokens.anim.durations.large
            }
            Anim {
                from: 0.35
                to: 1
                duration: Tokens.anim.durations.large
            }
        }
    }

    StyledText {
        id: badge

        anchors.top: icon.bottom
        anchors.topMargin: -Tokens.padding.extraSmall
        anchors.horizontalCenter: parent.horizontalCenter
        visible: Updates.hasUpdates && !Updates.busy && !Updates.installing
        text: Updates.count > 99 ? "99+" : `${Updates.count}`
        color: root.colour
        font: Tokens.font.label.builders.small.weight(Font.Bold).scale(0.8).build()
        horizontalAlignment: Text.AlignHCenter
    }
}
