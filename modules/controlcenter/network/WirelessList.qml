pragma ComponentBehavior: Bound

import ".."
import "."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Appearance.spacing.small

    RowLayout {
        spacing: Appearance.spacing.smaller

        StyledText {
            text: qsTr("Settings")
            font.pointSize: Appearance.font.size.large
            font.weight: 500
        }

        Item {
            Layout.fillWidth: true
        }

        ToggleButton {
            toggled: Nmcli.wifiEnabled
            icon: "wifi"
            accent: "Tertiary"

            onClicked: {
                Nmcli.toggleWifi(null);
            }
        }

        ToggleButton {
            toggled: Nmcli.scanning
            icon: "wifi_find"
            accent: "Secondary"

            onClicked: {
                Nmcli.rescanWifi();
            }
        }

        ToggleButton {
            toggled: !root.session.network.active
            icon: "settings"
            accent: "Primary"

            onClicked: {
                if (root.session.network.active)
                    root.session.network.active = null;
                else {
                    root.session.network.active = view.model.get(0)?.modelData ?? null;
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        StyledText {
            text: qsTr("Networks (%1)").arg(Nmcli.networks.length)
            font.pointSize: Appearance.font.size.large
            font.weight: 500
        }

        StyledText {
            visible: Nmcli.scanning
            text: qsTr("Scanning...")
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.small
        }
    }

    StyledText {
        text: qsTr("All available WiFi networks")
        color: Colours.palette.m3outline
    }

    StyledListView {
        id: view

        Layout.fillWidth: true
        Layout.fillHeight: true

        model: ScriptModel {
            values: [...Nmcli.networks].sort((a, b) => {
                // Put active/connected network first
                if (a.active !== b.active)
                    return b.active - a.active;
                // Then sort by signal strength
                return b.strength - a.strength;
            })
        }

        spacing: Appearance.spacing.small / 2
        clip: true

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: view
        }

        delegate: StyledRect {
            required property var modelData

            anchors.left: parent.left
            anchors.right: parent.right

            color: Qt.alpha(Colours.tPalette.m3surfaceContainer, root.session.network.active === modelData ? Colours.tPalette.m3surfaceContainer.a : 0)
            radius: Appearance.rounding.normal
            border.width: root.session.network.active === modelData ? 1 : 0
            border.color: Colours.palette.m3primary

            StateLayer {
                function onClicked(): void {
                    root.session.network.active = modelData;
                    // Check if we need to refresh saved connections when selecting a network
                    if (modelData && modelData.ssid) {
                        root.checkSavedProfileForNetwork(modelData.ssid);
                    }
                }
            }

            RowLayout {
                id: rowLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Appearance.padding.normal

                spacing: Appearance.spacing.normal

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: icon.implicitHeight + Appearance.padding.normal * 2

                    radius: Appearance.rounding.normal
                    color: modelData.active ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                    MaterialIcon {
                        id: icon

                        anchors.centerIn: parent
                        text: modelData.isSecure ? "lock" : "wifi"
                        font.pointSize: Appearance.font.size.large
                        fill: modelData.active ? 1 : 0
                        color: modelData.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    maximumLineCount: 1

                    text: modelData.ssid || qsTr("Unknown")
                }

                StyledText {
                    text: modelData.active ? qsTr("Connected") : (modelData.isSecure ? qsTr("Secured") : qsTr("Open"))
                    color: modelData.active ? Colours.palette.m3primary : Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                    font.weight: modelData.active ? 500 : 400
                }

                StyledText {
                    text: qsTr("%1%").arg(modelData.strength)
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                }

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: connectIcon.implicitHeight + Appearance.padding.smaller * 2

                    radius: Appearance.rounding.full
                    color: Qt.alpha(Colours.palette.m3primaryContainer, modelData.active ? 1 : 0)

                    StateLayer {
                        function onClicked(): void {
                            if (modelData.active) {
                                Nmcli.disconnectFromNetwork();
                            } else {
                                handleConnect(modelData);
                            }
                        }
                    }

                    MaterialIcon {
                        id: connectIcon

                        anchors.centerIn: parent
                        text: modelData.active ? "link_off" : "link"
                        color: modelData.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    }
                }
            }

            implicitHeight: rowLayout.implicitHeight + Appearance.padding.normal * 2
        }
    }

    function checkSavedProfileForNetwork(ssid: string): void {
        if (ssid && ssid.length > 0) {
            Nmcli.loadSavedConnections(() => {});
        }
    }

    function handleConnect(network): void {
        if (Nmcli.active && Nmcli.active.ssid !== network.ssid) {
            Nmcli.disconnectFromNetwork();
            Qt.callLater(() => {
                connectToNetwork(network);
            });
        } else {
            connectToNetwork(network);
        }
    }

    function connectToNetwork(network): void {
        if (network.isSecure) {
            const hasSavedProfile = Nmcli.hasSavedProfile(network.ssid);

            if (hasSavedProfile) {
                Nmcli.connectToNetwork(network.ssid, "", network.bssid, null);
            } else {
                Nmcli.connectToNetworkWithPasswordCheck(
                    network.ssid,
                    network.isSecure,
                    (result) => {
                        if (result.needsPassword) {
                            if (Nmcli.pendingConnection) {
                                Nmcli.connectionCheckTimer.stop();
                                Nmcli.immediateCheckTimer.stop();
                                Nmcli.immediateCheckTimer.checkCount = 0;
                                Nmcli.pendingConnection = null;
                            }
                            root.session.network.showPasswordDialog = true;
                            root.session.network.pendingNetwork = network;
                        }
                    },
                    network.bssid
                );
            }
        } else {
            Nmcli.connectToNetwork(network.ssid, "", network.bssid, null);
        }
    }
}