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

    // Locally-edited IPv4 form state.
    property string ipMethod: "auto" // "auto" | "auto-dns" | "manual"
    property bool ipLoaded: false
    property bool savingIp: false
    property bool autoconnect: true

    // Snapshot of the saved IPv4 config, so the Apply button only shows up once
    // something actually changed.
    property string _origMethod: "auto"
    property string _origAddress: ""
    property string _origGateway: ""
    property string _origDns: ""

    readonly property bool hasChanges: root.ipLoaded && (root.ipMethod !== root._origMethod || (root.ipMethod === "manual" && (addressField.text.trim() !== root._origAddress || gatewayField.text.trim() !== root._origGateway)) || ((root.ipMethod === "manual" || root.ipMethod === "auto-dns") && dnsField.text.trim() !== root._origDns))

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
            root._origMethod = cfg.method;
            root._origAddress = cfg.address;
            root._origGateway = cfg.gateway;
            root._origDns = cfg.dns;
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
                root._origMethod = root.ipMethod;
                root._origAddress = addressField.text.trim();
                root._origGateway = gatewayField.text.trim();
                root._origDns = dnsField.text.trim();
            }
        });
    }

    // Close if the network is no longer active (e.g. disconnected elsewhere).
    onApChanged: {
        if (root.ipLoaded && !root.ap)
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
            Layout.minimumWidth: Math.round(root.cappedWidth * 0.7)
            spacing: Tokens.spacing.small

            ButtonBase {
                id: forgetBtn

                fillWidth: true
                shapeMorph: true
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

        // ---- Connection info -------------------------------------------------
        SectionHeader {
            first: true
            text: qsTr("Connection")
        }

        InfoRow {
            first: true
            icon: "signal_wifi_4_bar"
            label: qsTr("Signal")
            value: root.ap ? qsTr("%1%").arg(root.ap.strength) : qsTr("—")
        }

        InfoRow {
            icon: "lock"
            label: qsTr("Security")
            value: root.ap?.security || qsTr("Open")
        }

        InfoRow {
            icon: "graphic_eq"
            label: qsTr("Frequency")
            value: root.ap && root.ap.frequency > 0 ? qsTr("%1 MHz").arg(root.ap.frequency) : qsTr("—")
        }

        InfoRow {
            icon: "lan"
            label: qsTr("IP address")
            value: root.details?.ipAddress || qsTr("—")
        }

        InfoRow {
            icon: "router"
            label: qsTr("Gateway")
            value: root.details?.gateway || qsTr("—")
        }

        InfoRow {
            last: true
            icon: "memory"
            label: qsTr("MAC address")
            value: root.details?.macAddress || qsTr("—")
        }

        // ---- Behaviour -------------------------------------------------------
        SectionHeader {
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

            Layout.fillWidth: true
            first: true
            last: root.ipMethod === "auto"
            label: qsTr("IP assignment")
            fallbackText: qsTr("Automatic (DHCP)")
            fallbackIcon: "lan"

            menuItems: [autoItem, autoDnsItem, manualItem]

            onSelected: item => {
                root.ipMethod = item === manualItem ? "manual" : (item === autoDnsItem ? "auto-dns" : "auto");
            }

            MenuItem {
                id: autoItem

                icon: "lan"
                text: qsTr("Automatic (DHCP)")
            }

            MenuItem {
                id: autoDnsItem

                icon: "dns"
                text: qsTr("Automatic, DNS only")
            }

            MenuItem {
                id: manualItem

                icon: "edit"
                text: qsTr("Manual")
            }
        }

        // Address + gateway: manual only. DNS: manual and DNS-only.
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            spacing: Tokens.spacing.large
            visible: root.ipMethod === "manual" || root.ipMethod === "auto-dns"

            M3TextField {
                id: addressField

                Layout.fillWidth: true
                visible: root.ipMethod === "manual"
                label: qsTr("Address (CIDR)")
                placeholder: qsTr("192.168.1.50/24")
                leadingIcon: "router"
                supportingText: qsTr("IP and prefix, e.g. 192.168.1.50/24")
                errorText: qsTr("Enter a valid address in CIDR notation")
                inputMethodHints: Qt.ImhNoPredictiveText
            }

            M3TextField {
                id: gatewayField

                Layout.fillWidth: true
                visible: root.ipMethod === "manual"
                label: qsTr("Gateway")
                placeholder: qsTr("192.168.1.1")
                leadingIcon: "exit_to_app"
                inputMethodHints: Qt.ImhNoPredictiveText
            }

            M3TextField {
                id: dnsField

                Layout.fillWidth: true
                label: qsTr("DNS servers")
                placeholder: qsTr("1.1.1.1, 8.8.8.8")
                leadingIcon: "dns"
                supportingText: qsTr("Comma-separated")
                errorText: qsTr("Enter valid DNS server addresses")
                inputMethodHints: Qt.ImhNoPredictiveText
            }
        }

        // Apply button — swaps to a loading spinner while applying, matching the
        // connect animation used in the Wi-Fi list. Only shown once the form
        // actually diverges from the saved config.
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
                        text: qsTr("Apply")
                        color: applyBtn.onColour
                        animate: true
                    }
                }
            }
        }
    }
}
