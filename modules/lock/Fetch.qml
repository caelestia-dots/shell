pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

ColumnLayout {
    id: root

    anchors.fill: parent
    anchors.margins: Tokens.padding.large * 2
    anchors.topMargin: Tokens.padding.large

    spacing: Tokens.spacing.small

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: false
        spacing: Tokens.spacing.normal

        StyledRect {
            implicitWidth: prompt.implicitWidth + Tokens.padding.normal * 2
            implicitHeight: prompt.implicitHeight + Tokens.padding.normal * 2

            color: Colours.palette.m3primary
            radius: Tokens.rounding.small

            MonoText {
                id: prompt

                anchors.centerIn: parent
                text: ">"
                font.pointSize: root.width > 400 ? Tokens.font.size.larger : Tokens.font.size.normal
                color: Colours.palette.m3onPrimary
            }
        }

        MonoText {
            Layout.fillWidth: true
            text: "caelestiafetch.sh"
            font.pointSize: root.width > 400 ? Tokens.font.size.larger : Tokens.font.size.normal
            elide: Text.ElideRight
        }

        WrappedLoader {
            Layout.fillHeight: true
            active: !iconLoader.active

            sourceComponent: SysInfo.isDefaultLogo ? caelestiaLogo : distroIcon
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: false
        spacing: height * 0.15

        WrappedLoader {
            id: iconLoader

            Layout.fillHeight: true
            active: root.width > 320

            sourceComponent: SysInfo.isDefaultLogo ? caelestiaLogo : distroIcon
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.normal
            Layout.bottomMargin: Tokens.padding.normal
            Layout.leftMargin: iconLoader.active ? 0 : width * 0.1
            spacing: Tokens.spacing.normal

            WrappedLoader {
                Layout.fillWidth: true
                active: !batLoader.active && root.height > 200

                sourceComponent: FetchText {
                    text: `OS  : ${SysInfo.osPrettyName || SysInfo.osName}`
                }
            }

            WrappedLoader {
                Layout.fillWidth: true
                active: root.height > (batLoader.active ? 200 : 110)

                sourceComponent: FetchText {
                    text: `WM  : ${SysInfo.wm}`
                }
            }

            WrappedLoader {
                Layout.fillWidth: true
                active: !batLoader.active || root.height > 110

                sourceComponent: FetchText {
                    text: `USER: ${SysInfo.user}`
                }
            }

            FetchText {
                text: `UP  : ${SysInfo.uptime}`
            }

            WrappedLoader {
                id: batLoader

                Layout.fillWidth: true
                active: UPower.displayDevice.isLaptopBattery

                sourceComponent: FetchText {
                    text: `BATT: ${[UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state) ? "(+) " : ""}${Math.round(UPower.displayDevice.percentage * 100)}%`
                }
            }
        }
    }

    WrappedLoader {
        Layout.alignment: Qt.AlignHCenter
        active: root.height > 180

        sourceComponent: RowLayout {
            spacing: Tokens.spacing.large

            Repeater {
                model: Math.max(0, Math.min(8, root.width / (Tokens.font.size.larger * 2 + Tokens.spacing.large)))

                StyledRect {
                    required property int index

                    implicitWidth: implicitHeight
                    implicitHeight: Tokens.font.size.larger * 2
                    color: Colours.palette[`term${index}`]
                    radius: Tokens.rounding.small
                }
            }
        }
    }

    Component {
        id: caelestiaLogo

        Logo {
            width: height
        }
    }

    Component {
        id: distroIcon

        ColouredIcon {
            source: SysInfo.osLogo
            implicitSize: height
            colour: Colours.palette.m3primary
            layer.enabled: Config.lock.recolourLogo
        }
    }

    component WrappedLoader: Loader {
        asynchronous: true
        visible: active
    }

    component FetchText: MonoText {
        Layout.fillWidth: true
        font.pointSize: root.width > 400 ? Tokens.font.size.larger : Tokens.font.size.normal
        elide: Text.ElideRight
    }

    component MonoText: StyledText {
        font.family: Tokens.font.family.mono
    }
}
