import QtQuick
import QtQuick.Effects
import Quickshell
import Caelestia.Blobs
import Caelestia.Config
import Caelestia.Scheme
import qs.components

Item {
    id: root

    required property RegionState rState
    required property ShellScreen screen
    required property bool open
    required property real contentOpacity

    signal selected(region: rect)

    focus: true
    Keys.onEscapePressed: rState.cancelled()

    RegionSelect {
        anchors.fill: parent
        opacity: root.contentOpacity
        selection: root.rState
        screen: root.screen
        onSelected: region => root.selected(region)
    }

    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha("black", 0.4)
        }

        BlobGroup {
            id: group

            smoothing: root.Tokens.rounding.extraLargeIncreased
            color: Colours.palette.secondaryContainer

            Behavior on color {
                CAnim {}
            }
        }

        BlobInvertedRect {
            group: group
            anchors.fill: parent
        }

        BlobRect {
            id: toolbarBg

            group: group
            anchors.horizontalCenter: parent.horizontalCenter
            y: !root.open || root.rState.selecting ? -height - 10 : 0

            radius: Tokens.rounding.extraExtraLarge
            implicitWidth: toolbar.implicitWidth
            implicitHeight: toolbar.implicitHeight

            deformScale: 0.00005 * Config.appearance.deformScale

            Behavior on y {
                Anim {
                    type: Anim.SlowEffects
                }
            }
        }
    }

    MouseArea {
        id: toolbar

        x: toolbarBg.x
        y: toolbarBg.y

        clip: true
        implicitWidth: toolbarContent.implicitWidth + Tokens.padding.small * 2
        implicitHeight: toolbarContent.implicitHeight + Tokens.padding.small * 2

        opacity: root.contentOpacity
        hoverEnabled: true

        transform: Matrix4x4 {
            matrix: toolbarBg.deformMatrix
        }

        RegionToolbar {
            id: toolbarContent

            anchors.centerIn: parent
            rState: root.rState
        }
    }
}
