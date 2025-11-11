pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property var selectedNetwork: null

    spacing: Appearance.spacing.large

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Available Networks")
            font.pointSize: Appearance.font.size.large
            font.weight: 700
        }

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: scanIcon.implicitHeight + Appearance.padding.small * 2

            radius: Appearance.rounding.full
            color: Network.scanning ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHighest

            StateLayer {
                color: Network.scanning ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                disabled: Network.scanning

                function onClicked(): void {
                    Network.rescanWifi();
                }
            }

            MaterialIcon {
                id: scanIcon

                anchors.centerIn: parent
                text: "refresh"
                font.pointSize: Appearance.font.size.large
                color: Network.scanning ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

                RotationAnimator on rotation {
                    running: Network.scanning
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }
        }
    }

    Repeater {
        model: Network.networks

        NetworkCard {
            required property var modelData
            required property int index

            Layout.fillWidth: true
            network: modelData

            onClicked: {
                if (network.isSecure) {
                    root.selectedNetwork = network;
                } else {
                    Network.connectToNetwork(network.ssid, "");
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
        Layout.preferredHeight: 0
        visible: Network.networks.length === 0

        StyledText {
            anchors.centerIn: parent
            text: Network.wifiEnabled ? qsTr("No networks found") : qsTr("WiFi is disabled")
            color: Colours.palette.m3outline
            font.pointSize: Appearance.font.size.large
        }
    }

    component NetworkCard: StyledRect {
        id: card

        required property var network

        signal clicked()

        implicitHeight: cardContent.implicitHeight + Appearance.padding.large * 2
        radius: Appearance.rounding.normal
        color: network.active ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer

        StateLayer {
            color: network.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

            function onClicked(): void {
                if (!network.active)
                    card.clicked();
            }
        }

        RowLayout {
            id: cardContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: {
                    if (!Network.wifiEnabled) return "wifi_off";
                    if (network.active) return "wifi";
                    const strength = network.strength;
                    if (strength >= 75) return "network_wifi_3_bar";
                    if (strength >= 50) return "network_wifi_2_bar";
                    if (strength >= 25) return "network_wifi_1_bar";
                    return "network_wifi";
                }
                font.pointSize: Appearance.font.size.extraLarge
                color: network.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.smaller

                StyledText {
                    Layout.fillWidth: true
                    text: network.ssid
                    font.weight: network.active ? 600 : 400
                    color: network.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }

                RowLayout {
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        text: network.isSecure ? "lock" : "lock_open"
                        font.pointSize: Appearance.font.size.small
                        color: network.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                        opacity: 0.7
                    }

                    StyledText {
                        text: network.isSecure ? qsTr("Secured") : qsTr("Open")
                        font.pointSize: Appearance.font.size.small
                        color: network.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                        opacity: 0.7
                    }

                    StyledText {
                        text: "•"
                        font.pointSize: Appearance.font.size.small
                        color: network.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                        opacity: 0.7
                    }

                    StyledText {
                        text: `${network.strength}%`
                        font.pointSize: Appearance.font.size.small
                        color: network.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                        opacity: 0.7
                    }
                }
            }

            MaterialIcon {
                text: network.active ? "check_circle" : "chevron_right"
                font.pointSize: Appearance.font.size.large
                color: network.active ? Colours.palette.m3primary : Colours.palette.m3outline
            }
        }
    }

    // Password Dialog Loader
    Loader {
        id: passwordDialogLoader

        anchors.fill: parent
        active: root.selectedNetwork !== null
        sourceComponent: passwordDialog
        z: 1000
    }

    Component {
        id: passwordDialog

        PasswordDialog {
            network: root.selectedNetwork

            onAccepted: password => {
                Network.connectToNetwork(root.selectedNetwork.ssid, password);
                root.selectedNetwork = null;
            }

            onCancelled: {
                root.selectedNetwork = null;
            }
        }
    }
}
