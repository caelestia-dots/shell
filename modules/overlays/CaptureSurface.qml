import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Caelestia.Blobs
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Scheme
import qs.components
import qs.components.controls

Item {
    id: root

    required property CaptureState cState
    required property ShellScreen screen
    required property real contentOpacity
    property alias session: capture.session

    ScreenCapture {
        id: capture

        anchors.fill: parent
        opacity: root.contentOpacity
    }

    RegionSelect {
        anchors.fill: parent
        opacity: root.contentOpacity
        screen: root.screen
        freeze: true
        selectClients: root.cState.selectClients
        showCrosshair: root.cState.showCrosshair
        onSelected: r => capture.session.save(Qt.rect(r.x + screen.x, r.y + screen.y, r.width, r.height))
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
            id: topRect

            group: group
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.cState.open ? 0 : -height - 10

            radius: Tokens.rounding.extraExtraLarge
            implicitWidth: topContent.implicitWidth
            implicitHeight: topContent.implicitHeight

            deformScale: 0.00005 * Config.appearance.deformScale

            Behavior on y {
                Anim {
                    type: Anim.SlowEffects
                }
            }
        }
    }

    MouseArea {
        id: topContent

        x: topRect.x
        y: topRect.y

        implicitWidth: topLayout.implicitWidth + Tokens.padding.small * 2
        implicitHeight: topLayout.implicitHeight + Tokens.padding.small * 2

        opacity: root.contentOpacity
        hoverEnabled: true

        transform: Matrix4x4 {
            matrix: topRect.deformMatrix
        }

        RowLayout {
            id: topLayout

            anchors.centerIn: parent
            spacing: Tokens.spacing.medium

            MaterialIcon {
                id: topIcon

                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Tokens.padding.medium
                text: "screenshot_region"
                color: Colours.palette.onSecondaryContainer
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: Tr.tr("Drag to select a region")
                color: Colours.palette.onSecondaryContainer
                font: Tokens.font.body.medium
            }

            ButtonRow {
                spacing: Tokens.spacing.extraSmall

                IconButton {
                    shapeMorph: true
                    isRound: true
                    isToggle: true
                    inactiveColour: Colours.palette.primaryContainer
                    inactiveOnColour: Colours.palette.onPrimaryContainer
                    implicitWidth: implicitHeight + Tokens.padding.small * 2
                    padding: Tokens.padding.small
                    checked: root.cState.showCrosshair
                    icon: "my_location"
                    onClicked: root.cState.showCrosshair = !root.cState.showCrosshair
                }

                IconButton {
                    shapeMorph: true
                    isRound: true
                    isToggle: true
                    inactiveColour: Colours.palette.primaryContainer
                    inactiveOnColour: Colours.palette.onPrimaryContainer
                    implicitWidth: implicitHeight + Tokens.padding.small * 2
                    padding: Tokens.padding.small
                    checked: root.cState.selectClients
                    icon: "select_window_2"
                    onClicked: root.cState.selectClients = !root.cState.selectClients
                }

                IconButton {
                    shapeMorph: true
                    isRound: true
                    inactiveColour: Colours.palette.primaryContainer
                    inactiveOnColour: Colours.palette.onPrimaryContainer
                    implicitWidth: implicitHeight + Tokens.padding.small * 2
                    padding: Tokens.padding.small
                    icon: "close"
                    onClicked: root.cState.cancelled()
                }
            }
        }
    }
}
