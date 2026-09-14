pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils
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

    title: root.ssid || Tr.tr("Network")
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
                        text: Tr.tr("Forget")
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
                        text: Tr.tr("Disconnect")
                        color: disconnectBtn.onColour
                    }
                }
            }
        }

        // ---- Connection info (only shows when active) ---------------------------------
        SectionHeader {
            first: true
            text: Tr.tr("Connection")
            visible: root.isActive
        }

        InfoRow {
            first: true
            icon: "signal_wifi_4_bar"
            label: Tr.tr("Signal")
            value: root.ap ? Strings.percent(root.ap.strength) : "—"
            visible: root.isActive
        }

        InfoRow {
            icon: "lock"
            label: Tr.tr("Security")
            value: root.ap?.security || Tr.trCtx("Open", "wifi security type")
            visible: root.isActive
        }

        InfoRow {
            icon: "graphic_eq"
            label: Tr.tr("Frequency")
            // TRANSLATORS: %1 = channel frequency; MHz is a unit, leave it untranslated
            value: root.ap && root.ap.frequency > 0 ? Tr.tr("%1 MHz").arg(root.ap.frequency) : "—"
            visible: root.isActive
        }

        InfoRow {
            icon: "lan"
            label: Tr.tr("IP address")
            value: root.details?.ipAddress || "—"
            visible: root.isActive
        }

        InfoRow {
            icon: "router"
            label: Tr.tr("Gateway")
            value: root.details?.gateway || "—"
            visible: root.isActive
        }

        InfoRow {
            last: true
            icon: "memory"
            label: Tr.tr("MAC address")
            value: root.details?.macAddress || "—"
            visible: root.isActive
        }

        // ---- Behaviour -------------------------------------------------------
        SectionHeader {
            first: !root.isActive
            text: Tr.tr("Behaviour")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            last: true
            text: Tr.tr("Connect automatically")
            subtext: Tr.tr("Join this network when it's in range")
            checked: root.autoconnect
            enabled: root.ipLoaded
            onToggled: {
                root.autoconnect = checked;
                Nmcli.setAutoconnect(root.ssid, checked, () => {});
            }
        }

        // ---- IPv4 ------------------------------------------------------------
        SectionHeader {
            text: Tr.tr("IPv4")
        }

        SelectRow {
            id: methodSelect

            first: true
            last: root.ipMethod === "auto"
            label: Tr.tr("IP assignment")
            // TRANSLATORS: DHCP and DNS are protocol names, leave them untranslated
            fallbackText: Tr.tr("Automatic (DHCP)")
            fallbackIcon: "lan"

            onSelected: item => root.ipMethod = item === manualItem ? "manual" : (item === autoDnsItem ? "auto-dns" : "auto")

            menuItems: [
                MenuItem {
                    id: autoItem

                    icon: "lan"
                    text: Tr.tr("Automatic (DHCP)")
                },
                MenuItem {
                    id: autoDnsItem

                    icon: "dns"
                    text: Tr.tr("Automatic, DNS only")
                },
                MenuItem {
                    id: manualItem

                    icon: "edit"
                    text: Tr.trCtx("Manual", "ip configuration method")
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
                            // TRANSLATORS: CIDR is a networking term, leave it untranslated
                            placeholderText: Tr.tr("Address (CIDR)")
                            leadingIcon: "router"
                            supportingText: Tr.tr("IP and prefix, e.g. 192.168.1.50/24")
                            errorText: Tr.tr("Enter a valid address in CIDR notation")
                            inputMethodHints: Qt.ImhNoPredictiveText
                            validate: /^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)\/(?:3[0-2]|[12]?\d)$/
                        }

                        StyledTextField {
                            id: gatewayField

                            Layout.fillWidth: true
                            placeholderText: Tr.tr("Gateway")
                            leadingIcon: "exit_to_app"
                            errorText: Tr.tr("Enter a valid gateway address")
                            inputMethodHints: Qt.ImhNoPredictiveText
                            validate: /^$|^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)$/
                        }
                    }
                }

                StyledTextField {
                    id: dnsField

                    Layout.fillWidth: true
                    placeholderText: Tr.tr("DNS servers")
                    leadingIcon: "dns"
                    // TRANSLATORS: describes the DNS servers field above: several addresses separated by commas
                    supportingText: Tr.tr("Comma-separated")
                    errorText: Tr.tr("Enter valid DNS server addresses")
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

                    text: Tr.tr("Apply")
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
