pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property Nmcli.AccessPoint network: nState.selectedWifiNetwork ?? null
    readonly property string ssid: root.network?.ssid ?? ""

    property string eapMethod: "peap"
    property string phase2Method: "mschapv2"
    property bool showAdvanced: false
    property bool connecting: false
    property bool hasError: false
    property string errorMessage: ""

    function attemptConnect(): void {
        if (!root.network || root.connecting) {
            return;
        }
        if (identityField.text.trim().length === 0) {
            identityField.isError = true;
            return;
        }

        root.hasError = false;
        root.connecting = true;

        const params = {
            identity: identityField.text.trim(),
            password: passwordField.text,
            eapMethod: root.eapMethod,
            phase2Method: root.phase2Method,
            anonymousIdentity: anonIdentityField.text.trim(),
            domainSuffixMatch: domainSuffixField.text.trim(),
            caCertPath: caCertField.text.trim(),
            verifyCert: verifyCertToggle.checked
        };

        NetworkConnection.connectWithEnterpriseCredentials(root.network, params, result => {
            root.connecting = false;

            if (result && result.success) {
                root.hasError = false;
                nState.closeSubPage();
            } else {
                root.hasError = true;
                root.errorMessage = qsTr("Connection failed. Check your identity, password and EAP settings.");
            }
        });
    }

    title: root.ssid.length > 0 ? root.ssid : qsTr("Enterprise network")
    isSubPage: true

    Component.onCompleted: {
        eapSelect.active = peapItem;
        phase2Select.active = mschapv2Item;

        if (root.ssid.length > 0 && Nmcli.hasSavedProfile(root.ssid)) {
            Nmcli.getEnterpriseConfig(root.ssid, cfg => {
                if (!cfg)
                    return;
                identityField.text = cfg.identity;
                anonIdentityField.text = cfg.anonymousIdentity;
                domainSuffixField.text = cfg.domainSuffixMatch;
                caCertField.text = cfg.caCertPath;
                root.eapMethod = cfg.eapMethod;
                root.phase2Method = cfg.phase2Method;
                eapSelect.active = cfg.eapMethod === "tls" ? tlsItem : (cfg.eapMethod === "ttls" ? ttlsItem : peapItem);
                phase2Select.active = cfg.phase2Method === "pap" ? papItem : (cfg.phase2Method === "gtc" ? gtcItem : (cfg.phase2Method === "md5" ? md5Item : mschapv2Item));
            });
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Credentials")
        }

        M3TextField {
            id: identityField

            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            label: qsTr("Identity")
            placeholder: qsTr("matricula@instituicao.edu.br")
            leadingIcon: "person"
            supportingText: qsTr("Usually your ID/matrícula followed by @ and your institution's domain")
            errorText: qsTr("Identity is required")
            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        }

        M3TextField {
            id: passwordField

            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            label: qsTr("Password")
            leadingIcon: "lock"
            password: true
            inputMethodHints: Qt.ImhNoPredictiveText
            onAccepted: root.attemptConnect()
        }

        SectionHeader {
            text: qsTr("Authentication method")
        }

        SelectRow {
            id: eapSelect

            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            first: true
            last: root.eapMethod === "tls"
            label: qsTr("EAP method")
            fallbackText: qsTr("PEAP")
            fallbackIcon: "security"

            menuItems: [peapItem, ttlsItem, tlsItem]

            onSelected: item => {
                root.eapMethod = item === tlsItem ? "tls" : (item === ttlsItem ? "ttls" : "peap");
            }

            MenuItem {
                id: peapItem

                icon: "security"
                text: qsTr("PEAP")
            }

            MenuItem {
                id: ttlsItem

                icon: "security"
                text: qsTr("TTLS")
            }

            MenuItem {
                id: tlsItem

                icon: "security"
                text: qsTr("TLS")
            }
        }

        SelectRow {
            id: phase2Select

            Layout.fillWidth: true
            visible: root.eapMethod !== "tls"
            last: true
            label: qsTr("Phase 2 authentication")
            fallbackText: qsTr("MSCHAPv2")
            fallbackIcon: "verified_user"

            menuItems: [mschapv2Item, papItem, gtcItem, md5Item]

            onSelected: item => {
                root.phase2Method = item === papItem ? "pap" : (item === gtcItem ? "gtc" : (item === md5Item ? "md5" : "mschapv2"));
            }

            MenuItem {
                id: mschapv2Item

                icon: "verified_user"
                text: qsTr("MSCHAPv2")
            }

            MenuItem {
                id: papItem

                icon: "verified_user"
                text: qsTr("PAP")
            }

            MenuItem {
                id: gtcItem

                icon: "verified_user"
                text: qsTr("GTC")
            }

            MenuItem {
                id: md5Item

                icon: "verified_user"
                text: qsTr("MD5")
            }
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.large
            first: true
            last: !root.showAdvanced
            text: qsTr("Advanced options")
            font: Tokens.font.body.medium
            horizontalPadding: Tokens.padding.largeIncreased
            checked: root.showAdvanced
            onToggled: root.showAdvanced = checked
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            spacing: Tokens.spacing.large
            visible: root.showAdvanced

            M3TextField {
                id: anonIdentityField

                Layout.fillWidth: true
                label: qsTr("Anonymous identity")
                placeholder: qsTr("anonymous@instituicao.edu.br")
                leadingIcon: "visibility_off"
                supportingText: qsTr("Optional — outer identity sent before the TLS tunnel is established")
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
            }

            M3TextField {
                id: domainSuffixField

                Layout.fillWidth: true
                label: qsTr("Domain suffix match")
                placeholder: qsTr("instituicao.edu.br")
                leadingIcon: "domain"
                supportingText: qsTr("Optional — restricts which server certificate domains are accepted")
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
            }

            M3TextField {
                id: caCertField

                Layout.fillWidth: true
                label: qsTr("CA certificate path")
                placeholder: qsTr("/etc/ssl/certs/eduroam-ca.pem")
                leadingIcon: "folder"
                supportingText: qsTr("Optional — path to a CA certificate to validate the RADIUS server")
                inputMethodHints: Qt.ImhNoPredictiveText
            }

            ToggleRow {
                id: verifyCertToggle

                Layout.fillWidth: true
                first: true
                last: true
                text: qsTr("Verify server certificate")
                subtext: qsTr("Disable only if you know what you're doing — this weakens security")
                enabled: caCertField.text.trim().length === 0
                checked: caCertField.text.trim().length === 0
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.medium
            visible: root.hasError
            text: root.errorMessage
            color: Colours.palette.m3error
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        ButtonRow {
            Layout.topMargin: Tokens.spacing.large
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: Math.round(root.cappedWidth * 0.5)
            spacing: Tokens.spacing.small

            ButtonBase {
                id: connectBtn

                fillWidth: true
                shapeMorph: true
                isRound: true
                inactiveColour: Colours.palette.m3primary
                inactiveOnColour: Colours.palette.m3onPrimary
                stateLayer.disabled: root.connecting

                implicitWidth: connectLayout.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: connectLayout.implicitHeight + Tokens.padding.medium * 2

                onClicked: root.attemptConnect()

                AnimLoader {
                    id: connectLayout

                    anchors.centerIn: parent
                    sourceComp: root.connecting ? loadingComp : textComp

                    Component {
                        id: textComp

                        RowLayout {
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: "wifi_lock"
                                color: connectBtn.onColour
                                fontStyle: Tokens.font.icon.medium
                            }

                            StyledText {
                                text: root.network?.active ? qsTr("Reconnect") : qsTr("Connect")
                                color: connectBtn.onColour
                            }
                        }
                    }

                    Component {
                        id: loadingComp

                        LoadingIndicator {
                            implicitSize: Math.round(Tokens.font.body.medium.pointSize * 1.4)
                            color: connectBtn.onColour
                        }
                    }
                }
            }

            ButtonBase {
                id: disconnectBtn

                visible: root.network?.active ?? false
                fillWidth: true
                shapeMorph: true
                isRound: true
                inactiveColour: Colours.palette.m3secondaryContainer
                inactiveOnColour: Colours.palette.m3onSecondaryContainer

                implicitWidth: disconnectLayout.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: disconnectLayout.implicitHeight + Tokens.padding.medium * 2

                onClicked: Nmcli.disconnectFromNetwork()

                RowLayout {
                    id: disconnectLayout

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "link_off"
                        color: disconnectBtn.onColour
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        text: qsTr("Disconnect")
                        color: disconnectBtn.onColour
                    }
                }
            }

            ButtonBase {
                id: forgetBtn

                visible: root.ssid.length > 0 && Nmcli.hasSavedProfile(root.ssid)
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

                RowLayout {
                    id: forgetLayout

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "delete"
                        color: forgetBtn.onColour
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        text: qsTr("Forget network")
                        color: forgetBtn.onColour
                    }
                }
            }
        }
    }
}
