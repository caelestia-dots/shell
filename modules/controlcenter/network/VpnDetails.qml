pragma ComponentBehavior: Bound

import ".."
import "../components"
import QtQuick
import QtQuick.Controls
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
    readonly property var vpnProvider: root.session.vpn.active
    readonly property bool providerEnabled: {
        if (!vpnProvider || vpnProvider.index === undefined)
            return false;
        const provider = GlobalConfig.utilities.vpn.provider[vpnProvider.index];
        return provider && typeof provider === "object" && provider.enabled === true;
    }

    device: vpnProvider

    headerComponent: Component {
        ConnectionHeader {
            icon: "vpn_key"
            title: root.vpnProvider?.displayName ?? qsTr("Unknown")
        }
    }

    sections: [
        Component {
            ColumnLayout {
                spacing: Tokens.spacing.normal

                SectionHeader {
                    title: qsTr("Connection status")
                    description: qsTr("VPN connection settings")
                }

                SectionContainer {
                    ToggleRow {
                        label: qsTr("Enable this provider")
                        checked: root.providerEnabled
                        toggle.onToggled: {
                            if (!root.vpnProvider)
                                return;
                            const providers = [];
                            const index = root.vpnProvider.index;

                            // Copy providers and update enabled state
                            for (let i = 0; i < GlobalConfig.utilities.vpn.provider.length; i++) {
                                const p = GlobalConfig.utilities.vpn.provider[i];
                                if (typeof p === "object") {
                                    const newProvider = {
                                        name: p.name,
                                        displayName: p.displayName,
                                        interface: p.interface
                                    };

                                    if (checked) {
                                        // Enable this one, disable others
                                        newProvider.enabled = (i === index);
                                    } else {
                                        // Just disable this one
                                        newProvider.enabled = (i === index) ? false : (p.enabled !== false);
                                    }

                                    if (p.connectCmd && p.connectCmd.length > 0) {
                                        newProvider.connectCmd = p.connectCmd;
                                    }
                                    if (p.disconnectCmd && p.disconnectCmd.length > 0) {
                                        newProvider.disconnectCmd = p.disconnectCmd;
                                    }

                                    providers.push(newProvider);
                                } else {
                                    providers.push(p);
                                }
                            }

                            GlobalConfig.utilities.vpn.provider = providers;
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Tokens.spacing.normal
                        spacing: Tokens.spacing.normal

                        TextButton {
                            Layout.fillWidth: true
                            Layout.minimumHeight: Tokens.font.size.normal + Tokens.padding.normal * 2
                            visible: root.providerEnabled
                            enabled: !VPN.connecting
                            inactiveColour: Colours.palette.m3primaryContainer
                            inactiveOnColour: Colours.palette.m3onPrimaryContainer
                            text: VPN.connected ? qsTr("Disconnect") : qsTr("Connect")

                            onClicked: {
                                VPN.toggle();
                            }
                        }

                        TextButton {
                            Layout.fillWidth: true
                            text: qsTr("Edit Provider")
                            inactiveColour: Colours.palette.m3secondaryContainer
                            inactiveOnColour: Colours.palette.m3onSecondaryContainer

                            onClicked: {
                                const provider = GlobalConfig.utilities.vpn.provider[root.vpnProvider.index];
                                editVpnDialog.editIndex = root.vpnProvider.index;
                                editVpnDialog.providerName = root.vpnProvider.name;
                                editVpnDialog.displayName = root.vpnProvider.displayName;
                                editVpnDialog.interfaceName = root.vpnProvider.interface;
                                editVpnDialog.connectCmd = (provider && provider.connectCmd) ? provider.connectCmd.join(" ") : "";
                                editVpnDialog.disconnectCmd = (provider && provider.disconnectCmd) ? provider.disconnectCmd.join(" ") : "";
                                editVpnDialog.open();
                            }
                        }

                        TextButton {
                            Layout.fillWidth: true
                            text: qsTr("Delete Provider")
                            inactiveColour: Colours.palette.m3errorContainer
                            inactiveOnColour: Colours.palette.m3onErrorContainer

                            onClicked: {
                                const providers = [];
                                for (let i = 0; i < GlobalConfig.utilities.vpn.provider.length; i++) {
                                    if (i !== root.vpnProvider.index) {
                                        providers.push(GlobalConfig.utilities.vpn.provider[i]);
                                    }
                                }
                                GlobalConfig.utilities.vpn.provider = providers;
                                root.session.vpn.active = null;
                            }
                        }
                    }

                    TextButton {
                        Layout.fillWidth: true
                        Layout.topMargin: Tokens.spacing.normal
                        visible: root.providerEnabled && VPN.status.state === "needs-auth" && VPN.status.authUrl !== ""
                        text: qsTr("Open Login Page")
                        inactiveColour: Colours.palette.m3tertiaryContainer
                        inactiveOnColour: Colours.palette.m3onTertiaryContainer

                        onClicked: {
                            Qt.openUrlExternally(VPN.status.authUrl);
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.topMargin: Tokens.spacing.normal
                        visible: root.providerEnabled && VPN.status.state === "needs-auth" && VPN.status.authUrl === ""
                        text: qsTr("Click 'Connect' to generate authentication URL")
                        font.pointSize: Tokens.font.size.small
                        color: Colours.palette.m3onSurfaceVariant
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }
        },
        Component {
            ColumnLayout {
                spacing: Tokens.spacing.normal

                SectionHeader {
                    title: qsTr("Provider details")
                    description: qsTr("VPN provider information")
                }

                SectionContainer {
                    contentSpacing: Tokens.spacing.small / 2

                    PropertyRow {
                        label: qsTr("Provider")
                        value: root.vpnProvider?.name ?? qsTr("Unknown")
                    }

                    PropertyRow {
                        showTopMargin: true
                        label: qsTr("Display name")
                        value: root.vpnProvider?.displayName ?? qsTr("Unknown")
                    }

                    PropertyRow {
                        showTopMargin: true
                        label: qsTr("Interface")
                        value: root.vpnProvider?.interface || qsTr("N/A")
                    }

                    PropertyRow {
                        showTopMargin: true
                        label: qsTr("Status")
                        value: {
                            if (!root.providerEnabled)
                                return qsTr("Disabled");
                            if (VPN.connecting)
                                return qsTr("Connecting...");

                            switch (VPN.status.state) {
                            case "connected":
                                return qsTr("Connected");
                            case "disconnected":
                                return qsTr("Disconnected");
                            case "connecting":
                                return qsTr("Connecting...");
                            case "needs-auth":
                                return qsTr("Authentication required");
                            case "error":
                                return qsTr("Error");
                            default:
                                return qsTr("Unknown");
                            }
                        }
                    }

                    PropertyRow {
                        visible: VPN.status.reason !== ""
                        showTopMargin: true
                        label: qsTr("Details")
                        value: VPN.status.reason
                    }

                    PropertyRow {
                        showTopMargin: true
                        label: qsTr("Enabled")
                        value: root.providerEnabled ? qsTr("Yes") : qsTr("No")
                    }
                }
            }
        }
    ]

    // Edit VPN Dialog
    Popup {
        id: editVpnDialog

        property int editIndex: -1
        property string providerName: ""
        property string displayName: ""
        property string interfaceName: ""
        property string connectCmd: ""
        property string disconnectCmd: ""

        function closeWithAnimation(): void {
            close();
        }

        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(400, parent.width - Tokens.padding.large * 2)
        padding: Tokens.padding.large * 1.5

        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        opacity: 0
        scale: 0.7

        enter: Transition {
            Anim {
                property: "opacity"
                from: 0
                to: 1
                type: Anim.FastSpatial
            }
            Anim {
                property: "scale"
                from: 0.7
                to: 1
                type: Anim.FastSpatial
            }
        }

        exit: Transition {
            Anim {
                property: "opacity"
                from: 1
                to: 0
                type: Anim.FastSpatial
            }
            Anim {
                property: "scale"
                from: 1
                to: 0.7
                type: Anim.FastSpatial
            }
        }

        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.4 * editVpnDialog.opacity)
        }

        background: StyledRect {
            color: Colours.palette.m3surfaceContainerHigh
            radius: Tokens.rounding.large

            Elevation {
                anchors.fill: parent
                radius: parent.radius
                level: 3
                z: -1
            }
        }

        contentItem: ColumnLayout {
            spacing: Tokens.spacing.normal

            StyledText {
                text: qsTr("Edit VPN Provider")
                font.pointSize: Tokens.font.size.large
                font.weight: 500
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.smaller / 2

                StyledText {
                    text: qsTr("Display Name")
                    font.pointSize: Tokens.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    color: displayNameField.activeFocus ? Colours.layer(Colours.palette.m3surfaceContainer, 3) : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                    radius: Tokens.rounding.small
                    border.width: 1
                    border.color: displayNameField.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.3)

                    Behavior on color {
                        CAnim {}
                    }
                    Behavior on border.color {
                        CAnim {}
                    }

                    StyledTextField {
                        id: displayNameField

                        anchors.centerIn: parent
                        width: parent.width - Tokens.padding.normal
                        horizontalAlignment: TextInput.AlignLeft
                        text: editVpnDialog.displayName
                        onTextChanged: editVpnDialog.displayName = text
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.smaller / 2

                StyledText {
                    text: qsTr("Interface (e.g., wg0, torguard)")
                    font.pointSize: Tokens.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    color: interfaceNameField.activeFocus ? Colours.layer(Colours.palette.m3surfaceContainer, 3) : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                    radius: Tokens.rounding.small
                    border.width: 1
                    border.color: interfaceNameField.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.3)

                    Behavior on color {
                        CAnim {}
                    }
                    Behavior on border.color {
                        CAnim {}
                    }

                    StyledTextField {
                        id: interfaceNameField

                        anchors.centerIn: parent
                        width: parent.width - Tokens.padding.normal
                        horizontalAlignment: TextInput.AlignLeft
                        text: editVpnDialog.interfaceName
                        onTextChanged: editVpnDialog.interfaceName = text
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.smaller / 2
                visible: editVpnDialog.connectCmd.length > 0

                StyledText {
                    text: qsTr("Connect Command")
                    font.pointSize: Tokens.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    color: connectCmdFieldEdit.activeFocus ? Colours.layer(Colours.palette.m3surfaceContainer, 3) : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                    radius: Tokens.rounding.small
                    border.width: 1
                    border.color: connectCmdFieldEdit.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.3)

                    Behavior on color {
                        CAnim {}
                    }
                    Behavior on border.color {
                        CAnim {}
                    }

                    StyledTextField {
                        id: connectCmdFieldEdit

                        anchors.centerIn: parent
                        width: parent.width - Tokens.padding.normal
                        horizontalAlignment: TextInput.AlignLeft
                        text: editVpnDialog.connectCmd
                        onTextChanged: editVpnDialog.connectCmd = text
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.smaller / 2
                visible: editVpnDialog.disconnectCmd.length > 0

                StyledText {
                    text: qsTr("Disconnect Command")
                    font.pointSize: Tokens.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    color: disconnectCmdFieldEdit.activeFocus ? Colours.layer(Colours.palette.m3surfaceContainer, 3) : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                    radius: Tokens.rounding.small
                    border.width: 1
                    border.color: disconnectCmdFieldEdit.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.3)

                    Behavior on color {
                        CAnim {}
                    }
                    Behavior on border.color {
                        CAnim {}
                    }

                    StyledTextField {
                        id: disconnectCmdFieldEdit

                        anchors.centerIn: parent
                        width: parent.width - Tokens.padding.normal
                        horizontalAlignment: TextInput.AlignLeft
                        text: editVpnDialog.disconnectCmd
                        onTextChanged: editVpnDialog.disconnectCmd = text
                    }
                }
            }

            RowLayout {
                Layout.topMargin: Tokens.spacing.normal
                Layout.fillWidth: true
                spacing: Tokens.spacing.normal

                TextButton {
                    Layout.fillWidth: true
                    text: qsTr("Cancel")
                    inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                    inactiveOnColour: Colours.palette.m3onSurface
                    onClicked: editVpnDialog.closeWithAnimation()
                }

                TextButton {
                    Layout.fillWidth: true
                    text: qsTr("Save")
                    enabled: editVpnDialog.interfaceName.length > 0
                    inactiveColour: Colours.palette.m3primaryContainer
                    inactiveOnColour: Colours.palette.m3onPrimaryContainer

                    onClicked: {
                        const providers = [];
                        const oldProvider = GlobalConfig.utilities.vpn.provider[editVpnDialog.editIndex];
                        const wasEnabled = typeof oldProvider === "object" ? (oldProvider.enabled !== false) : true;

                        for (let i = 0; i < GlobalConfig.utilities.vpn.provider.length; i++) {
                            if (i === editVpnDialog.editIndex) {
                                const hasCommands = editVpnDialog.connectCmd.length > 0 && editVpnDialog.disconnectCmd.length > 0;
                                const newProvider = {
                                    displayName: editVpnDialog.displayName || editVpnDialog.interfaceName,
                                    enabled: wasEnabled,
                                    interface: editVpnDialog.interfaceName,
                                    name: editVpnDialog.providerName
                                };

                                if (hasCommands) {
                                    newProvider.connectCmd = editVpnDialog.connectCmd.split(" ").filter(s => s.length > 0);
                                    newProvider.disconnectCmd = editVpnDialog.disconnectCmd.split(" ").filter(s => s.length > 0);
                                }

                                providers.push(newProvider);
                            } else {
                                const p = GlobalConfig.utilities.vpn.provider[i];
                                const reconstructed = {
                                    displayName: p.displayName,
                                    enabled: p.enabled,
                                    interface: p.interface,
                                    name: p.name
                                };
                                if (p.connectCmd && p.connectCmd.length > 0) {
                                    reconstructed.connectCmd = p.connectCmd;
                                }
                                if (p.disconnectCmd && p.disconnectCmd.length > 0) {
                                    reconstructed.disconnectCmd = p.disconnectCmd;
                                }
                                providers.push(reconstructed);
                            }
                        }

                        GlobalConfig.utilities.vpn.provider = providers;
                        editVpnDialog.closeWithAnimation();
                    }
                }
            }
        }
    }
}
