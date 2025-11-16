pragma ComponentBehavior: Bound

import ".."
import "../ethernet"
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

    RowLayout {
        id: contentLayout

        anchors.fill: parent
        spacing: 0

        Item {
            id: leftNetworkItem
            Layout.preferredWidth: Math.floor(parent.width * 0.4)
            Layout.minimumWidth: 420
            Layout.fillHeight: true

            ClippingRectangle {
                id: leftNetworkClippingRect
                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                anchors.leftMargin: 0
                anchors.rightMargin: Appearance.padding.normal / 2

                radius: leftNetworkBorder.innerRadius
                color: "transparent"

                Loader {
                    id: leftNetworkLoader

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large + Appearance.padding.normal
                    anchors.leftMargin: Appearance.padding.large
                    anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2

                    asynchronous: true
                    sourceComponent: networkListComponent
                }
            }

            InnerBorder {
                id: leftNetworkBorder
                leftThickness: 0
                rightThickness: Appearance.padding.normal / 2
            }

            Component {
                id: networkListComponent

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

                    // Settings header above the collapsible sections
                    RowLayout {
                        Layout.fillWidth: true
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
                            toggled: !root.session.ethernet.active && !root.session.network.active
                            icon: "settings"
                            accent: "Primary"

                            onClicked: {
                                if (root.session.ethernet.active || root.session.network.active) {
                                    root.session.ethernet.active = null;
                                    root.session.network.active = null;
                                } else {
                                    // Toggle to show settings - prefer ethernet if available, otherwise wireless
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

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.small

                                StyledText {
                                    text: qsTr("Devices (%1)").arg(Nmcli.ethernetDevices.length)
                                    font.pointSize: Appearance.font.size.normal
                                    font.weight: 500
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: qsTr("All available ethernet devices")
                                color: Colours.palette.m3outline
                            }

                            Repeater {
                                id: ethernetRepeater

                                Layout.fillWidth: true
                                model: Nmcli.ethernetDevices

                                delegate: StyledRect {
                                    required property var modelData

                                    Layout.fillWidth: true

                                    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, root.session.ethernet.active === modelData ? Colours.tPalette.m3surfaceContainer.a : 0)
                                    radius: Appearance.rounding.normal

                                    StateLayer {
                                        function onClicked(): void {
                                            root.session.network.active = null;
                                            root.session.ethernet.active = modelData;
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
                                            color: modelData.connected ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                                            MaterialIcon {
                                                id: icon

                                                anchors.centerIn: parent
                                                text: "cable"
                                                font.pointSize: Appearance.font.size.large
                                                fill: modelData.connected ? 1 : 0
                                                color: modelData.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                            }
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                            maximumLineCount: 1

                                            text: modelData.interface || qsTr("Unknown")
                                        }

                                        StyledText {
                                            text: modelData.connected ? qsTr("Connected") : qsTr("Disconnected")
                                            color: modelData.connected ? Colours.palette.m3primary : Colours.palette.m3outline
                                            font.pointSize: Appearance.font.size.small
                                            font.weight: modelData.connected ? 500 : 400
                                        }

                                        StyledRect {
                                            implicitWidth: implicitHeight
                                            implicitHeight: connectIcon.implicitHeight + Appearance.padding.smaller * 2

                                            radius: Appearance.rounding.full
                                            color: Qt.alpha(Colours.palette.m3primaryContainer, modelData.connected ? 1 : 0)

                                            StateLayer {
                                                function onClicked(): void {
                                                    if (modelData.connected && modelData.connection) {
                                                        Nmcli.disconnectEthernet(modelData.connection, () => {});
                                                    } else {
                                                        Nmcli.connectEthernet(modelData.connection || "", modelData.interface || "", () => {});
                                                    }
                                                }
                                            }

                                            MaterialIcon {
                                                id: connectIcon

                                                anchors.centerIn: parent
                                                text: modelData.connected ? "link_off" : "link"
                                                color: modelData.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                            }
                                        }
                                    }

                                    implicitHeight: rowLayout.implicitHeight + Appearance.padding.normal * 2
                                }
                            }
                        }
                    }

                    CollapsibleSection {
                        id: wirelessListSection

                        Layout.fillWidth: true
                        title: qsTr("Wireless")
                        expanded: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.small

                                StyledText {
                                    text: qsTr("Networks (%1)").arg(Nmcli.networks.length)
                                    font.pointSize: Appearance.font.size.normal
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
                                Layout.fillWidth: true
                                text: qsTr("All available WiFi networks")
                                color: Colours.palette.m3outline
                            }

                            Repeater {
                                id: wirelessRepeater

                                Layout.fillWidth: true
                                model: ScriptModel {
                                    values: [...Nmcli.networks].sort((a, b) => {
                                        // Put active/connected network first
                                        if (a.active !== b.active)
                                            return b.active - a.active;
                                        // Then sort by signal strength
                                        return b.strength - a.strength;
                                    })
                                }

                                delegate: StyledRect {
                                    required property var modelData

                                    Layout.fillWidth: true

                                    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (modelData && root.session.network.active === modelData) ? Colours.tPalette.m3surfaceContainer.a : 0)
                                    radius: Appearance.rounding.normal

                                    StateLayer {
                                        function onClicked(): void {
                                            if (!modelData) {
                                                return;
                                            }
                                            root.session.ethernet.active = null;
                                            root.session.network.active = modelData;
                                            // Check if we need to refresh saved connections when selecting a network
                                            if (modelData.ssid) {
                                                checkSavedProfileForNetwork(modelData.ssid);
                                            }
                                        }
                                    }

                                    RowLayout {
                                        id: wirelessRowLayout

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.margins: Appearance.padding.normal

                                        spacing: Appearance.spacing.normal

                                        StyledRect {
                                            implicitWidth: implicitHeight
                                            implicitHeight: wirelessIcon.implicitHeight + Appearance.padding.normal * 2

                                            radius: Appearance.rounding.normal
                                            color: (modelData && modelData.active) ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                                            MaterialIcon {
                                                id: wirelessIcon

                                                anchors.centerIn: parent
                                                text: Icons.getNetworkIcon(modelData && modelData.strength !== undefined ? modelData.strength : 0)
                                                font.pointSize: Appearance.font.size.large
                                                fill: (modelData && modelData.active) ? 1 : 0
                                                color: (modelData && modelData.active) ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                            }
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                            maximumLineCount: 1

                                            text: (modelData && modelData.ssid) ? modelData.ssid : qsTr("Unknown")
                                        }

                                        StyledText {
                                            text: (modelData && modelData.active) ? qsTr("Connected") : ((modelData && modelData.isSecure) ? qsTr("Secured") : qsTr("Open"))
                                            color: (modelData && modelData.active) ? Colours.palette.m3primary : Colours.palette.m3outline
                                            font.pointSize: Appearance.font.size.small
                                            font.weight: (modelData && modelData.active) ? 500 : 400
                                        }

                                        StyledRect {
                                            implicitWidth: implicitHeight
                                            implicitHeight: wirelessConnectIcon.implicitHeight + Appearance.padding.smaller * 2

                                            radius: Appearance.rounding.full
                                            color: Qt.alpha(Colours.palette.m3primaryContainer, (modelData && modelData.active) ? 1 : 0)

                                            StateLayer {
                                                function onClicked(): void {
                                                    if (modelData && modelData.active) {
                                                        Nmcli.disconnectFromNetwork();
                                                    } else if (modelData) {
                                                        handleWirelessConnect(modelData);
                                                    }
                                                }
                                            }

                                            MaterialIcon {
                                                id: wirelessConnectIcon

                                                anchors.centerIn: parent
                                                text: (modelData && modelData.active) ? "link_off" : "link"
                                                color: (modelData && modelData.active) ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                            }
                                        }
                                    }

                                    implicitHeight: wirelessRowLayout.implicitHeight + Appearance.padding.normal * 2
                                }
                            }
                        }
                    }
                }
            }
            }
        }

        Item {
            id: rightNetworkItem
            Layout.fillWidth: true
            Layout.fillHeight: true

            ClippingRectangle {
                id: networkClippingRect
                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                anchors.leftMargin: 0
                anchors.rightMargin: Appearance.padding.normal / 2

                radius: rightBorder.innerRadius
                color: "transparent"

                // Right pane - networking details/settings
                Loader {
                    id: loader

                    property var ethernetPane: root.session.ethernet.active
                    property var wirelessPane: root.session.network.active
                    property var pane: ethernetPane || wirelessPane
                    property string paneId: ethernetPane ? (ethernetPane.interface || "") : (wirelessPane ? (wirelessPane.ssid || wirelessPane.bssid || "") : "")

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large * 2

                    opacity: 1
                    scale: 1
                    transformOrigin: Item.Center

                    asynchronous: true
                    sourceComponent: pane ? (ethernetPane ? ethernetDetails : wirelessDetails) : settings

                    Behavior on paneId {
                        SequentialAnimation {
                            ParallelAnimation {
                                Anim {
                                    target: loader
                                    property: "opacity"
                                    to: 0
                                    easing.bezierCurve: Appearance.anim.curves.standardAccel
                                }
                                Anim {
                                    target: loader
                                    property: "scale"
                                    to: 0.8
                                    easing.bezierCurve: Appearance.anim.curves.standardAccel
                                }
                            }
                            PropertyAction {}
                            ParallelAnimation {
                                Anim {
                                    target: loader
                                    property: "opacity"
                                    to: 1
                                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                                }
                                Anim {
                                    target: loader
                                    property: "scale"
                                    to: 1
                                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                                }
                            }
                        }
                    }

                    onPaneChanged: {
                        paneId = ethernetPane ? (ethernetPane.interface || "") : (wirelessPane ? (wirelessPane.ssid || wirelessPane.bssid || "") : "");
                    }
                }
            }

            InnerBorder {
                id: rightBorder

                leftThickness: Appearance.padding.normal / 2
            }

            Component {
                id: settings

                StyledFlickable {
                    flickableDirection: Flickable.VerticalFlick
                    contentHeight: settingsInner.height

                    NetworkSettings {
                        id: settingsInner

                        anchors.left: parent.left
                        anchors.right: parent.right
                        session: root.session
                    }
                }
            }

            Component {
                id: ethernetDetails

                EthernetDetails {
                    session: root.session
                }
            }

            Component {
                id: wirelessDetails

                WirelessDetails {
                    session: root.session
                }
            }
        }
    }

    WirelessPasswordDialog {
        anchors.fill: parent
        session: root.session
        z: 1000
    }

    component Anim: NumberAnimation {
        target: loader
        duration: Appearance.anim.durations.normal / 2
        easing.type: Easing.BezierSpline
    }

    function checkSavedProfileForNetwork(ssid: string): void {
        if (ssid && ssid.length > 0) {
            Nmcli.loadSavedConnections(() => {});
        }
    }

    function handleWirelessConnect(network): void {
        if (Nmcli.active && Nmcli.active.ssid !== network.ssid) {
            Nmcli.disconnectFromNetwork();
            Qt.callLater(() => {
                connectToWirelessNetwork(network);
            });
        } else {
            connectToWirelessNetwork(network);
        }
    }

    function connectToWirelessNetwork(network): void {
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

