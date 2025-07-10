import "root:/widgets"
import "root:/services"
import "root:/config"
import "root:/utils"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Dialogs

Row {
    id: root

    required property PersistentProperties visibilities
    required property PersistentProperties state

    padding: Appearance.padding.large
    spacing: Appearance.spacing.normal

    StyledClippingRect {
        implicitWidth: info.implicitHeight
        implicitHeight: info.implicitHeight

        radius: Appearance.rounding.large
        color: Colours.palette.m3surfaceContainerHigh

        MaterialIcon {
            anchors.centerIn: parent

            text: "person"
            fill: 1
            grade: 200
            font.pointSize: Math.floor(info.implicitHeight / 2) || 1
        }

        CachingImage {
            id: pfp

            anchors.fill: parent
            path: `${Paths.stringify(Paths.home)}/.face`
        }

        MouseArea {
            anchors.fill: parent

            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: {
                root.visibilities.launcher = false;
                root.state.facePicker.open();
            }

            StyledRect {
                anchors.fill: parent

                color: Qt.alpha(Colours.palette.m3primary, 0.1)
                opacity: parent.containsMouse ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.anim.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                }
            }

            StyledRect {
                anchors.centerIn: parent

                implicitWidth: selectIcon.implicitHeight + Appearance.padding.small * 2
                implicitHeight: selectIcon.implicitHeight + Appearance.padding.small * 2

                radius: Appearance.rounding.normal
                color: Colours.palette.m3primary
                scale: parent.containsMouse ? 1 : 0.5
                opacity: parent.containsMouse ? 1 : 0

                MaterialIcon {
                    id: selectIcon

                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -font.pointSize * 0.02

                    text: "frame_person"
                    color: Colours.palette.m3onPrimary
                    font.pointSize: Appearance.font.size.extraLarge
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Appearance.anim.durations.expressiveFastSpatial
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.anim.durations.expressiveFastSpatial
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                    }
                }
            }
        }
    }

    Column {
        id: info

        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.normal

        InfoLine {
            icon: Icons.osIcon
            text: Icons.osName
            colour: Colours.palette.m3primary
            materialIcon: false
        }

        InfoLine {
            icon: "select_window_2"
            text: Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP")
            colour: Colours.palette.m3secondary
        }

        InfoLine {
            icon: "timer"
            text: uptimeProc.uptime
            colour: Colours.palette.m3tertiary

            Timer {
                running: true
                repeat: true
                interval: 15000
                onTriggered: uptimeProc.running = true
            }

            Process {
                id: uptimeProc

                property string uptime

                running: true
                command: ["uptime", "-p"]
                stdout: StdioCollector {
                    onStreamFinished: uptimeProc.uptime = text.trim()
                }
            }
        }
    }

    component InfoLine: Item {
        id: line

        required property string icon
        required property string text
        required property color colour
        property bool materialIcon: true

        implicitWidth: icon.implicitWidth + text.width + text.anchors.leftMargin
        implicitHeight: Math.max(icon.implicitHeight, text.implicitHeight)

        MaterialIcon {
            id: icon

            anchors.left: parent.left
            anchors.leftMargin: (Config.dashboard.sizes.infoIconSize - implicitWidth) / 2

            fill: 1
            text: line.icon
            color: line.colour
            font.pointSize: Appearance.font.size.normal
            font.family: line.materialIcon ? Appearance.font.family.material : Appearance.font.family.sans
        }

        StyledText {
            id: text

            anchors.verticalCenter: icon.verticalCenter
            anchors.left: icon.right
            anchors.leftMargin: icon.anchors.leftMargin
            text: `:  ${line.text}`
            font.pointSize: Appearance.font.size.normal

            width: Config.dashboard.sizes.infoWidth
            elide: Text.ElideRight
        }
    }
}
