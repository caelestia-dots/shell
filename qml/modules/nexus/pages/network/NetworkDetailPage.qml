pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// Detail / settings sub-page for the active Wi-Fi network. Reached by tapping
// the active network row (settings icon) on NetworkPage.
PageBase {
    id: root

    readonly property string ssid: nState.selectedNetworkSsid
    readonly property var ap: Nmcli.findNetwork(root.ssid)
    readonly property var details: Nmcli.wirelessDeviceDetails
    readonly property bool isActive: !!Nmcli.active && Nmcli.active.ssid === root.ssid

    // Locally-edited IPv4 form state.
    property string ipMethod: "auto" // "auto" | "auto-dns" | "manual"
    property bool ipLoaded: false
    property bool savingIp: false
    property bool autoconnect: true

    // Snapshot of the saved IPv4 config, so the Apply button only shows up once
    // something actually changed.
    property string origMethod: "auto"
    property string origAddress: ""
    property string origGateway: ""
    property string origDns: ""

    readonly property bool hasChanges: root.ipLoaded && (root.ipMethod !== root.origMethod || (root.ipMethod === "manual" && (addressField.text.trim() !== root.origAddress || gatewayField.text.trim() !== root.origGateway)) || ((root.ipMethod === "manual" || root.ipMethod === "auto-dns") && dnsField.text.trim() !== root.origDns))
    readonly property bool showDnsSettings: root.ipMethod === "manual" || root.ipMethod === "auto-dns"

    function loadIpConfig(): void {
        if (!root.ssid)
            return;
        Nmcli.getIpv4Config(root.ssid, cfg => {
            if (!cfg)
                return;
            root.ipMethod = cfg.method; // "auto" | "auto-dns" | "manual"
            methodSelect.active = cfg.method === "manual" ? manualItem : (cfg.method === "auto-dns" ? autoDnsItem : autoItem);
            addressField.text = cfg.address;
            gatewayField.text = cfg.gateway;
            dnsField.text = cfg.dns;
            root.autoconnect = cfg.autoconnect;
            root.origMethod = cfg.method;
            root.origAddress = cfg.address;
            root.origGateway = cfg.gateway;
            root.origDns = cfg.dns;
            root.ipLoaded = true;
        });
    }

    function saveIpConfig(): void {
        if (!root.ssid)
            return;
        root.savingIp = true;
        Nmcli.setIpv4Config(root.ssid, {
            method: root.ipMethod,
            address: addressField.text.trim(),
            gateway: gatewayField.text.trim(),
            dns: dnsField.text.trim()
        }, result => {
            root.savingIp = false;
            if (!(result && result.success)) {
                if (root.ipMethod === "manual")
                    addressField.isError = true;
                else
                    dnsField.isError = true;
            } else {
                root.origMethod = root.ipMethod;
                root.origAddress = addressField.text.trim();
                root.origGateway = gatewayField.text.trim();
                root.origDns = dnsField.text.trim();
            }
        });
    }

    // Close if the network is no longer active (e.g. disconnected elsewhere).
    // ...But not when the page was opened from saved networks
    onApChanged: {
        if (!nState.networkDetailsFromSaved && root.ipLoaded && !root.ap)
            nState.closeSubPage();
    }

    title: root.ssid || qsTr("Network")
    isSubPage: true

    Component.onCompleted: {
        Nmcli.getWirelessDeviceDetails("", () => {});
        loadIpConfig();
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // ---- Action buttons --------------------------------------------------
        ButtonRow {
            Layout.bottomMargin: Tokens.spacing.large - parent.spacing
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: Math.round(root.cappedWidth * (root.isActive ? 0.7 : 0.5))
            spacing: Tokens.spacing.small

            ButtonBase {
                id: forgetBtn

                fillWidth: true
                shapeMorph: root.isActive
                isRound: true
                inactiveColour: Colours.palette.m3errorContainer
                inactiveOnColour: Colours.palette.m3onErrorContainer

                implicitWidth: forgetLayout.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: forgetLayout.implicitHeight + Tokens.padding.medium * 2

                onClicked: {
                    Nmcli.forgetNetwork(root.ssid);
                    root.nState.closeSubPage();
                }

                ColumnLayout {
                    id: forgetLayout

                    anchors.centerIn: parent
                    spacing: 0

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "delete"
                        color: forgetBtn.onColour
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Forget")
                        color: forgetBtn.onColour
                    }
                }
            }

            ButtonBase {
                id: disconnectBtn

                visible: root.isActive
                fillWidth: true
                shapeMorph: true
                isRound: true
                inactiveColour: Colours.palette.m3primaryContainer
                inactiveOnColour: Colours.palette.m3onPrimaryContainer

                implicitWidth: disconnectLayout.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: disconnectLayout.implicitHeight + Tokens.padding.medium * 2

                onClicked: {
                    Nmcli.disconnectFromNetwork();
                    root.nState.closeSubPage();
                }

                ColumnLayout {
                    id: disconnectLayout

                    anchors.centerIn: parent
                    spacing: 0

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "link_off"
                        color: disconnectBtn.onColour
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Disconnect")
                        color: disconnectBtn.onColour
                    }
                }
            }
        }

        // ---- Connection info (only shows when active) ---------------------------------
        SectionHeader {
            first: true
            text: qsTr("Connection")
            visible: root.isActive
        }

        InfoRow {
            first: true
            icon: "signal_wifi_4_bar"
            label: qsTr("Signal")
            value: root.ap ? qsTr("%1%").arg(root.ap.strength) : qsTr("—")
            visible: root.isActive
        }

        InfoRow {
            icon: "lock"
            label: qsTr("Security")
            value: root.ap?.security || qsTr("Open")
            visible: root.isActive
        }

        InfoRow {
            icon: "graphic_eq"
            label: qsTr("Frequency")
            value: root.ap && root.ap.frequency > 0 ? qsTr("%1 MHz").arg(root.ap.frequency) : qsTr("—")
            visible: root.isActive
        }

        InfoRow {
            icon: "lan"
            label: qsTr("IP address")
            value: root.details?.ipAddress || qsTr("—")
            visible: root.isActive
        }

        InfoRow {
            icon: "router"
            label: qsTr("Gateway")
            value: root.details?.gateway || qsTr("—")
            visible: root.isActive
        }

        InfoRow {
            last: true
            icon: "memory"
            label: qsTr("MAC address")
            value: root.details?.macAddress || qsTr("—")
            visible: root.isActive
        }

        // ---- Behaviour -------------------------------------------------------
        SectionHeader {
            first: !root.isActive
            text: qsTr("Behaviour")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            last: true
            text: qsTr("Connect automatically")
            subtext: qsTr("Join this network when it's in range")
            checked: root.autoconnect
            enabled: root.ipLoaded
            onToggled: {
                root.autoconnect = checked;
                Nmcli.setAutoconnect(root.ssid, checked, () => {});
            }
        }

        // ---- IPv4 ------------------------------------------------------------
        SectionHeader {
            text: qsTr("IPv4")
        }

        SelectRow {
            id: methodSelect

            first: true
            last: root.ipMethod === "auto"
            label: qsTr("IP assignment")
            fallbackText: qsTr("Automatic (DHCP)")
            fallbackIcon: "lan"

            onSelected: item => root.ipMethod = item === manualItem ? "manual" : (item === autoDnsItem ? "auto-dns" : "auto")

            menuItems: [
                MenuItem {
                    id: autoItem

                    icon: "lan"
                    text: qsTr("Automatic (DHCP)")
                },
                MenuItem {
                    id: autoDnsItem

                    icon: "dns"
                    text: qsTr("Automatic, DNS only")
                },
                MenuItem {
                    id: manualItem

                    icon: "edit"
                    text: qsTr("Manual")
                }
            ]

            Behavior on bottomLeftRadius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on bottomRightRadius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        // Address + gateway: manual only. DNS: manual and DNS-only.
        Item {
            Layout.fillWidth: true
            Layout.topMargin: root.showDnsSettings ? Tokens.spacing.large : -parent.spacing
            implicitHeight: root.showDnsSettings ? dnsColumn.implicitHeight : 0
            opacity: root.showDnsSettings ? 1 : 0

            Behavior on Layout.topMargin {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on implicitHeight {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            ColumnLayout {
                id: dnsColumn

                anchors.left: parent.left
                anchors.right: parent.right
                spacing: root.ipMethod === "manual" ? Tokens.spacing.large : 0

                Behavior on spacing {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: root.ipMethod === "manual" ? manualDnsColumn.implicitHeight : 0
                    opacity: root.ipMethod === "manual" ? 1 : 0

                    Behavior on implicitHeight {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    ColumnLayout {
                        id: manualDnsColumn

                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: Tokens.spacing.large

                        StyledTextField {
                            id: addressField

                            Layout.fillWidth: true
                            placeholderText: qsTr("Address (CIDR)")
                            leadingIcon: "router"
                            supportingText: qsTr("IP and prefix, e.g. 192.168.1.50/24")
                            errorText: qsTr("Enter a valid address in CIDR notation")
                            inputMethodHints: Qt.ImhNoPredictiveText
                            validate: /^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)\/(?:3[0-2]|[12]?\d)$/
                        }

                        StyledTextField {
                            id: gatewayField

                            Layout.fillWidth: true
                            placeholderText: qsTr("Gateway")
                            leadingIcon: "exit_to_app"
                            errorText: qsTr("Enter a valid gateway address")
                            inputMethodHints: Qt.ImhNoPredictiveText
                            validate: /^$|^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)$/
                        }
                    }
                }

                StyledTextField {
                    id: dnsField

                    Layout.fillWidth: true
                    placeholderText: qsTr("DNS servers")
                    leadingIcon: "dns"
                    supportingText: qsTr("Comma-separated")
                    errorText: qsTr("Enter valid DNS server addresses")
                    inputMethodHints: Qt.ImhNoPredictiveText
                    validate: /^$|^\s*(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)(?:\s*,\s*(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d))*\s*$/
                }
            }
        }

        // Apply button — swaps to a loading spinner while applying, matching the
        // connect animation used in the Wi-Fi list. Only shown once the form
        // actually diverges from the saved config.
        Item {
            Layout.alignment: Qt.AlignRight
            implicitWidth: applyBtn.implicitWidth
            implicitHeight: root.hasChanges || root.savingIp ? applyBtn.implicitHeight : 0
            opacity: root.hasChanges || root.savingIp ? 1 : 0

            Behavior on implicitHeight {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            ButtonBase {
                id: applyBtn

                shapeMorph: true
                isRound: true
                inactiveColour: Colours.palette.m3primary
                inactiveOnColour: Colours.palette.m3onPrimary
                stateLayer.disabled: !root.ipLoaded || root.savingIp

                implicitWidth: applyMetrics.width + Tokens.padding.extraLarge * 2
                implicitHeight: applyMetrics.height + Tokens.padding.medium * 2

                onClicked: {
                    if (root.ipLoaded && !root.savingIp)
                        root.saveIpConfig();
                }

                TextMetrics {
                    id: applyMetrics

                    text: qsTr("Apply")
                    font: applyBtn.font
                }

                AnimLoader {
                    id: applyContent

                    anchors.centerIn: parent
                    sourceComp: root.savingIp ? applyLoadingComp : applyTextComp
                    outAnimType: Anim.SlowEffects
                    inAnimType: Anim.SlowEffects
                }

                Component {
                    id: applyLoadingComp

                    LoadingIndicator {
                        implicitSize: Math.round(Tokens.font.body.medium.pointSize * 1.4)
                        color: applyBtn.onColour
                    }
                }

                Component {
                    id: applyTextComp

                    StyledText {
                        text: applyMetrics.text
                        font: applyBtn.font
                        color: applyBtn.onColour
                    }
                }
            }
        }
    }
}
