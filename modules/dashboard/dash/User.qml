import qs.components
import qs.components.effects
import qs.components.images
import qs.components.filedialog
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick

Row {
    id: root

    required property PersistentProperties visibilities
    required property PersistentProperties state
    required property FileDialog facePicker

    padding: Appearance.padding.large
    spacing: Appearance.spacing.normal

    StyledClippingRect {
        implicitWidth: info.implicitHeight
        implicitHeight: info.implicitHeight

        radius: Appearance.rounding.large
        color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

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
            path: `${Paths.home}/.face`
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            StyledRect {
                anchors.fill: parent

                color: Qt.alpha(Colours.palette.m3scrim, 0.5)
                opacity: parent.containsMouse ? 1 : 0

                Behavior on opacity {
                    Anim {
                        duration: Appearance.anim.durations.expressiveFastSpatial
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

                StateLayer {
                    color: Colours.palette.m3onPrimary

                    function onClicked(): void {
                        root.visibilities.launcher = false;
                        root.facePicker.open();
                    }
                }

                MaterialIcon {
                    id: selectIcon

                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -font.pointSize * 0.02

                    text: "frame_person"
                    color: Colours.palette.m3onPrimary
                    font.pointSize: Appearance.font.size.extraLarge
                }

                Behavior on scale {
                    Anim {
                        duration: Appearance.anim.durations.expressiveFastSpatial
                        easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                    }
                }

                Behavior on opacity {
                    Anim {
                        duration: Appearance.anim.durations.expressiveFastSpatial
                    }
                }
            }
        }
    }

    Column {
        id: info

        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.normal

        Item {
            id: line

            implicitWidth: icon.implicitWidth + text.width + text.anchors.leftMargin
            implicitHeight: Math.max(icon.implicitHeight, text.implicitHeight)

            ColouredIcon {
                id: icon

                anchors.left: parent.left
                anchors.leftMargin: (Config.dashboard.sizes.infoIconSize - implicitWidth) / 2

                source: SysInfo.osLogo
                implicitSize: Math.floor(Appearance.font.size.normal * 1.34)
                colour: Colours.palette.m3primary
            }

            StyledText {
                id: text

                anchors.verticalCenter: icon.verticalCenter
                anchors.left: icon.right
                anchors.leftMargin: icon.anchors.leftMargin
                text: `:  ${SysInfo.osPrettyName || SysInfo.osName}`
                font.pointSize: Appearance.font.size.normal

                width: Config.dashboard.sizes.infoWidth
                elide: Text.ElideRight
            }
        }

        InfoLine {
            icon: "select_window_2"
            text: SysInfo.wm
            colour: Colours.palette.m3secondary
        }

        InfoLine {
            id: uptime

            icon: "timer"
            text: qsTr("up %1").arg(SysInfo.uptime)
            colour: Colours.palette.m3tertiary
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
            anchors.leftMargin: (Config.dashboard.sizes.infoIconSize - implicitWidth) / 2

            fill: 1
            text: line.icon
            color: line.colour
            font.pointSize: Appearance.font.size.normal
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
