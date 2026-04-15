pragma ComponentBehavior: Bound

import ".."
import "../components"
import "."
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils

DeviceDetails {
    id: root

    required property Session session
    readonly property var network: root.session.network.active

    function checkSavedProfile(): void {
        if (network && network.ssid) {
            Nmcli.loadSavedConnections(() => {});
        }
    }

    function updateDeviceDetails(): void {
        if (network && network.ssid) {
            const isActive = network.active || (Nmcli.active && Nmcli.active.ssid === network.ssid);
            if (isActive) {
                Nmcli.getWirelessDeviceDetails("");
            } else {
                Nmcli.wirelessDeviceDetails = null;
            }
        } else {
            Nmcli.wirelessDeviceDetails = null;
        }
    }

    device: network

    Component.onCompleted: {
        updateDeviceDetails();
        checkSavedProfile();
    }

    onNetworkChanged: {
        connectionUpdateTimer.stop();
        if (network && network.ssid) {
            connectionUpdateTimer.start();
        }
        updateDeviceDetails();
        checkSavedProfile();
    }

    headerComponent: Component {
        ConnectionHeader {
            icon: root.network?.isSecure ? "lock" : "wifi"
            title: root.network?.ssid ?? qsTr("Unknown")
        }
    }

    sections: [
        Component {
            ColumnLayout {
                spacing: Tokens.spacing.normal

                SectionHeader {
                    title: qsTr("Connection status")
                    description: qsTr("Connection settings for this network")
                }

                SectionContainer {
                    ToggleRow {
                        label: qsTr("Connected")
                        checked: root.network?.active ?? false
                        toggle.onToggled: {
                            if (checked) {
                                NetworkConnection.handleConnect(root.network, root.session, null);
                            } else {
                                Nmcli.disconnectFromNetwork();
                            }
                        }
                    }

                    TextButton {
                        Layout.fillWidth: true
                        Layout.topMargin: Tokens.spacing.normal
                        Layout.minimumHeight: Tokens.font.size.normal + Tokens.padding.normal * 2
                        visible: {
                            if (!root.network || !root.network.ssid) {
                                return false;
                            }
                            return Nmcli.hasSavedProfile(root.network.ssid);
                        }
                        inactiveColour: Colours.palette.m3secondaryContainer
                        inactiveOnColour: Colours.palette.m3onSecondaryContainer
                        text: qsTr("Forget Network")

                        onClicked: {
                            if (root.network && root.network.ssid) {
                                if (root.network.active) {
                                    Nmcli.disconnectFromNetwork();
                                }
                                Nmcli.forgetNetwork(root.network.ssid);
                            }
                        }
                    }
                }
            }
        },
        Component {
            ColumnLayout {
                spacing: Tokens.spacing.normal

                SectionHeader {
                    title: qsTr("Network properties")
                    description: qsTr("Additional information")
                }

                SectionContainer {
                    contentSpacing: Tokens.spacing.small / 2

                    PropertyRow {
                        label: qsTr("SSID")
                        value: root.network?.ssid ?? qsTr("Unknown")
                    }

                    PropertyRow {
                        showTopMargin: true
                        label: qsTr("BSSID")
                        value: root.network?.bssid ?? qsTr("Unknown")
                    }

                    PropertyRow {
                        showTopMargin: true
                        label: qsTr("Signal strength")
                        value: root.network ? qsTr("%1%").arg(root.network.strength) : qsTr("N/A")
                    }

                    PropertyRow {
                        showTopMargin: true
                        label: qsTr("Frequency")
                        value: root.network ? qsTr("%1 MHz").arg(root.network.frequency) : qsTr("N/A")
                    }

                    PropertyRow {
                        showTopMargin: true
                        label: qsTr("Security")
                        value: root.network ? (root.network.isSecure ? root.network.security : qsTr("Open")) : qsTr("N/A")
                    }
                }
            }
        },
        Component {
            ColumnLayout {
                spacing: Tokens.spacing.normal

                SectionHeader {
                    title: qsTr("Connection information")
                    description: qsTr("Network connection details")
                }

                SectionContainer {
                    ConnectionInfoSection {
                        deviceDetails: Nmcli.wirelessDeviceDetails
                    }
                }
            }
        }
    ]

    Connections {
        function onActiveChanged() {
            updateDeviceDetails();
        }
        function onWirelessDeviceDetailsChanged() {
            if (network && network.ssid) {
                const isActive = network.active || (Nmcli.active && Nmcli.active.ssid === network.ssid);
                if (isActive && Nmcli.wirelessDeviceDetails && Nmcli.wirelessDeviceDetails !== null) {
                    connectionUpdateTimer.stop();
                }
            }
        }

        target: Nmcli
    }

    Timer {
        id: connectionUpdateTimer

        interval: 500
        repeat: true
        running: network && network.ssid
        onTriggered: {
            if (network) {
                const isActive = network.active || (Nmcli.active && Nmcli.active.ssid === network.ssid);
                if (isActive) {
                    if (!Nmcli.wirelessDeviceDetails || Nmcli.wirelessDeviceDetails === null) {
                        Nmcli.getWirelessDeviceDetails("", () => {});
                    } else {
                        connectionUpdateTimer.stop();
                    }
                } else {
                    if (Nmcli.wirelessDeviceDetails !== null) {
                        Nmcli.wirelessDeviceDetails = null;
                    }
                }
            }
        }
    }
}
