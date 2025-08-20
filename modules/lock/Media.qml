pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var lock

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: layout.implicitHeight

    Image {
        anchors.fill: parent
        source: root.lock.animating ? "" : (Players.active?.trackArtUrl ?? "")

        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: width
        sourceSize.height: height

        layer.enabled: true
        layer.effect: ShaderEffect {
            required property Item source
            readonly property Item maskSource: mask

            fragmentShader: `file://${Quickshell.shellDir}/assets/shaders/opacitymask.frag.qsb`
        }

        opacity: status === Image.Ready ? 1 : 0

        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.extraLarge
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
        anchors.margins: Appearance.padding.large

        StyledText {
            Layout.topMargin: Appearance.padding.large
            Layout.bottomMargin: Appearance.spacing.larger
            text: qsTr("Now playing")
            color: Colours.palette.m3onSurfaceVariant
            font.family: Appearance.font.family.mono
            font.weight: 500
        }

        StyledText {
            Layout.fillWidth: true
            animate: true
            text: Players.active?.trackArtist ?? qsTr("No media")
            color: Colours.palette.m3primary
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: Appearance.font.size.large
            font.family: Appearance.font.family.mono
            font.weight: 600
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            animate: true
            text: Players.active?.trackTitle ?? qsTr("No media")
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: Appearance.font.size.larger
            font.family: Appearance.font.family.mono
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Appearance.spacing.large * 1.2
            Layout.bottomMargin: Appearance.padding.large

            spacing: Appearance.spacing.large

            PlayerControl {
                icon: "skip_previous"

                function onClicked(): void {
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

                function onClicked(): void {
                    if (Players.active?.canTogglePlaying)
                        Players.active.togglePlaying();
                }
            }

            PlayerControl {
                icon: "skip_next"

                function onClicked(): void {
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

        function onClicked(): void {
        }

        Layout.preferredWidth: implicitWidth + (controlState.pressed ? Appearance.padding.normal * 2 : active ? Appearance.padding.small * 2 : 0)
        implicitWidth: controlIcon.implicitWidth + Appearance.padding.large * 2
        implicitHeight: controlIcon.implicitHeight + Appearance.padding.normal * 2

        color: active ? Colours.palette[`m3${colour.toLowerCase()}`] : Colours.palette[`m3${colour.toLowerCase()}Container`]
        radius: active || controlState.pressed ? Appearance.rounding.normal : Math.min(implicitWidth, implicitHeight) / 2 * Math.min(1, Appearance.rounding.scale)

        Elevation {
            anchors.fill: parent
            radius: parent.radius
            z: -1
            level: controlState.containsMouse && !controlState.pressed ? control.level + 1 : control.level
        }

        StateLayer {
            id: controlState

            color: control.active ? Colours.palette[`m3on${control.colour}`] : Colours.palette[`m3on${control.colour}Container`]

            function onClicked(): void {
                control.onClicked();
            }
        }

        MaterialIcon {
            id: controlIcon

            anchors.centerIn: parent
            color: control.active ? Colours.palette[`m3on${control.colour}`] : Colours.palette[`m3on${control.colour}Container`]
            font.pointSize: Appearance.font.size.large
            fill: control.active ? 1 : 0

            Behavior on fill {
                Anim {}
            }
        }

        Behavior on Layout.preferredWidth {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }

        Behavior on radius {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
