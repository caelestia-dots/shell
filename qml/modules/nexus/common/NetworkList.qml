pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus

ItemList {
    id: root

    required property NexusState nState
    property int limit: 0 // 0 = show all
    property bool enableFilter

    signal networkSelected(ap: Nmcli.AccessPoint)

    function networkFilter(ap: Nmcli.AccessPoint): bool {
        return true;
    }

    showList: Nmcli.wifiEnabled
    placeholderIcon: Nmcli.wifiEnabled ? "wifi_find" : "signal_wifi_off"
    placeholderText: Nmcli.wifiEnabled ? qsTr("No networks found") : qsTr("Wi-Fi disabled")
    extraHeight: Nmcli.scanning ? Tokens.rounding.extraSmall : 0 // Inline so it isn't affected by anim
    list.anchors.top: scanningIndicator.bottom

    model: ScriptModel {
        values: {
            const connecting = Nmcli.connectingSsid();
            // Lower rank sorts higher in the list
            const rank = n => n.active ? 0 : n.ssid === connecting ? 1 : Nmcli.hasSavedProfile(n.ssid) ? 2 : 3;
            const sorted = [...Nmcli.networks].sort((a, b) => rank(a) - rank(b) || b.strength - a.strength);
            if (root.limit > 0 && sorted.length > root.limit)
                sorted.length = root.limit;
            return root.enableFilter ? sorted.filter(root.networkFilter) : sorted;
        }
    }

    delegate: StateLayer {
        id: network

        required property int index
        required property var modelData
        property bool currentSelected
        property real textOpacity: disabled ? 0.5 : 1

        disabled: currentSelected || Nmcli.connectingSsid() === modelData.ssid

        anchors.left: root.list.contentItem.left
        anchors.right: root.list.contentItem.right
        implicitHeight: networkLayout.implicitHeight + networkLayout.anchors.margins * 2
        radius: Tokens.rounding.extraSmall
        bottomLeftRadius: root?.last && index === root.list.count - 1 ? Tokens.rounding.extraLarge : radius
        bottomRightRadius: root?.last && index === root.list.count - 1 ? Tokens.rounding.extraLarge : radius
        anchors.fill: undefined

        onClicked: {
            if (!modelData.active) {
                NetworkConnection.handleConnect(modelData);
                currentSelected = true;
                root.networkSelected(modelData);
            } else {
                // Active network: open its detail/settings sub-page.
                root.nState.selectedNetworkSsid = modelData.ssid;
                root.nState.networkDetailsFromSaved = false;
                root.nState.openSubPage(3);
            }
        }

        Behavior on textOpacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Connections {
            function onActiveChanged(): void {
                if (network.modelData.active)
                    network.currentSelected = false;
            }

            target: network.modelData
        }

        Connections {
            function onNetworkSelected(ap: Nmcli.AccessPoint): void {
                if (ap !== network.modelData)
                    network.currentSelected = false;
            }

            target: root
        }

        RowLayout {
            id: networkLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            anchors.leftMargin: Tokens.padding.extraLarge
            anchors.rightMargin: Tokens.padding.extraLarge
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: Icons.getNetworkIcon(network.modelData.strength)
                color: network.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                opacity: network.textOpacity
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                opacity: network.textOpacity

                StyledText {
                    Layout.fillWidth: true
                    text: network.modelData.ssid
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Security: %1%2").arg(network.modelData.security).arg(network.modelData.active ? qsTr(" • Connected") : Nmcli.hasSavedProfile(network.modelData.ssid) ? qsTr(" • Saved") : "")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }

            AnimLoader {
                sourceComp: Nmcli.connectingSsid() === network.modelData.ssid ? loadingComp : iconComp

                Component {
                    id: iconComp

                    MaterialIcon {
                        text: network.modelData.active ? "settings" : "lock"
                        color: network.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                        opacity: network.textOpacity
                    }
                }

                Component {
                    id: loadingComp

                    LoadingIndicator {
                        implicitSize: Math.round(Tokens.font.icon.medium.pointSize * 1.3)
                    }
                }
            }
        }
    }

    StyledProgressBar {
        id: scanningIndicator

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        implicitHeight: Nmcli.scanning ? Tokens.rounding.extraSmall : 0
        indeterminate: true

        Behavior on implicitHeight {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
