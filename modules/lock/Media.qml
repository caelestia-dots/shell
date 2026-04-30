pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

Item {
    id: root

    required property var lock

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: layout.implicitHeight

    Image {
        anchors.fill: parent
        source: Players.getArtUrl(Players.active)

        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize: {
            const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
            return Qt.size(width * dpr, height * dpr);
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: mask
        }

        opacity: status === Image.Ready ? 1 : 0

        Behavior on opacity {
            Anim {
                type: Anim.StandardExtraLarge
            }
        }
    }

    Rectangle {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: Qt.rgba(0, 0, 0, 0.5)
            }
            GradientStop {
                position: 0.4
                color: Qt.rgba(0, 0, 0, 0.2)
            }
            GradientStop {
                position: 0.8
                color: Qt.rgba(0, 0, 0, 0)
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large

        StyledText {
            Layout.topMargin: Tokens.padding.large
            Layout.bottomMargin: Tokens.spacing.larger
            text: qsTr("Now playing")
            color: Colours.palette.m3onSurfaceVariant
            font.family: Tokens.font.family.mono
            font.weight: 500
        }

        StyledText {
            Layout.fillWidth: true
            animate: true
            text: Players.active?.trackArtist ?? qsTr("No media")
            color: Colours.palette.m3primary
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: Tokens.font.size.large
            font.family: Tokens.font.family.mono
            font.weight: 600
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            animate: true
            text: Players.active?.trackTitle ?? qsTr("No media")
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: Tokens.font.size.larger
            font.family: Tokens.font.family.mono
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.large * 1.2
            Layout.bottomMargin: Tokens.padding.large

            spacing: Tokens.spacing.large

            PlayerControl {
                icon: "skip_previous"
                onClicked: {
                    if (Players.active?.canGoPrevious)
                        Players.active.previous();
                }
            }

            PlayerControl {
                animate: true
                icon: active ? "pause" : "play_arrow"
                colour: "Primary"
                level: active ? 2 : 1
                active: Players.active?.isPlaying ?? false
                onClicked: {
                    if (Players.active?.canTogglePlaying)
                        Players.active.togglePlaying();
                }
            }

            PlayerControl {
                icon: "skip_next"
                onClicked: {
                    if (Players.active?.canGoNext)
                        Players.active.next();
                }
            }
        }
    }

    component PlayerControl: StyledRect {
        id: control

        property alias animate: controlIcon.animate
        property alias icon: controlIcon.text
        property bool active
        property string colour: "Secondary"
        property int level: 1

        signal clicked

        Layout.preferredWidth: implicitWidth + (controlState.pressed ? Tokens.padding.normal * 2 : active ? Tokens.padding.small * 2 : 0)
        implicitWidth: controlIcon.implicitWidth + Tokens.padding.large * 2
        implicitHeight: controlIcon.implicitHeight + Tokens.padding.normal * 2

        color: active ? Colours.palette[`m3${colour.toLowerCase()}`] : Colours.palette[`m3${colour.toLowerCase()}Container`]
        radius: active || controlState.pressed ? Tokens.rounding.normal : Math.min(implicitWidth, implicitHeight) / 2 * Math.min(1, Tokens.rounding.scale)

        Elevation {
            anchors.fill: parent
            radius: parent.radius
            z: -1
            level: controlState.containsMouse && !controlState.pressed ? control.level + 1 : control.level
        }

        StateLayer {
            id: controlState

            color: control.active ? Colours.palette[`m3on${control.colour}`] : Colours.palette[`m3on${control.colour}Container`]
            onClicked: control.clicked()
        }

        MaterialIcon {
            id: controlIcon

            anchors.centerIn: parent
            color: control.active ? Colours.palette[`m3on${control.colour}`] : Colours.palette[`m3on${control.colour}Container`]
            font.pointSize: Tokens.font.size.large
            fill: control.active ? 1 : 0

            Behavior on fill {
                Anim {}
            }
        }

        Behavior on Layout.preferredWidth {
            Anim {
                type: Anim.FastSpatial
            }
        }

        Behavior on radius {
            Anim {
                type: Anim.FastSpatial
            }
        }
    }
}
