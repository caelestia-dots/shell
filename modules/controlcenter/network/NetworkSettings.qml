pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Appearance.spacing.normal

    MaterialIcon {
        Layout.alignment: Qt.AlignHCenter
        text: "wifi"
        font.pointSize: Appearance.font.size.extraLarge * 3
        font.bold: true
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: qsTr("Network settings")
        font.pointSize: Appearance.font.size.large
        font.bold: true
    }

    // WiFi Status Section
    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("WiFi status")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Enable or disable WiFi")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: wifiStatus.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        RowLayout {
            id: wifiStatus

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            spacing: Appearance.spacing.normal

            StyledText {
                Layout.fillWidth: true
                text: qsTr("WiFi enabled")
            }

            StyledSwitch {
                checked: Network.wifiEnabled
                onToggled: Network.toggleWifi()
                cLayer: 2
            }
        }
    }

    // Connected Network Section
    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Active connection")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Currently connected network")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: activeConnection.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: activeConnection

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            spacing: Appearance.spacing.larger

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: Network.active ? "wifi" : "wifi_off"
                    font.pointSize: Appearance.font.size.extraLarge
                    color: Network.active ? Colours.palette.m3primary : Colours.palette.m3outline
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.smaller

                    StyledText {
                        text: Network.active ? Network.active.ssid : qsTr("Not connected")
                        font.weight: 600
                    }

                    StyledText {
                        visible: Network.active
                        text: Network.active ? `${qsTr("Signal")}: ${Network.active.strength}%` : ""
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3outline
                    }
                }
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small
                visible: Network.active

                implicitHeight: disconnectBtn.implicitHeight + Appearance.padding.normal

                radius: Appearance.rounding.normal
                color: Colours.palette.m3errorContainer

                StateLayer {
                    color: Colours.palette.m3onErrorContainer

                    function onClicked(): void {
                        Network.disconnectFromNetwork();
                    }
                }

                RowLayout {
                    id: disconnectBtn

                    anchors.centerIn: parent
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        text: "wifi_off"
                        color: Colours.palette.m3onErrorContainer
                        font.pointSize: Appearance.font.size.large
                    }

                    StyledText {
                        text: qsTr("Disconnect")
                        color: Colours.palette.m3onErrorContainer
                        font.weight: 600
                    }
                }
            }
        }
    }

    // Network Information
    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Network information")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Details about the connection")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: networkInfo.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: networkInfo

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            spacing: Appearance.spacing.small / 2

            StyledText {
                text: qsTr("SSID")
            }

            StyledText {
                text: Network.active?.ssid ?? qsTr("Not connected")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Security")
            }

            StyledText {
                text: {
                    if (!Network.active) return qsTr("N/A");
                    return Network.active.isSecure ? Network.active.security : qsTr("Open");
                }
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Frequency")
            }

            StyledText {
                text: Network.active ? `${Network.active.frequency} MHz` : qsTr("N/A")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("BSSID")
            }

            StyledText {
                text: Network.active?.bssid ?? qsTr("N/A")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }
        }
    }
}
