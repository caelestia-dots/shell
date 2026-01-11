pragma ComponentBehavior: Bound

import ".."
import "../components"
import "."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session

    anchors.fill: parent

    SplitPaneLayout {
        id: splitLayout

        anchors.fill: parent

        leftContent: Component {
            StyledFlickable {
                id: leftFlickable

                flickableDirection: Flickable.VerticalFlick
                contentHeight: leftContent.height

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: leftFlickable
                }

                ColumnLayout {
                    id: leftContent

                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Appearance.spacing.normal

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.smaller

                        StyledText {
                            text: qsTr("Network")
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
                            iconSize: Appearance.font.size.normal
                            horizontalPadding: Appearance.padding.normal
                            verticalPadding: Appearance.padding.smaller
                            tooltip: qsTr("Toggle WiFi")

                            onClicked: {
                                Nmcli.toggleWifi(null);
                            }
                        }

                        ToggleButton {
                            toggled: Nmcli.scanning
                            icon: "wifi_find"
                            accent: "Secondary"
                            iconSize: Appearance.font.size.normal
                            horizontalPadding: Appearance.padding.normal
                            verticalPadding: Appearance.padding.smaller
                            tooltip: qsTr("Scan for networks")

                            onClicked: {
                                Nmcli.rescanWifi();
                            }
                        }

                        ToggleButton {
                            toggled: !root.session.ethernet.active && !root.session.network.active
                            icon: "settings"
                            accent: "Primary"
                            iconSize: Appearance.font.size.normal
                            horizontalPadding: Appearance.padding.normal
                            verticalPadding: Appearance.padding.smaller
                            tooltip: qsTr("Network settings")

                            onClicked: {
                                if (root.session.ethernet.active || root.session.network.active) {
                                    root.session.ethernet.active = null;
                                    root.session.network.active = null;
                                } else {
                                    if (Nmcli.ethernetDevices.length > 0) {
                                        root.session.ethernet.active = Nmcli.ethernetDevices[0];
                                    } else if (Nmcli.networks.length > 0) {
                                        root.session.network.active = Nmcli.networks[0];
                                    }
                                }
                            }
                        }
                    }

                    CollapsibleSection {
                        id: ethernetListSection

                        Layout.fillWidth: true
                        title: qsTr("Ethernet")
                        expanded: true

                        Loader {
                            Layout.fillWidth: true
                            sourceComponent: Component {
                                EthernetList {
                                    session: root.session
                                    showHeader: false
                                }
                            }
                        }
                    }

                    CollapsibleSection {
                        id: wirelessListSection

                        Layout.fillWidth: true
                        title: qsTr("Wireless")
                        expanded: true

                        Loader {
                            Layout.fillWidth: true
                            sourceComponent: Component {
                                WirelessList {
                                    session: root.session
                                    showHeader: false
                                }
                            }
                        }
                    }
                }
            }
        }

        rightContent: Component {
            Item {
                id: rightPaneItem
                
                property var ethernetPane: root.session.ethernet.active
                property var wirelessPane: root.session.network.active
                property var pane: ethernetPane || wirelessPane
                property string paneId: ethernetPane ? ("eth:" + (ethernetPane.interface || "")) : (wirelessPane ? ("wifi:" + (wirelessPane.ssid || wirelessPane.bssid || "")) : "settings")
                property Component targetComponent: settingsComponent
                property Component nextComponent: settingsComponent

                function getComponentForPane() {
                    if (ethernetPane) return ethernetDetailsComponent;
                    if (wirelessPane) return wirelessDetailsComponent;
                    return settingsComponent;
                }

                Component.onCompleted: {
                    targetComponent = getComponentForPane();
                    nextComponent = targetComponent;
                }

                Connections {
                    target: root.session.ethernet
                    function onActiveChanged() {
                        // Clear wireless when ethernet is selected
                        if (root.session.ethernet.active && root.session.network.active) {
                            root.session.network.active = null;
                            return; // Let the network.onActiveChanged handle the update
                        }
                        rightPaneItem.nextComponent = rightPaneItem.getComponentForPane();
                        // paneId will automatically update via property binding
                    }
                }

                Connections {
                    target: root.session.network
                    function onActiveChanged() {
                        // Clear ethernet when wireless is selected
                        if (root.session.network.active && root.session.ethernet.active) {
                            root.session.ethernet.active = null;
                            return; // Let the ethernet.onActiveChanged handle the update
                        }
                        rightPaneItem.nextComponent = rightPaneItem.getComponentForPane();
                        // paneId will automatically update via property binding
                    }
                }

                Loader {
                    id: rightLoader

                    anchors.fill: parent

                    opacity: 1
                    scale: 1
                    transformOrigin: Item.Center
                    clip: false

                    asynchronous: true
                    sourceComponent: rightPaneItem.targetComponent
                }

                Behavior on paneId {
                    PaneTransition {
                        target: rightLoader
                        propertyActions: [
                            PropertyAction {
                                target: rightPaneItem
                                property: "targetComponent"
                                value: rightPaneItem.nextComponent
                            }
                        ]
                    }
                }
            }
        }
    }

    Component {
        id: settingsComponent

        StyledFlickable {
            id: settingsFlickable
            flickableDirection: Flickable.VerticalFlick
            contentHeight: settingsInner.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: settingsFlickable
            }

            NetworkSettings {
                id: settingsInner

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                session: root.session
            }
        }
    }

    Component {
        id: ethernetDetailsComponent

        StyledFlickable {
            id: ethernetFlickable
            flickableDirection: Flickable.VerticalFlick
            contentHeight: ethernetDetailsInner.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: ethernetFlickable
            }

            EthernetDetails {
                id: ethernetDetailsInner

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                session: root.session
            }
        }
    }

    Component {
        id: wirelessDetailsComponent

        StyledFlickable {
            id: wirelessFlickable
            flickableDirection: Flickable.VerticalFlick
            contentHeight: wirelessDetailsInner.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: wirelessFlickable
            }

            WirelessDetails {
                id: wirelessDetailsInner

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                session: root.session
            }
        }
    }

    WirelessPasswordDialog {
        anchors.fill: parent
        session: root.session
        z: 1000
    }
}
