pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    anchors.fill: parent
    anchors.margins: Appearance.padding.large * 2
    anchors.topMargin: Appearance.padding.large

    spacing: Appearance.spacing.small

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: false
        spacing: Appearance.spacing.normal

        StyledRect {
            implicitWidth: prompt.implicitWidth + Appearance.padding.normal * 2
            implicitHeight: prompt.implicitHeight + Appearance.padding.normal * 2

            color: Colours.palette.m3primary
            radius: Appearance.rounding.small

            MonoText {
                id: prompt

                anchors.centerIn: parent
                text: ">"
                font.pointSize: root.width > 400 ? Appearance.font.size.larger : Appearance.font.size.normal
                color: Colours.palette.m3onPrimary
            }
        }

        MonoText {
            Layout.fillWidth: true
            text: "caelestiafetch.sh"
            font.pointSize: root.width > 400 ? Appearance.font.size.larger : Appearance.font.size.normal
            elide: Text.ElideRight
        }

        Loader {
            Layout.fillHeight: true
            asynchronous: true
            active: !iconLoader.active
            visible: active

            sourceComponent: IconImage {
                source: Quickshell.iconPath(SysInfo.logo)
                implicitSize: height
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: false
        spacing: height * 0.15

        Loader {
            id: iconLoader

            Layout.fillHeight: true

            asynchronous: true
            active: root.width > 320
            visible: active

            sourceComponent: IconImage {
                source: Quickshell.iconPath(SysInfo.logo)
                implicitSize: height
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.padding.normal
            Layout.bottomMargin: Appearance.padding.normal
            Layout.leftMargin: iconLoader.active ? 0 : width * 0.1
            spacing: Appearance.spacing.normal

            Loader {
                Layout.fillWidth: true
                asynchronous: true
                active: !batLoader.active && root.height > 200
                visible: active

                sourceComponent: FetchText {
                    text: `OS  : ${SysInfo.osPrettyName || SysInfo.osName}`
                }
            }

            Loader {
                Layout.fillWidth: true
                asynchronous: true
                active: root.height > (batLoader.active ? 200 : 110)
                visible: active

                sourceComponent: FetchText {
                    text: `WM  : ${SysInfo.wm}`
                }
            }

            FetchText {
                text: `USER: ${SysInfo.user}`
            }

            FetchText {
                text: `UP  : ${SysInfo.uptime}`
            }

            Loader {
                id: batLoader

                Layout.fillWidth: true
                asynchronous: true
                active: UPower.displayDevice.isLaptopBattery
                visible: active

                sourceComponent: FetchText {
                    text: `BATT: ${UPower.onBattery ? "" : "(+) "}${Math.round(UPower.displayDevice.percentage * 100)}%`
                }
            }
        }
    }

    Loader {
        Layout.alignment: Qt.AlignHCenter

        asynchronous: true
        active: root.height > 180
        visible: active

        sourceComponent: RowLayout {
            spacing: Appearance.spacing.large

            Repeater {
                model: Math.max(0, Math.min(8, root.width / (Appearance.font.size.larger * 2 + Appearance.spacing.large)))

                StyledRect {
                    required property int index

                    implicitWidth: implicitHeight
                    implicitHeight: Appearance.font.size.larger * 2
                    color: Colours.palette[`term${index}`]
                    radius: Appearance.rounding.small
                }
            }
        }
    }

    component FetchText: MonoText {
        Layout.fillWidth: true
        font.pointSize: root.width > 400 ? Appearance.font.size.larger : Appearance.font.size.normal
        elide: Text.ElideRight
    }

    component MonoText: StyledText {
        font.family: Appearance.font.family.mono
    }
}
