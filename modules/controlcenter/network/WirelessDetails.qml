pragma ComponentBehavior: Bound

import ".."
import "."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session
    readonly property var network: session.network.active

    Component.onCompleted: {
        updateDeviceDetails();
        checkSavedProfile();
    }

    onNetworkChanged: {
        // Restart timer when network changes
        connectionUpdateTimer.stop();
        if (network && network.ssid) {
            connectionUpdateTimer.start();
        }
        updateDeviceDetails();
        checkSavedProfile();
    }

    function checkSavedProfile(): void {
        if (network && network.ssid) {
            Nmcli.loadSavedConnections(() => {});
        }
    }

    Connections {
        target: Nmcli
        function onActiveChanged() {
            updateDeviceDetails();
        }
        function onWirelessDeviceDetailsChanged() {
            // When details are updated, check if we should stop the timer
            if (network && network.ssid) {
                const isActive = network.active || (Nmcli.active && Nmcli.active.ssid === network.ssid);
                if (isActive && Nmcli.wirelessDeviceDetails && Nmcli.wirelessDeviceDetails !== null) {
                    // We have details for the active network, stop the timer
                    connectionUpdateTimer.stop();
                }
            }
        }
    }

    Timer {
        id: connectionUpdateTimer
        interval: 500
        repeat: true
        running: network && network.ssid
        onTriggered: {
            // Periodically check if network becomes active and update details
            if (network) {
                const isActive = network.active || (Nmcli.active && Nmcli.active.ssid === network.ssid);
                if (isActive) {
                    // Network is active - check if we have details
                    if (!Nmcli.wirelessDeviceDetails || Nmcli.wirelessDeviceDetails === null) {
                        // Network is active but we don't have details yet, fetch them
                        Nmcli.getWirelessDeviceDetails("", () => {
                        // After fetching, check if we got details - if not, timer will try again
                        });
                    } else {
                        // We have details, can stop the timer
                        connectionUpdateTimer.stop();
                    }
                } else {
                    // Network is not active, clear details
                    if (Nmcli.wirelessDeviceDetails !== null) {
                        Nmcli.wirelessDeviceDetails = null;
                    }
                }
            }
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

    StyledFlickable {
        id: flickable

        anchors.fill: parent

        flickableDirection: Flickable.VerticalFlick
        clip: true
        contentHeight: layout.height

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: flickable
        }

        ColumnLayout {
            id: layout

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.normal

            ConnectionHeader {
                icon: root.network?.isSecure ? "lock" : "wifi"
                title: root.network?.ssid ?? qsTr("Unknown")
            }

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
                            root.handleConnect();
                        } else {
                            Nmcli.disconnectFromNetwork();
                        }
                    }
                }

                TextButton {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.normal
                    Layout.minimumHeight: Appearance.font.size.normal + Appearance.padding.normal * 2
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

            SectionHeader {
                title: qsTr("Network properties")
                description: qsTr("Additional information")
            }

            SectionContainer {
                contentSpacing: Appearance.spacing.small / 2

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

    function handleConnect(): void {
        if (Nmcli.active && Nmcli.active.ssid !== root.network.ssid) {
            Nmcli.disconnectFromNetwork();
            Qt.callLater(() => {
                connectToNetwork();
            });
        } else {
            connectToNetwork();
        }
    }

    function connectToNetwork(): void {
        if (root.network.isSecure) {
            const hasSavedProfile = Nmcli.hasSavedProfile(root.network.ssid);

            if (hasSavedProfile) {
                Nmcli.connectToNetwork(root.network.ssid, "", root.network.bssid, null);
            } else {
                Nmcli.connectToNetworkWithPasswordCheck(root.network.ssid, root.network.isSecure, result => {
                    if (result.needsPassword) {
                        if (Nmcli.pendingConnection) {
                            Nmcli.connectionCheckTimer.stop();
                            Nmcli.immediateCheckTimer.stop();
                            Nmcli.immediateCheckTimer.checkCount = 0;
                            Nmcli.pendingConnection = null;
                        }
                        root.session.network.showPasswordDialog = true;
                        root.session.network.pendingNetwork = root.network;
                    }
                }, root.network.bssid);
            }
        } else {
            Nmcli.connectToNetwork(root.network.ssid, "", root.network.bssid, null);
        }
    }
}
