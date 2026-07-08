pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property PopoutState popouts
    property var network: null
    property bool isClosing: false

    property bool connecting: false
    property bool hasError: false

    readonly property bool shouldBeVisible: root.popouts.currentName === "enterprisepassword"

    function closeDialog(): void {
        if (isClosing)
            return;

        isClosing = true;
        connecting = false;
        hasError = false;
        identityField.buffer = "";
        passwordField.buffer = "";

        if (root.popouts.currentName === "enterprisepassword")
            root.popouts.currentName = "network";
    }

    function attemptConnect(): void {
        if (!root.network || connecting)
            return;

        if (identityField.buffer.trim().length === 0) {
            identityField.errorState = true;
            identityField.forceActiveFocus();
            return;
        }

        hasError = false;
        connecting = true;

        const params = {
            identity: identityField.buffer.trim(),
            password: passwordField.buffer,
            eapMethod: "peap",
            phase2Method: "mschapv2",
            anonymousIdentity: "",
            domainSuffixMatch: "",
            caCertPath: "",
            verifyCert: false
        };

        NetworkConnection.connectWithEnterpriseCredentials(root.network, params, result => {
            connecting = false;

            if (result && result.success) {
                root.closeDialog();
            } else {
                hasError = true;
                passwordField.buffer = "";
                if (root.network && root.network.ssid && !Nmcli.hasSavedProfile(root.network.ssid))
                    Nmcli.forgetNetwork(root.network.ssid);
            }
        });
    }

    spacing: Tokens.spacing.medium
    implicitWidth: 400
    implicitHeight: card.implicitHeight
    visible: shouldBeVisible || isClosing
    enabled: shouldBeVisible && !isClosing
    focus: enabled

    Component.onCompleted: {
        if (shouldBeVisible)
            focusTimer.start();
    }

    onShouldBeVisibleChanged: {
        if (shouldBeVisible)
            focusTimer.start();
        else {
            identityField.errorState = false;
            hasError = false;
        }
    }

    Keys.onEscapePressed: closeDialog()

    Timer {
        id: focusTimer

        interval: 150
        onTriggered: {
            root.forceActiveFocus();
            identityField.forceActiveFocus();
        }
    }

    StyledRect {
        id: card

        Layout.fillWidth: true
        Layout.preferredWidth: 400
        implicitHeight: content.implicitHeight + Tokens.padding.extraLargeIncreased
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer
        visible: root.shouldBeVisible || root.isClosing
        opacity: root.shouldBeVisible && !root.isClosing ? 1 : 0
        scale: root.shouldBeVisible && !root.isClosing ? 1 : 0.7

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }

        ParallelAnimation {
            running: root.isClosing
            onFinished: {
                if (root.isClosing)
                    root.isClosing = false;
            }

            Anim {
                type: Anim.DefaultEffects
                target: card
                property: "opacity"
                to: 0
            }
            Anim {
                target: card
                property: "scale"
                to: 0.7
            }
        }

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Tokens.padding.large

            spacing: Tokens.spacing.medium

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "lock"
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).build()
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Enter credentials")
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.network?.ssid ? qsTr("Network: %1").arg(root.network.ssid) : qsTr("Network: Unknown")
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.spacing.small
                visible: root.connecting || root.hasError
                text: root.hasError ? qsTr("Connection failed. Please check your credentials and try again.") : qsTr("Connecting...")
                color: root.hasError ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
                Layout.maximumWidth: content.width
            }

            CredField {
                id: identityField

                Layout.topMargin: Tokens.spacing.largeIncreased
                Layout.fillWidth: true
                label: qsTr("Identity")
                onAccepted: passwordField.forceActiveFocus()
                onAdvance: passwordField.forceActiveFocus()
            }

            CredField {
                id: passwordField

                Layout.topMargin: Tokens.spacing.small
                Layout.fillWidth: true
                masked: true
                label: qsTr("Password")
                onAccepted: root.attemptConnect()
                onAdvance: identityField.forceActiveFocus()
            }

            RowLayout {
                Layout.topMargin: Tokens.spacing.medium
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                TextButton {
                    Layout.fillWidth: true
                    Layout.minimumHeight: Tokens.font.body.medium.pointSize + Tokens.padding.medium * 2
                    inactiveColour: Colours.palette.m3secondaryContainer
                    inactiveOnColour: Colours.palette.m3onSecondaryContainer
                    text: qsTr("Cancel")
                    onClicked: root.closeDialog()
                }

                TextButton {
                    Layout.fillWidth: true
                    Layout.minimumHeight: Tokens.font.body.medium.pointSize + Tokens.padding.medium * 2
                    inactiveColour: Colours.palette.m3primary
                    inactiveOnColour: Colours.palette.m3onPrimary
                    enabled: !root.connecting
                    text: qsTr("Connect")
                    onClicked: root.attemptConnect()
                }
            }
        }
    }

    component CredField: FocusScope {
        id: cf

        property bool masked: false
        property string label: ""
        property string buffer: ""
        property bool errorState: false

        signal accepted
        signal advance

        activeFocusOnTab: true
        implicitHeight: Math.max(48, chRow.height + Tokens.padding.medium * 2)
        clip: true

        Keys.onPressed: event => {
            if (!activeFocus)
                forceActiveFocus();

            if (event.key === Qt.Key_Escape) {
                event.accepted = false;
                return;
            }

            if (cf.errorState && event.text && event.text.length > 0)
                cf.errorState = false;

            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                cf.accepted();
                event.accepted = true;
            } else if (event.key === Qt.Key_Tab) {
                cf.advance();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backspace) {
                cf.buffer = event.modifiers & Qt.ControlModifier ? "" : cf.buffer.slice(0, -1);
                event.accepted = true;
            } else if (event.text && event.text.length > 0) {
                cf.buffer += event.text;
                event.accepted = true;
            }
        }

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.large
            color: cf.activeFocus ? Qt.lighter(Colours.tPalette.m3surfaceContainer, 1.05) : Colours.tPalette.m3surfaceContainer
            border.width: cf.activeFocus || cf.errorState ? 4 : 1
            border.color: cf.errorState ? Colours.palette.m3error : (cf.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outline)

            Behavior on border.color {
                CAnim {}
            }

            Behavior on border.width {
                CAnim {}
            }

            Behavior on color {
                CAnim {}
            }
        }

        StateLayer {
            hoverEnabled: false
            cursorShape: Qt.IBeamCursor
            radius: Tokens.rounding.large
            onClicked: cf.forceActiveFocus()
        }

        StyledText {
            anchors.centerIn: parent
            text: cf.label
            color: Colours.palette.m3outline
            font: Tokens.font.mono.medium
            opacity: cf.buffer ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Row {
            id: chRow

            readonly property real pad: Tokens.padding.large

            height: Tokens.font.body.medium.pointSize
            y: (cf.height - height) / 2
            x: {
                const avail = cf.width - pad * 2;
                if (implicitWidth <= avail)
                    return (cf.width - implicitWidth) / 2;
                return cf.width - pad - implicitWidth;
            }
            spacing: Tokens.spacing.extraSmall

            Behavior on x {
                Anim {}
            }

            Repeater {
                model: ScriptModel {
                    values: cf.buffer.split("")
                }

                Item {
                    id: chip

                    required property var modelData

                    implicitWidth: cf.masked ? chRow.height : ltr.implicitWidth
                    implicitHeight: chRow.height

                    opacity: 0
                    scale: 0
                    Component.onCompleted: {
                        opacity = 1;
                        scale = 1;
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Behavior on scale {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    StyledRect {
                        visible: cf.masked
                        anchors.centerIn: parent
                        implicitWidth: chRow.height
                        implicitHeight: chRow.height
                        color: Colours.palette.m3onSurface
                        radius: Tokens.rounding.medium / 2
                    }

                    StyledText {
                        id: ltr

                        visible: !cf.masked
                        anchors.centerIn: parent
                        text: chip.modelData
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.mono.medium
                    }
                }
            }
        }
    }
}
