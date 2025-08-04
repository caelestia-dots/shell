pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property string connectingToSsid: ""

    spacing: Appearance.spacing.small
    width: Config.bar.sizes.networkWidth

    StyledText {
        Layout.topMargin: Appearance.padding.normal
        Layout.rightMargin: Appearance.padding.small
        text: qsTr("Wifi %1").arg(Network.wifiEnabled ? "enabled" : "disabled")
        font.weight: 500
    }

    Toggle {
        label: qsTr("Enabled")
        checked: Network.wifiEnabled
        toggle.onToggled: Network.enableWifi(checked)
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.small
        Layout.rightMargin: Appearance.padding.small
        text: qsTr("%1 networks available").arg(Network.networks.length)
        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Appearance.font.size.small
    }

    Repeater {
        model: ScriptModel {
            values: [...Network.networks].sort((a, b) => {
                if (a.active !== b.active)
                    return b.active - a.active;
                return b.strength - a.strength;
            }).slice(0, 8)
        }

        RowLayout {
            id: networkItem

            required property Network.AccessPoint modelData
            readonly property bool isConnecting: root.connectingToSsid === modelData.ssid
            readonly property bool loading: networkItem.isConnecting

            Layout.fillWidth: true
            Layout.rightMargin: Appearance.padding.small
            spacing: Appearance.spacing.small

            opacity: 0
            scale: 0.7

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {}
            }

            MaterialIcon {
                text: Icons.getNetworkIcon(networkItem.modelData.strength)
                color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }

            MaterialIcon {
                visible: networkItem.modelData.isSecure
                text: "lock"
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                Layout.leftMargin: Appearance.spacing.small / 2
                Layout.rightMargin: Appearance.spacing.small / 2
                Layout.fillWidth: true
                text: networkItem.modelData.ssid
                elide: Text.ElideRight
                font.weight: networkItem.modelData.active ? 500 : 400
                color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            StyledRect {
                id: connectBtn

                implicitWidth: implicitHeight
                implicitHeight: connectIcon.implicitHeight + Appearance.padding.small

                radius: Appearance.rounding.full
                color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3surface

                StyledBusyIndicator {
                    anchors.centerIn: parent

                    implicitWidth: implicitHeight
                    implicitHeight: connectIcon.implicitHeight

                    running: opacity > 0
                    opacity: networkItem.loading ? 1 : 0

                    Behavior on opacity {
                        Anim {}
                    }
                }

                StateLayer {
                    color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    disabled: networkItem.loading || !Network.wifiEnabled

                    function onClicked(): void {
                        if (networkItem.modelData.active) {
                            Network.disconnectFromNetwork();
                        } else {
                            root.connectingToSsid = networkItem.modelData.ssid;
                            Network.connectToNetwork(networkItem.modelData.ssid, "");
                        }
                    }
                }

                MaterialIcon {
                    id: connectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: networkItem.modelData.active ? "link_off" : "link"
                    color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                    opacity: networkItem.loading ? 0 : 1

                    Behavior on opacity {
                        Anim {}
                    }
                }
            }
        }
    }

    StyledRect {
        Layout.topMargin: Appearance.spacing.small
        Layout.fillWidth: true
        implicitHeight: rescanBtn.implicitHeight + Appearance.padding.small * 2

        radius: Appearance.rounding.normal
        color: Network.scanning ? Colours.palette.m3surfaceContainer : Colours.palette.m3primaryContainer

        StateLayer {
            color: Network.scanning ? Colours.palette.m3onSurface : Colours.palette.m3onPrimaryContainer
            disabled: Network.scanning || !Network.wifiEnabled

            function onClicked(): void {
                Network.rescanWifi();
            }
        }

        RowLayout {
            id: rescanBtn
            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                id: scanIcon

                animate: true
                text: Network.scanning ? "refresh" : "wifi_find"
                color: Network.scanning ? Colours.palette.m3onSurface : Colours.palette.m3onPrimaryContainer

                RotationAnimation on rotation {
                    running: Network.scanning
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 1000
                }
            }

            StyledText {
                text: Network.scanning ? qsTr("Scanning...") : qsTr("Rescan networks")
                color: Network.scanning ? Colours.palette.m3onSurface : Colours.palette.m3onPrimaryContainer
            }
        }
    }

    // Reset connecting state when network changes
    Connections {
        target: Network

        function onActiveChanged(): void {
            if (Network.active && root.connectingToSsid === Network.active.ssid) {
                root.connectingToSsid = "";
            }
        }

        function onScanningChanged(): void {
            if (!Network.scanning)
                scanIcon.rotation = 0;
        }
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        Layout.rightMargin: Appearance.padding.small
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
