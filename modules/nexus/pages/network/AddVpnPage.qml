pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
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
    readonly property VPN.Provider existing: editing ? (VPN.providers[editIndex] ?? null) : null

    function splitCmd(arr: var): string {
        return arr?.join(" ") ?? "";
    }

    function joinCmd(str: string): var {
        const t = str.trim();
        return t.length > 0 ? t.split(/\s+/) : [];
    }

    function arrEq(a: var, b: var): bool {
        return a.length === b.length && a.every((x, i) => x === b[i]);
    }

    function submit(): void {
        const name = nameField.text.trim();
        if (name.length === 0) {
            nameField.isError = true;
            nameField.forceActiveFocus();
            return;
        }

        const data = {
            name: name,
            displayName: displayField.text.trim() || name,
            interface: interfaceField.text.trim(),
            connectCmd: joinCmd(connectField.text),
            disconnectCmd: joinCmd(disconnectField.text)
        };

        if (editing) {
            const needsReload = existing.providerId === VPN.selectedProvider && VPN.connected && (existing.name !== name || existing.iface !== data.interface || !arrEq(existing.connectCmd, data.connectCmd) || !arrEq(existing.disconnectCmd, data.disconnectCmd));
            if (needsReload)
                VPN.disconnect();
            VPN.updateProvider(editIndex, data);
            if (needsReload) {
                if (!VPN.connecting && !VPN.disconnecting) {
                    VPN.connect();
                } else if (VPN.disconnecting) {
                    let onConnChanged = () => {
                        if (onConnChanged && !VPN.disconnecting) {
                            VPN.disconnectingChanged.disconnect(onConnChanged);
                            onConnChanged = null;
                            if (!VPN.connected)
                                VPN.connect();
                        }
                    };
                    VPN.disconnectingChanged.connect(onConnChanged);
                }
            }
        } else {
            VPN.addProvider(data);
        }

        nState.closeSubPage();
    }

    title: editing ? qsTr("Edit VPN provider") : qsTr("Add VPN provider")
    isSubPage: true

    Component.onCompleted: {
        if (existing) {
            nameField.text = existing.name;
            displayField.text = existing.displayName;
            interfaceField.text = existing.iface;
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

        StyledTextField {
            id: nameField

            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            placeholderText: qsTr("Provider name")
            leadingIcon: "vpn_key"
            supportingText: qsTr("Built-in id or a custom name")
            errorText: qsTr("Provider name is required")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            onAccepted: displayField.forceActiveFocus()
        }

        StyledTextField {
            id: displayField

            Layout.fillWidth: true
            placeholderText: qsTr("Display name")
            supportingText: qsTr("Shown in the list")
            leadingIcon: "label"
            inputMethodHints: Qt.ImhNoPredictiveText

            onAccepted: interfaceField.forceActiveFocus()
        }

        StyledTextField {
            id: interfaceField

            Layout.fillWidth: true
            placeholderText: qsTr("Interface")
            leadingIcon: "lan"
            supportingText: qsTr("Network interface (for WireGuard / status checks)")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            onAccepted: connectField.forceActiveFocus()
        }

        SectionHeader {
            text: qsTr("Custom commands (optional)")
        }

        StyledTextField {
            id: connectField

            Layout.fillWidth: true
            placeholderText: qsTr("Connect command")
            leadingIcon: "play_arrow"
            supportingText: qsTr("Leave empty to use the built-in default")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            onAccepted: disconnectField.forceActiveFocus()
        }

        StyledTextField {
            id: disconnectField

            Layout.fillWidth: true
            placeholderText: qsTr("Disconnect command")
            leadingIcon: "stop"
            supportingText: qsTr("Leave empty to use the built-in default")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            onAccepted: root.submit()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: (root.editing ? Tokens.spacing.medium : Tokens.spacing.extraSmall) - parent.spacing
            spacing: Tokens.spacing.small

            IconTextButton {
                visible: root.editing
                isRound: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                inactiveColour: Colours.palette.m3errorContainer
                inactiveOnColour: Colours.palette.m3onErrorContainer
                iconLabel.fill: 1
                iconLabel.grade: 25
                icon: "delete_forever"
                text: qsTr("Delete")
                onClicked: {
                    if (root.existing.providerId === VPN.selectedProvider && VPN.connected)
                        VPN.disconnect();
                    VPN.deleteProvider(root.existing.index);
                    root.nState.closeSubPage();
                }
            }

            Item {
                Layout.fillWidth: true
            }

            ButtonRow {
                spacing: parent.spacing

                TextButton {
                    isRound: true
                    shapeMorph: true
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    type: TextButton.Tonal
                    text: qsTr("Cancel")
                    onClicked: root.nState.closeSubPage()
                }

                TextButton {
                    isRound: true
                    shapeMorph: true
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    text: root.editing ? qsTr("Save") : qsTr("Add")
                    disabled: !nameField.text.trim()
                    onClicked: root.submit()
                }
            }
        }
    }
}
