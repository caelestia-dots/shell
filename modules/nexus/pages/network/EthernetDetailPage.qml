pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// Detail / settings sub-page for an ethernet device. Reached by tapping an
// ethernet row on NetworkPage.
PageBase {
    id: root

    readonly property string ifaceName: nState.selectedEthernetInterface
    readonly property Nmcli.EthernetDevice device: Nmcli.ethernetDevices.find(d => d.iface === root.ifaceName) ?? null
    readonly property var details: Nmcli.ethernetDeviceDetails
    readonly property string connectionName: root.device?.connection ?? ""

    // Locally-edited IPv4 form state.
    property string ipMethod: "auto" // "auto" | "auto-dns" | "manual"
    property bool ipLoaded: false
    property bool savingIp: false

    // Original loaded values, so the Apply button only shows on a real change.
    property string origMethod: "auto"
    property string origAddress: ""
    property string origGateway: ""
    property string origDns: ""

    readonly property bool hasChanges: root.ipLoaded && (root.ipMethod !== root.origMethod || (root.ipMethod === "manual" && (addressField.text.trim() !== root.origAddress || gatewayField.text.trim() !== root.origGateway)) || ((root.ipMethod === "manual" || root.ipMethod === "auto-dns") && dnsField.text.trim() !== root.origDns))

    function loadIpConfig(): void {
        if (!root.connectionName)
            return;
        Nmcli.getIpv4Config(root.connectionName, cfg => {
            if (!cfg)
                return;
            root.ipMethod = cfg.method;
            methodSelect.active = cfg.method === "manual" ? manualItem : (cfg.method === "auto-dns" ? autoDnsItem : autoItem);
            addressField.text = cfg.address;
            gatewayField.text = cfg.gateway;
            dnsField.text = cfg.dns;
            root.origMethod = cfg.method;
            root.origAddress = cfg.address;
            root.origGateway = cfg.gateway;
            root.origDns = cfg.dns;
            root.ipLoaded = true;
        });
    }

    function saveIpConfig(): void {
        if (!root.connectionName)
            return;

        // Bail out and flag the offending field before touching nmcli.
        if (root.ipMethod === "manual") {
            if (!addressField.valid) {
                addressField.isError = true;
                return;
            }
            if (!gatewayField.valid) {
                gatewayField.isError = true;
                return;
            }
        }
        if ((root.ipMethod === "manual" || root.ipMethod === "auto-dns") && !dnsField.valid) {
            dnsField.isError = true;
            return;
        }

        root.savingIp = true;
        Nmcli.setIpv4Config(root.connectionName, {
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
                // Persisted — make the current values the new baseline so the
                // Apply button hides again until something else changes.
                root.origMethod = root.ipMethod;
                root.origAddress = addressField.text.trim();
                root.origGateway = gatewayField.text.trim();
                root.origDns = dnsField.text.trim();
            }
        });
    }

    title: root.device?.connection || root.ifaceName || Tr.tr("Ethernet")
    isSubPage: true

    Component.onCompleted: {
        Nmcli.getEthernetDeviceDetails(root.ifaceName, () => {});
        Nmcli.getEthernetSpeed(root.ifaceName);
        loadIpConfig();
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // ---- Action button --------------------------------------------------
        ButtonRow {
            Layout.bottomMargin: Tokens.spacing.large - parent.spacing
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: Math.round(root.cappedWidth * 0.5)
            spacing: Tokens.spacing.small

            ButtonBase {
                id: connectBtn

                fillWidth: true
                shapeMorph: true
                isRound: true
                inactiveColour: root.device?.connected ? Colours.palette.m3primaryContainer : Colours.palette.m3secondaryContainer
                inactiveOnColour: root.device?.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSecondaryContainer

                implicitWidth: connectLayout.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: connectLayout.implicitHeight + Tokens.padding.medium * 2

                onClicked: {
                    if (root.device?.connected)
                        Nmcli.disconnectEthernet(root.connectionName);
                    else
                        Nmcli.connectEthernet(root.connectionName, root.ifaceName);
                }

                ColumnLayout {
                    id: connectLayout

                    anchors.centerIn: parent
                    spacing: 0

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.device?.connected ? "link_off" : "link"
                        color: connectBtn.onColour
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.device?.connected ? Tr.tr("Disconnect") : Tr.tr("Connect")
                        color: connectBtn.onColour
                    }
                }
            }
        }

        // ---- Connection info ------------------------------------------------
        SectionHeader {
            first: true
            text: Tr.tr("Connection")
        }

        InfoRow {
            first: true
            icon: "link"
            label: Tr.tr("Status")
            value: root.device?.connected ? Tr.trCtx("Connected", "ethernet link state") : Tr.trCtx("Not connected", "ethernet link state")
        }

        InfoRow {
            icon: "settings_ethernet"
            label: Tr.trCtx("Interface", "network interface")
            value: root.ifaceName || "—"
        }

        InfoRow {
            icon: "speed"
            label: Tr.tr("Speed")
            visible: Nmcli.ethernetSpeed.length > 0
            value: Nmcli.ethernetSpeed
        }

        InfoRow {
            icon: "lan"
            label: Tr.tr("IP address")
            value: root.details?.ipAddress || "—"
        }

        InfoRow {
            icon: "router"
            label: Tr.tr("Gateway")
            value: root.details?.gateway || "—"
        }

        InfoRow {
            last: true
            icon: "memory"
            label: Tr.tr("MAC address")
            value: root.details?.macAddress || "—"
        }

        // ---- IPv4 ------------------------------------------------------------
        SectionHeader {
            text: Tr.tr("IPv4")
        }

        SelectRow {
            id: methodSelect

            Layout.fillWidth: true
            first: true
            last: root.ipMethod === "auto"
            label: Tr.tr("IP assignment")
            fallbackText: Tr.tr("Automatic (DHCP)")
            fallbackIcon: "lan"

            menuItems: [autoItem, autoDnsItem, manualItem]

            onSelected: item => root.ipMethod = item === manualItem ? "manual" : (item === autoDnsItem ? "auto-dns" : "auto")

            MenuItem {
                id: autoItem

                icon: "lan"
                text: Tr.tr("Automatic (DHCP)")
            }

            MenuItem {
                id: autoDnsItem

                icon: "dns"
                text: Tr.tr("Automatic, DNS only")
            }

            MenuItem {
                id: manualItem

                icon: "edit"
                text: Tr.trCtx("Manual", "ip configuration method")
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            spacing: Tokens.spacing.large
            visible: root.ipMethod === "manual" || root.ipMethod === "auto-dns"

            StyledTextField {
                id: addressField

                Layout.fillWidth: true
                visible: root.ipMethod === "manual"
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
                visible: root.ipMethod === "manual"
                placeholderText: Tr.tr("Gateway")
                leadingIcon: "exit_to_app"
                errorText: Tr.tr("Enter a valid gateway address")
                inputMethodHints: Qt.ImhNoPredictiveText
                validate: /^$|^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)$/
            }

            StyledTextField {
                id: dnsField

                Layout.fillWidth: true
                placeholderText: Tr.tr("DNS servers")
                leadingIcon: "dns"
                supportingText: Tr.tr("Comma-separated")
                errorText: Tr.tr("Enter valid DNS server addresses")
                inputMethodHints: Qt.ImhNoPredictiveText
                validate: /^$|^\s*(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)(?:\s*,\s*(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d))*\s*$/
            }
        }

        // Apply button — swaps to a loading spinner while applying. Shown only
        // when the IP assignment has unsaved changes.
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            spacing: Tokens.spacing.medium
            visible: root.hasChanges || root.savingIp

            Item {
                Layout.fillWidth: true
            }

            ButtonBase {
                id: applyBtn

                shapeMorph: true
                isRound: true
                inactiveColour: Colours.palette.m3primary
                inactiveOnColour: Colours.palette.m3onPrimary
                stateLayer.disabled: !root.ipLoaded || root.savingIp

                implicitWidth: applyContent.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: applyContent.implicitHeight + Tokens.padding.medium * 2

                onClicked: if (root.ipLoaded && !root.savingIp)
                    root.saveIpConfig()

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
                        text: Tr.tr("Apply")
                        color: applyBtn.onColour
                        animate: true
                    }
                }
            }
        }
    }
}
