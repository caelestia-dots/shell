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

    property bool connecting: false
    property bool hasError: false

    function attemptConnect(): void {
        if (!root.network || root.connecting) {
            return;
        }

        root.hasError = false;
        root.connecting = true;

        NetworkConnection.connectWithPassword(root.network, passwordField.text, result => {
            root.connecting = false;

            if (result && result.success) {
                nState.closeSubPage();
            } else {
                root.hasError = true;
                passwordField.isError = true;
            }
        });
    }

    title: root.ssid.length > 0 ? root.ssid : qsTr("Enter password")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Password")
        }

        M3TextField {
            id: passwordField

            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            label: qsTr("Password")
            leadingIcon: "lock"
            password: true
            errorText: qsTr("Incorrect password — try again")
            inputMethodHints: Qt.ImhNoPredictiveText
            onAccepted: root.attemptConnect()
        }

        ButtonRow {
            Layout.topMargin: Tokens.spacing.large
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: Math.round(root.cappedWidth * 0.5)

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
                                text: "wifi"
                                color: connectBtn.onColour
                                fontStyle: Tokens.font.icon.medium
                            }

                            StyledText {
                                text: qsTr("Connect")
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
        }
    }
}
