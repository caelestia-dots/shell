import "root:/widgets"
import "root:/services"
import "root:/config"
import "root:/utils"
import Quickshell
import Quickshell.Io
import QtQuick

Row {
    id: root

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
            font.pointSize: (info.implicitHeight / 2) || 1
        }

        Image {
            id: avatarImage
            anchors.fill: parent
            source: `${Paths.cache}/thumbnails/@93x93-exact.png?${Date.now()}`
            fillMode: Image.PreserveAspectCrop
            smooth: true
            cache: false
        }

        Rectangle {
            id: overlay
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.4)
            opacity: mouseArea.containsMouse ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: "photo_camera"
                color: "white"
                font.pointSize: info.implicitHeight / 4
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: avatarUpdateProc.running = true
            cursorShape: Qt.PointingHandCursor
        }

        Process {
            id: avatarUpdateProc
            running: false
            command: ["python3", `${Quickshell.shellRoot}/assets/face-selector.py`]

            stdout: SplitParser {
                onRead: {
                    avatarImage.source = "";
                    avatarImage.source = `${Paths.cache}/thumbnails/@93x93-exact.png?${Date.now()}`
                    notifyProc.running = true;
                }
            }
        }

        Process {
            id: notifyProc
            running: false
            command: [
                "notify-send",
                "-u", "low",
                "-i", "icon_user",
                "Profile Updated",
                "Your avatar has been successfully changed.",
            ]
        }
    }

    Column {
        id: info

        spacing: Appearance.spacing.normal

        InfoLine {
            icon: Icons.osIcon
            text: Icons.osName
            colour: Colours.palette.m3primary
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
                stdout: SplitParser {
                    onRead: data => uptimeProc.uptime = data
                }
            }
        }
    }

    component InfoLine: Item {
        id: line

        required property string icon
        required property string text
        required property color colour

        implicitWidth: icon.implicitWidth + text.width + text.anchors.leftMargin
        implicitHeight: Math.max(icon.implicitHeight, text.implicitHeight)

        MaterialIcon {
            id: icon

            anchors.left: parent.left
            anchors.leftMargin: (DashboardConfig.sizes.infoIconSize - implicitWidth) / 2

            text: line.icon
            color: line.colour
            font.pointSize: Appearance.font.size.normal
            font.variableAxes: ({
                    FILL: 1
                })
        }

        StyledText {
            id: text

            anchors.verticalCenter: icon.verticalCenter
            anchors.left: icon.right
            anchors.leftMargin: icon.anchors.leftMargin
            text: `:  ${line.text}`
            font.pointSize: Appearance.font.size.normal

            width: DashboardConfig.sizes.infoWidth
            elide: Text.ElideRight
        }
    }
}
