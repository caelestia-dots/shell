pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property color colour

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        animate: true
        // Shield-style glyphs (like KDE network-vpn)
        text: MadisonVpn.connected ? "verified_user" : "remove_moderator"
        fill: MadisonVpn.connected ? 1 : 0
        color: MadisonVpn.connected ? Colours.palette.m3primary : root.colour
        opacity: MadisonVpn.busy ? 0.55 : 1

        SequentialAnimation on opacity {
            running: MadisonVpn.busy
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
}
