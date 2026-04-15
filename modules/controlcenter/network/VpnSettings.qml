pragma ComponentBehavior: Bound

import ".."
import "../components"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services

ColumnLayout {
    id: root

    required property Session session

    spacing: Tokens.spacing.normal

    SettingsHeader {
        icon: "vpn_key"
        title: qsTr("VPN Settings")
    }

    SectionHeader {
        Layout.topMargin: Tokens.spacing.large
        title: qsTr("General")
        description: qsTr("VPN configuration")
    }

    SectionContainer {
        ToggleRow {
            label: qsTr("VPN enabled")
            checked: GlobalConfig.utilities.vpn.enabled
            toggle.onToggled: {
                GlobalConfig.utilities.vpn.enabled = checked;
            }
        }
    }

    SectionHeader {
        Layout.topMargin: Tokens.spacing.large
        title: qsTr("Providers")
        description: qsTr("Manage VPN providers")
    }

    SectionContainer {
        contentSpacing: Tokens.spacing.normal

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight

            interactive: false
            spacing: Tokens.spacing.smaller

            model: ScriptModel {
                values: GlobalConfig.utilities.vpn.provider.map((provider, index) => {
                    const isObject = typeof provider === "object";
                    const name = isObject ? (provider.name || "custom") : String(provider);
                    const displayName = isObject ? (provider.displayName || name) : name;
                    const iface = isObject ? (provider.interface || "") : "";

                    return {
                        index: index,
                        name: name,
                        displayName: displayName,
                        interface: iface,
                        provider: provider,
                        isActive: index === 0
                    };
                })
            }

            delegate: Component {
                StyledRect {
                    required property var modelData
                    required property int index

                    width: ListView.view ? ListView.view.width : undefined
                    implicitHeight: 60
                    color: Colours.tPalette.m3surfaceContainerHigh
                    radius: Tokens.rounding.normal

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Tokens.padding.normal
                        spacing: Tokens.spacing.normal

                        MaterialIcon {
                            text: modelData.isActive ? "vpn_key" : "vpn_key_off"
                            font.pointSize: Tokens.font.size.large
                            color: modelData.isActive ? Colours.palette.m3primary : Colours.palette.m3outline
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                text: modelData.displayName
                                font.weight: modelData.isActive ? 500 : 400
                            }

                            StyledText {
                                text: qsTr("%1 • %2").arg(modelData.name).arg(modelData.interface || qsTr("No interface"))
                                font.pointSize: Tokens.font.size.small
                                color: Colours.palette.m3outline
                            }
                        }

                        IconButton {
                            icon: modelData.isActive ? "arrow_downward" : "arrow_upward"
                            visible: !modelData.isActive || GlobalConfig.utilities.vpn.provider.length > 1
                            onClicked: {
                                const providers = [];
                                for (let i = 0; i < GlobalConfig.utilities.vpn.provider.length; i++) {
                                    const p = GlobalConfig.utilities.vpn.provider[i];
                                    const reconstructed = {
                                        name: p.name,
                                        displayName: p.displayName,
                                        interface: p.interface,
                                        enabled: p.enabled
                                    };
                                    if (p.connectCmd && p.connectCmd.length > 0) {
                                        reconstructed.connectCmd = p.connectCmd;
                                    }
                                    if (p.disconnectCmd && p.disconnectCmd.length > 0) {
                                        reconstructed.disconnectCmd = p.disconnectCmd;
                                    }
                                    providers.push(reconstructed);
                                }

                                if (modelData.isActive && index < providers.length - 1) {
                                    // Move down
                                    const temp = providers[index];
                                    providers[index] = providers[index + 1];
                                    providers[index + 1] = temp;
                                } else if (!modelData.isActive) {
                                    // Make active (move to top)
                                    const provider = providers.splice(index, 1)[0];
                                    providers.unshift(provider);
                                }

                                GlobalConfig.utilities.vpn.provider = providers;
                            }
                        }

                        IconButton {
                            icon: "delete"
                            onClicked: {
                                const providers = [];
                                for (let i = 0; i < GlobalConfig.utilities.vpn.provider.length; i++) {
                                    if (i !== index) {
                                        const p = GlobalConfig.utilities.vpn.provider[i];
                                        const reconstructed = {
                                            name: p.name,
                                            displayName: p.displayName,
                                            interface: p.interface,
                                            enabled: p.enabled
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
                            }
                        }
                    }
                }
            }
        }

        TextButton {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.normal
            text: qsTr("+ Add Provider")
            inactiveColour: Colours.palette.m3primaryContainer
            inactiveOnColour: Colours.palette.m3onPrimaryContainer

            onClicked: {
                addProviderDialog.open();
            }
        }
    }

    SectionHeader {
        Layout.topMargin: Tokens.spacing.large
        title: qsTr("Quick Add")
        description: qsTr("Add common VPN providers")
    }

    SectionContainer {
        contentSpacing: Tokens.spacing.smaller

        TextButton {
            Layout.fillWidth: true
            text: qsTr("+ Add NetBird")
            inactiveColour: Colours.tPalette.m3surfaceContainerHigh
            inactiveOnColour: Colours.palette.m3onSurface

            onClicked: {
                const providers = [...GlobalConfig.utilities.vpn.provider];
                providers.push({
                    name: "netbird",
                    displayName: "NetBird",
                    interface: "wt0"
                });
                GlobalConfig.utilities.vpn.provider = providers;
            }
        }

        TextButton {
            Layout.fillWidth: true
            text: qsTr("+ Add Tailscale")
            inactiveColour: Colours.tPalette.m3surfaceContainerHigh
            inactiveOnColour: Colours.palette.m3onSurface

            onClicked: {
                const providers = [...GlobalConfig.utilities.vpn.provider];
                providers.push({
                    name: "tailscale",
                    displayName: "Tailscale",
                    interface: "tailscale0"
                });
                GlobalConfig.utilities.vpn.provider = providers;
            }
        }

        TextButton {
            Layout.fillWidth: true
            text: qsTr("+ Add Cloudflare WARP")
            inactiveColour: Colours.tPalette.m3surfaceContainerHigh
            inactiveOnColour: Colours.palette.m3onSurface

            onClicked: {
                const providers = [...GlobalConfig.utilities.vpn.provider];
                providers.push({
                    name: "warp",
                    displayName: "Cloudflare WARP",
                    interface: "CloudflareWARP"
                });
                GlobalConfig.utilities.vpn.provider = providers;
            }
        }
    }
}
