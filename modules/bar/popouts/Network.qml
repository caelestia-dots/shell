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

        ColumnLayout {
            id: networkItem
            
            required property Network.AccessPoint modelData
            readonly property bool isConnecting: root.connectingToSsid === modelData.ssid
            
            RowLayout {
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
                    color: Qt.alpha(Colours.palette.m3primary, networkItem.modelData.active ? 1 : 0)

                    CircularIndicator {
                        anchors.fill: parent
                        running: networkItem.isConnecting
                    }

                    StateLayer {
                        color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        disabled: networkItem.isConnecting || !Network.wifiEnabled

                        function onClicked(): void {
                            if (networkItem.modelData.active) {
                                Network.disconnectFromNetwork();
                            } else {
                                root.connectingToSsid = networkItem.modelData.ssid;
                                Network.connectToNetwork(root.connectingToSsid);
                            }
                        }
                    }

                    MaterialIcon {
                        id: connectIcon

                        anchors.centerIn: parent
                        animate: true
                        text: networkItem.modelData.active ? "link_off" : "link"
                        color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                        opacity: networkItem.isConnecting ? 0 : 1

                        Behavior on opacity {
                            Anim {}
                        }
                    }
                }
            }

            StyledRect {
                id: askWifiPassword
                visible: networkItem.isConnecting && Network.isconnectionFailed

                Layout.rightMargin: Appearance.padding.small
                Layout.fillWidth: true
                implicitHeight: confirmPswdIcon.implicitHeight + Appearance.padding.small*2

                color: Colours.palette.m3onSecondary;
                radius: Appearance.rounding.large

                RowLayout {
                    anchors.fill: askWifiPassword
                    spacing: Appearance.spacing.small

                    opacity: 0
                    scale: 0.7
                    
                    Component.onCompleted: {
                        opacity = 1;
                        scale = 1;
                    }

                    StyledRect {
                        id: hidePswdBtn
                        property bool isclicked: false;

                        Layout.leftMargin: Appearance.padding.small/2
                        implicitWidth: implicitHeight
                        implicitHeight: hidePswdIcon.implicitHeight + Appearance.padding.small

                        radius: Appearance.rounding.full
                        color: Qt.alpha(Colours.palette.m3primary, hidePswdBtn.isclicked ? 1 : 0)

                        StateLayer {
                            disabled: false

                            function onClicked(): void {
                                hidePswdBtn.isclicked = !hidePswdBtn.isclicked;
                            }
                        }

                        MaterialIcon {
                            id: hidePswdIcon

                            anchors.centerIn: parent
                            animate: true
                            text: hidePswdBtn.isclicked ? "visibility_off" : "visibility"
                            color: askWifiPassword.visible && hidePswdBtn.isclicked ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        }
                    }

                    StyledTextField {
                        id: wifiPasswordField
                        Layout.leftMargin: Appearance.spacing.small / 2
                        Layout.rightMargin: Appearance.spacing.small / 2
                        Layout.fillWidth: true
                        placeholderText: "Enter Password"
                        passwordMaskDelay: 300
                        echoMode: hidePswdBtn.isclicked ? TextInput.Normal : TextInput.Password   // hides characters
                        selectByMouse: true             // allow mouse text selection
                        mouseSelectionMode: TextInput.SelectCharacters
                        focus: true
                        onActiveFocusChanged: {
                            if (!activeFocus)
                                forceActiveFocus();
                        }
                    }

                    StyledRect {
                        id: confirmPswdBtn
                        property bool isclicked: false;

                        implicitWidth: implicitHeight
                        implicitHeight: confirmPswdIcon.implicitHeight + Appearance.padding.small

                        radius: Appearance.rounding.full
                        color: Qt.alpha(Colours.palette.m3primary, confirmPswdBtn.isclicked ? 1 : 0)

                        StateLayer {
                            disabled: false

                            function onClicked(): void {
                                confirmPswdBtn.isclicked = true;
                                Network.connectToSecureNetwork(root.connectingToSsid, wifiPasswordField.text);
                                confirmwaitTimer.start();
                            }
                        }

                        MaterialIcon {
                            id: confirmPswdIcon

                            anchors.centerIn: parent
                            animate: true
                            text: "check"
                            color: askWifiPassword.visible && confirmPswdBtn.isclicked ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        }

                        Timer {
                            id: confirmwaitTimer
                            interval: 100
                            repeat: false
                            onTriggered: {
                                confirmPswdBtn.isclicked = false;
                            }
                        }
                    }

                    StyledRect {
                        id: cancelPswdBtn
                        property bool isclicked: false

                        Layout.rightMargin: Appearance.spacing.small / 2
                        implicitWidth: implicitHeight
                        implicitHeight: cancelPswdIcon.implicitHeight + Appearance.padding.small

                        radius: Appearance.rounding.full
                        color: Qt.alpha(Colours.palette.m3primary, cancelPswdBtn.isclicked ? 1 : 0)

                        StateLayer {
                            disabled: false

                            function onClicked(): void {
                                cancelPswdBtn.isclicked = true;
                                cancelwaitTimer.start();
                            }
                        }

                        MaterialIcon {
                            id: cancelPswdIcon

                            anchors.centerIn: parent
                            animate: true
                            text: "close"  
                            color: askWifiPassword.visible && cancelPswdBtn.isclicked ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        }

                        Timer {
                            id: cancelwaitTimer
                            interval: 100
                            repeat: false
                            onTriggered: {
                                cancelPswdBtn.isclicked = false;
                                Network.isconnectionFailed = false;
                                root.connectingToSsid = "";
                            }
                        }
                    }
                }

                onVisibleChanged : {
                    if (!visible) {
                        hidePswdBtn.isclicked = false;
                    }
                }
            }
        }


        
    }

    StyledRect {
        Layout.topMargin: Appearance.spacing.small
        Layout.fillWidth: true
        implicitHeight: rescanBtn.implicitHeight + Appearance.padding.small * 2

        radius: Appearance.rounding.full
        color: Colours.palette.m3primaryContainer

        StateLayer {
            color: Colours.palette.m3onPrimaryContainer
            disabled: Network.scanning || !Network.wifiEnabled

            function onClicked(): void {
                Network.rescanWifi();
            }
        }

        RowLayout {
            id: rescanBtn

            anchors.centerIn: parent
            spacing: Appearance.spacing.small
            opacity: Network.scanning ? 0 : 1

            MaterialIcon {
                id: scanIcon

                animate: true
                text: "wifi_find"
                color: Colours.palette.m3onPrimaryContainer
            }

            StyledText {
                text: qsTr("Rescan networks")
                color: Colours.palette.m3onPrimaryContainer
            }

            Behavior on opacity {
                Anim {}
            }
        }

        CircularIndicator {
            anchors.centerIn: parent
            strokeWidth: Appearance.padding.small / 2
            bgColour: "transparent"
            implicitHeight: parent.implicitHeight - Appearance.padding.smaller * 2
            running: Network.scanning
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
}
