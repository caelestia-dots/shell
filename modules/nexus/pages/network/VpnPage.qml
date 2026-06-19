pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// Full VPN provider management. Reached from the VPN section on NetworkPage.
// Lists configured providers, lets you switch the active one, connect/disconnect,
// and add/edit/delete providers (persisted to utilities.vpn.provider).
PageBase {
    id: root

    // Drives the live "Connected for" label and refreshes In/Out counters.
    property int nowTick: 0

    function formatDuration(ms: double): string {
        if (!ms || ms <= 0)
            return "00:00:00";
        let s = Math.floor(ms / 1000);
        const h = Math.floor(s / 3600);
        s -= h * 3600;
        const m = Math.floor(s / 60);
        s -= m * 60;
        const pad = n => (n < 10 ? "0" + n : "" + n);
        return `${pad(h)}:${pad(m)}:${pad(s)}`;
    }

    title: qsTr("VPN")
    isSubPage: true

    Component.onCompleted: VPN.checkStatus()

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Timer {
            running: root.visible && VPN.connected
            repeat: true
            triggeredOnStart: true
            interval: 1000
            onTriggered: {
                root.nowTick = Date.now();
                VPN.refreshStats();
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.small
            visible: VPN.providers().length === 0
            text: qsTr("No VPN providers configured yet. Add one to get started.")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        // ---- Provider list ---------------------------------------------------
        Repeater {
            model: VPN.providers()

            delegate: ConnectedRect {
                id: providerRow

                required property var modelData
                required property int index

                readonly property bool isActive: modelData.enabled
                readonly property bool isConnected: isActive && VPN.connected

                Layout.fillWidth: true
                first: index === 0
                last: index === VPN.providers().length - 1
                implicitHeight: cardLayout.implicitHeight + Tokens.padding.medium * 2

                // Tapping the row makes this provider the active one.
                StateLayer {
                    onClicked: {
                        if (!providerRow.isActive)
                            VPN.setActiveProvider(providerRow.modelData.index);
                    }
                }

                ColumnLayout {
                    id: cardLayout

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.medium
                    spacing: Tokens.spacing.medium

                    RowLayout {
                        id: rowLayout

                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        StyledRect {
                            implicitWidth: implicitHeight
                            implicitHeight: provIcon.implicitHeight + Tokens.padding.small * 2
                            radius: Tokens.rounding.full
                            color: providerRow.isConnected ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHighest

                            MaterialIcon {
                                id: provIcon

                                anchors.centerIn: parent
                                text: providerRow.isConnected ? "vpn_key" : "vpn_key_off"
                                fill: providerRow.isConnected ? 1 : 0
                                color: providerRow.isConnected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.medium
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: providerRow.modelData.displayName
                                font: Tokens.font.body.medium
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: {
                                    if (!providerRow.isActive)
                                        return qsTr("Tap to use");
                                    if (VPN.connecting)
                                        return qsTr("Connecting…");
                                    switch (VPN.status.state) {
                                    case "connected":
                                        return qsTr("Connected");
                                    case "needs-auth":
                                        return VPN.status.reason || qsTr("Authentication required");
                                    case "error":
                                        return VPN.status.reason || qsTr("Error");
                                    default:
                                        return qsTr("Active");
                                    }
                                }
                                color: {
                                    if (!providerRow.isActive)
                                        return Colours.palette.m3outline;
                                    if (VPN.status.state === "connected")
                                        return Colours.palette.m3primary;
                                    if (VPN.status.state === "error")
                                        return Colours.palette.m3error;
                                    if (VPN.status.state === "needs-auth")
                                        return Colours.palette.m3tertiary;
                                    return Colours.palette.m3onSurfaceVariant;
                                }
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }

                        // Connect / disconnect (only for the active provider).
                        IconButton {
                            visible: providerRow.isActive
                            disabled: VPN.connecting
                            type: IconButton.Tonal
                            isToggle: true
                            checked: providerRow.isConnected
                            icon: providerRow.isConnected ? "link_off" : "link"
                            onClicked: VPN.toggle()
                        }

                        // Edit.
                        IconButton {
                            type: IconButton.Text
                            icon: "edit"
                            onClicked: {
                                root.nState.editingVpnIndex = providerRow.modelData.index;
                                root.nState.openSubPage(2);
                            }
                        }

                        // Delete.
                        IconButton {
                            type: IconButton.Text
                            icon: "delete"
                            inactiveOnColour: Colours.palette.m3error
                            onClicked: {
                                if (providerRow.isActive && VPN.connected)
                                    VPN.disconnect();
                                VPN.deleteProvider(providerRow.modelData.index);
                            }
                        }
                    }

                    // Expanded info — only while this provider is connected.
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: provIcon.width + Tokens.padding.small * 2 + Tokens.spacing.medium
                        spacing: Tokens.spacing.large
                        visible: providerRow.isConnected

                        // Server (best-effort; only some providers expose this).
                        ColumnLayout {
                            visible: VPN.serverLocation.length > 0
                            spacing: 0

                            StyledText {
                                text: qsTr("Server")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                            }

                            StyledText {
                                text: VPN.serverLocation
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }
                        }

                        // In / Out data.
                        ColumnLayout {
                            visible: VPN.bytesIn.length > 0 || VPN.bytesOut.length > 0
                            spacing: 0

                            StyledText {
                                text: qsTr("Data")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                            }

                            StyledText {
                                text: qsTr("In: %1 · Out: %2").arg(VPN.bytesIn || "0 B").arg(VPN.bytesOut || "0 B")
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        // Connected for (live).
                        ColumnLayout {
                            spacing: 0

                            StyledText {
                                Layout.alignment: Qt.AlignRight
                                text: qsTr("Connected for")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                horizontalAlignment: Text.AlignRight
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignRight
                                text: {
                                    root.nowTick; // re-evaluate each tick
                                    return root.formatDuration(Date.now() - VPN.connectedSince);
                                }
                                color: Colours.palette.m3primary
                                font: Tokens.font.body.small
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }
        }

        // ---- Add provider ----------------------------------------------------
        ConnectedRect {
            Layout.fillWidth: true
            Layout.topMargin: VPN.providers().length > 0 ? Tokens.spacing.small : 0
            first: true
            last: true
            implicitHeight: addLayout.implicitHeight + addLayout.anchors.margins * 2

            StateLayer {
                onClicked: {
                    root.nState.editingVpnIndex = -1;
                    root.nState.openSubPage(2);
                }
            }

            RowLayout {
                id: addLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "add"
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Add VPN provider")
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }
        }
    }
}
