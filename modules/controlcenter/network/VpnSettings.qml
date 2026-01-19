pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.effects
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Appearance.spacing.normal

    SettingsHeader {
        icon: "vpn_key"
        title: qsTr("VPN Settings")
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("General")
        description: qsTr("VPN configuration")
    }

    SectionContainer {
        ToggleRow {
            label: qsTr("VPN enabled")
            checked: Config.utilities.vpn.enabled
            toggle.onToggled: {
                Config.utilities.vpn.enabled = checked;
                Config.save();
            }
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("Providers")
        description: qsTr("Manage VPN providers")
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            
            interactive: false
            spacing: Appearance.spacing.smaller
            
            model: ScriptModel {
                values: Config.utilities.vpn.provider.map((provider, index) => {
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
                    color: Colours.tPalette.m3surfaceContainerHigh
                    radius: Appearance.rounding.normal

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.normal
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: modelData.isActive ? "vpn_key" : "vpn_key_off"
                            font.pointSize: Appearance.font.size.large
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
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3outline
                            }
                        }

                        IconButton {
                            icon: modelData.isActive ? "arrow_downward" : "arrow_upward"
                            visible: !modelData.isActive || Config.utilities.vpn.provider.length > 1
                            onClicked: {
                                if (modelData.isActive && index < Config.utilities.vpn.provider.length - 1) {
                                    // Move down
                                    const providers = [...Config.utilities.vpn.provider];
                                    const temp = providers[index];
                                    providers[index] = providers[index + 1];
                                    providers[index + 1] = temp;
                                    Config.utilities.vpn.provider = providers;
                                    Config.save();
                                } else if (!modelData.isActive) {
                                    // Make active (move to top)
                                    const providers = [...Config.utilities.vpn.provider];
                                    const provider = providers.splice(index, 1)[0];
                                    providers.unshift(provider);
                                    Config.utilities.vpn.provider = providers;
                                    Config.save();
                                }
                            }
                        }

                        IconButton {
                            icon: "delete"
                            onClicked: {
                                const providers = [...Config.utilities.vpn.provider];
                                providers.splice(index, 1);
                                Config.utilities.vpn.provider = providers;
                                Config.save();
                            }
                        }
                    }

                    implicitHeight: 60
                }
            }
        }

        TextButton {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.normal
            text: qsTr("+ Add Provider")
            inactiveColour: Colours.palette.m3primaryContainer
            inactiveOnColour: Colours.palette.m3onPrimaryContainer

            onClicked: {
                addProviderDialog.open();
            }
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("Quick Add")
        description: qsTr("Add common VPN providers")
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.smaller

        TextButton {
            Layout.fillWidth: true
            text: qsTr("+ Add NetBird")
            inactiveColour: Colours.tPalette.m3surfaceContainerHigh
            inactiveOnColour: Colours.palette.m3onSurface

            onClicked: {
                const providers = [...Config.utilities.vpn.provider];
                providers.push({
                    name: "netbird",
                    displayName: "NetBird",
                    interface: "wt0"
                });
                Config.utilities.vpn.provider = providers;
                Config.save();
            }
        }

        TextButton {
            Layout.fillWidth: true
            text: qsTr("+ Add Tailscale")
            inactiveColour: Colours.tPalette.m3surfaceContainerHigh
            inactiveOnColour: Colours.palette.m3onSurface

            onClicked: {
                const providers = [...Config.utilities.vpn.provider];
                providers.push({
                    name: "tailscale",
                    displayName: "Tailscale",
                    interface: "tailscale0"
                });
                Config.utilities.vpn.provider = providers;
                Config.save();
            }
        }

        TextButton {
            Layout.fillWidth: true
            text: qsTr("+ Add Cloudflare WARP")
            inactiveColour: Colours.tPalette.m3surfaceContainerHigh
            inactiveOnColour: Colours.palette.m3onSurface

            onClicked: {
                const providers = [...Config.utilities.vpn.provider];
                providers.push({
                    name: "warp",
                    displayName: "Cloudflare WARP",
                    interface: "CloudflareWARP"
                });
                Config.utilities.vpn.provider = providers;
                Config.save();
            }
        }

        TextButton {
            Layout.fillWidth: true
            text: qsTr("+ Add WireGuard")
            inactiveColour: Colours.tPalette.m3surfaceContainerHigh
            inactiveOnColour: Colours.palette.m3onSurface

            onClicked: {
                customProviderDialog.providerType = "wireguard";
                customProviderDialog.open();
            }
        }
    }

    // Simple add provider dialog
    Popup {
        id: addProviderDialog
        
        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        implicitWidth: Math.min(500, parent.width - Appearance.padding.large * 2)
        padding: Appearance.padding.large
        
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        opacity: 0
        scale: 0.7
        
        onAboutToShow: {
            opacity = 0;
            scale = 0.7;
        }
        
        onOpened: {
            addOpacityAnim.to = 1;
            addScaleAnim.to = 1;
            addOpenAnim.start();
        }
        
        onAboutToHide: {
            addOpacityAnim.to = 0;
            addScaleAnim.to = 0.7;
            addCloseAnim.start();
        }
        
        ParallelAnimation {
            id: addOpenAnim
            NumberAnimation { id: addOpacityAnim; target: addProviderDialog; property: "opacity"; duration: Appearance.anim.durations.expressiveFastSpatial; easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial }
            NumberAnimation { id: addScaleAnim; target: addProviderDialog; property: "scale"; duration: Appearance.anim.durations.expressiveFastSpatial; easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial }
        }
        
        ParallelAnimation {
            id: addCloseAnim
            NumberAnimation { target: addProviderDialog; property: "opacity"; to: 0; duration: Appearance.anim.durations.expressiveFastSpatial; easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial }
            NumberAnimation { target: addProviderDialog; property: "scale"; to: 0.7; duration: Appearance.anim.durations.expressiveFastSpatial; easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial }
        }
        
        background: StyledRect {
            color: Colours.palette.m3surfaceContainerHigh
            radius: Appearance.rounding.large
        }
        
        contentItem: ColumnLayout {
            spacing: Appearance.spacing.normal
            
            StyledText {
                text: qsTr("Add VPN Provider")
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }
            
            StyledText {
                Layout.fillWidth: true
                text: qsTr("Choose a provider type or use Quick Add buttons below")
                wrapMode: Text.WordWrap
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }
            
            Item { Layout.preferredHeight: Appearance.spacing.normal }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal
                
                TextButton {
                    Layout.fillWidth: true
                    text: qsTr("Cancel")
                    inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                    inactiveOnColour: Colours.palette.m3onSurface
                    
                    onClicked: addProviderDialog.close()
                }
                
                TextButton {
                    Layout.fillWidth: true
                    text: qsTr("Custom")
                    inactiveColour: Colours.palette.m3primaryContainer
                    inactiveOnColour: Colours.palette.m3onPrimaryContainer
                    
                    onClicked: {
                        addProviderDialog.close();
                        customProviderDialog.providerType = "custom";
                        customProviderDialog.open();
                    }
                }
            }
        }
    }

    // Custom provider dialog (for WireGuard with interface name)
    Popup {
        id: customProviderDialog
        
        property string providerType: "custom"
        property string interfaceName: ""
        property string displayName: ""
        
        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        implicitWidth: Math.min(500, parent.width - Appearance.padding.large * 2)
        padding: Appearance.padding.large
        
        modal: true
        closePolicy: Popup.CloseOnEscape
        
        opacity: 0
        scale: 0.7
        
        onAboutToShow: {
            opacity = 0;
            scale = 0.7;
        }
        
        onOpened: {
            interfaceName = "";
            displayName = "";
            if (providerType === "wireguard") {
                displayName = "WireGuard";
            }
            customOpacityAnim.to = 1;
            customScaleAnim.to = 1;
            customOpenAnim.start();
        }
        
        onAboutToHide: {
            customOpacityAnim.to = 0;
            customScaleAnim.to = 0.7;
            customCloseAnim.start();
        }
        
        ParallelAnimation {
            id: customOpenAnim
            NumberAnimation { id: customOpacityAnim; target: customProviderDialog; property: "opacity"; duration: Appearance.anim.durations.expressiveFastSpatial; easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial }
            NumberAnimation { id: customScaleAnim; target: customProviderDialog; property: "scale"; duration: Appearance.anim.durations.expressiveFastSpatial; easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial }
        }
        
        ParallelAnimation {
            id: customCloseAnim
            NumberAnimation { target: customProviderDialog; property: "opacity"; to: 0; duration: Appearance.anim.durations.expressiveFastSpatial; easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial }
            NumberAnimation { target: customProviderDialog; property: "scale"; to: 0.7; duration: Appearance.anim.durations.expressiveFastSpatial; easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial }
        }
        
        background: StyledRect {
            color: Colours.palette.m3surfaceContainerHigh
            radius: Appearance.rounding.large
        }
        
        contentItem: ColumnLayout {
            spacing: Appearance.spacing.normal
            
            StyledText {
                text: customProviderDialog.providerType === "wireguard" ? qsTr("Add WireGuard VPN") : qsTr("Add Custom VPN")
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }
            
            StyledText {
                Layout.fillWidth: true
                text: customProviderDialog.providerType === "wireguard" ? 
                    qsTr("Enter the WireGuard interface name (e.g., wg0, torguard)") :
                    qsTr("Enter custom VPN details")
                wrapMode: Text.WordWrap
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }
            
            TextField {
                id: displayNameField
                Layout.fillWidth: true
                placeholderText: qsTr("Display Name")
                text: customProviderDialog.displayName
                onTextChanged: customProviderDialog.displayName = text
            }
            
            TextField {
                id: interfaceField
                Layout.fillWidth: true
                placeholderText: customProviderDialog.providerType === "wireguard" ? qsTr("Interface (e.g., wg0)") : qsTr("Interface")
                text: customProviderDialog.interfaceName
                onTextChanged: customProviderDialog.interfaceName = text
            }
            
            Item { Layout.preferredHeight: Appearance.spacing.normal }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal
                
                TextButton {
                    Layout.fillWidth: true
                    text: qsTr("Cancel")
                    inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                    inactiveOnColour: Colours.palette.m3onSurface
                    
                    onClicked: customProviderDialog.close()
                }
                
                TextButton {
                    Layout.fillWidth: true
                    text: qsTr("Add")
                    enabled: customProviderDialog.interfaceName.length > 0
                    inactiveColour: Colours.palette.m3primaryContainer
                    inactiveOnColour: Colours.palette.m3onPrimaryContainer
                    
                    onClicked: {
                        const providers = [...Config.utilities.vpn.provider];
                        const newProvider = {
                            name: customProviderDialog.providerType,
                            displayName: customProviderDialog.displayName || customProviderDialog.interfaceName,
                            interface: customProviderDialog.interfaceName
                        };
                        providers.push(newProvider);
                        Config.utilities.vpn.provider = providers;
                        Config.save();
                        customProviderDialog.close();
                    }
                }
            }
        }
    }
}
