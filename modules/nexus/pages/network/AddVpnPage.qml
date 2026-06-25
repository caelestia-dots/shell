pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// Add or edit a VPN provider. editingVpnIndex (-1 = add) is read from NexusState.
PageBase {
    id: root

    readonly property int editIndex: nState.editingVpnIndex
    readonly property bool editing: editIndex >= 0
    readonly property var existing: editing ? (VPN.providers()[editIndex] ?? null) : null

    function splitCmd(arr: var): string {
        return (arr && arr.length > 0) ? arr.join(" ") : "";
    }

    function joinCmd(str: string): var {
        const t = str.trim();
        return t.length > 0 ? t.split(/\s+/) : [];
    }

    function submit(): void {
        const name = nameField.text.trim();
        if (name.length === 0) {
            nameField.isError = true;
            nameField.forceFieldFocus();
            return;
        }

        const data = {
            name: name,
            displayName: displayField.text.trim() || name,
            interface: interfaceField.text.trim(),
            connectCmd: root.joinCmd(connectField.text),
            disconnectCmd: root.joinCmd(disconnectField.text)
        };

        if (root.editing)
            VPN.updateProvider(root.editIndex, data);
        else
            VPN.addProvider(data);

        nState.closeSubPage();
    }

    title: editing ? qsTr("Edit VPN provider") : qsTr("Add VPN provider")
    isSubPage: true

    Component.onCompleted: {
        if (existing) {
            nameField.text = existing.name;
            displayField.text = existing.displayName;
            interfaceField.text = existing.interface;
            connectField.text = splitCmd(existing.connectCmd);
            disconnectField.text = splitCmd(existing.disconnectCmd);
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            text: qsTr("Built-in names (wireguard, warp, tailscale, netbird) auto-fill their commands. For others, provide the connect/disconnect commands.")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        M3TextField {
            id: nameField

            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            label: qsTr("Provider name")
            placeholder: qsTr("wireguard, warp, tailscale…")
            leadingIcon: "vpn_key"
            supportingText: qsTr("Built-in id or a custom name")
            errorText: qsTr("Provider name is required")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            onAccepted: displayField.forceFieldFocus()
        }

        M3TextField {
            id: displayField

            Layout.fillWidth: true
            label: qsTr("Display name")
            placeholder: qsTr("Shown in the list")
            leadingIcon: "label"
            inputMethodHints: Qt.ImhNoPredictiveText

            onAccepted: interfaceField.forceFieldFocus()
        }

        M3TextField {
            id: interfaceField

            Layout.fillWidth: true
            label: qsTr("Interface")
            placeholder: qsTr("e.g. wg0, tailscale0")
            leadingIcon: "lan"
            supportingText: qsTr("Network interface (for WireGuard / status checks)")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            onAccepted: connectField.forceFieldFocus()
        }

        SectionHeader {
            text: qsTr("Custom commands (optional)")
        }

        M3TextField {
            id: connectField

            Layout.fillWidth: true
            label: qsTr("Connect command")
            placeholder: qsTr("e.g. tailscale up")
            leadingIcon: "play_arrow"
            supportingText: qsTr("Leave empty to use the built-in default")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            onAccepted: disconnectField.forceFieldFocus()
        }

        M3TextField {
            id: disconnectField

            Layout.fillWidth: true
            label: qsTr("Disconnect command")
            placeholder: qsTr("e.g. tailscale down")
            leadingIcon: "stop"
            supportingText: qsTr("Leave empty to use the built-in default")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            onAccepted: root.submit()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.medium
            spacing: Tokens.spacing.medium

            Item {
                Layout.fillWidth: true
            }

            TextButton {
                Layout.minimumHeight: Tokens.font.body.medium.pointSize + Tokens.padding.medium * 2
                type: TextButton.Text
                text: qsTr("Cancel")
                onClicked: root.nState.closeSubPage()
            }

            TextButton {
                Layout.minimumHeight: Tokens.font.body.medium.pointSize + Tokens.padding.medium * 2
                type: TextButton.Filled
                text: root.editing ? qsTr("Save") : qsTr("Add")
                enabled: nameField.text.trim().length > 0
                onClicked: root.submit()
            }
        }
    }
}
