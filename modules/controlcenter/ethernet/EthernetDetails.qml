pragma ComponentBehavior: Bound

import ".."
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
    readonly property var device: session.ethernet.active

    Component.onCompleted: {
        if (device && device.interface) {
            Nmcli.getEthernetDeviceDetails(device.interface, () => {});
        }
    }

    onDeviceChanged: {
        if (device && device.interface) {
            Nmcli.getEthernetDeviceDetails(device.interface, () => {});
        } else {
            Nmcli.ethernetDeviceDetails = null;
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
                icon: "cable"
                title: root.device?.interface ?? qsTr("Unknown")
            }

            SectionHeader {
                title: qsTr("Connection status")
                description: qsTr("Connection settings for this device")
            }

            SectionContainer {
                ToggleRow {
                    label: qsTr("Connected")
                    checked: root.device?.connected ?? false
                    toggle.onToggled: {
                        if (checked) {
                            Nmcli.connectEthernet(root.device?.connection || "", root.device?.interface || "", () => {});
                        } else {
                            if (root.device?.connection) {
                                Nmcli.disconnectEthernet(root.device.connection, () => {});
                            }
                        }
                    }
                }
            }

            SectionHeader {
                title: qsTr("Device properties")
                description: qsTr("Additional information")
            }

            SectionContainer {
                contentSpacing: Appearance.spacing.small / 2

                PropertyRow {
                    label: qsTr("Interface")
                    value: root.device?.interface ?? qsTr("Unknown")
                }

                PropertyRow {
                    showTopMargin: true
                    label: qsTr("Connection")
                    value: root.device?.connection || qsTr("Not connected")
                }

                PropertyRow {
                    showTopMargin: true
                    label: qsTr("State")
                    value: root.device?.state ?? qsTr("Unknown")
                }
            }

            SectionHeader {
                title: qsTr("Connection information")
                description: qsTr("Network connection details")
            }

            SectionContainer {
                ConnectionInfoSection {
                    deviceDetails: Nmcli.ethernetDeviceDetails
                }
            }

        }
    }

}