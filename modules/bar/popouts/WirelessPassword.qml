pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property PopoutState popouts
    property var network: null
    property bool isClosing: false

    readonly property bool shouldBeVisible: root.popouts.currentName === "wirelesspassword"

    function closeDialog(): void {
        if (isClosing) {
            return;
        }

        isClosing = true;
        passwordContainer.passwordBuffer = "";
        connectButton.connecting = false;
        connectButton.hasError = false;

        // Return to network popout
        if (root.popouts.currentName === "wirelesspassword") {
            root.popouts.currentName = "network";
        }
    }

    spacing: Tokens.spacing.medium
    implicitWidth: 400
    implicitHeight: content.implicitHeight + Tokens.padding.extraLargeIncreased
    visible: shouldBeVisible || isClosing
    enabled: shouldBeVisible && !isClosing
    focus: enabled

    Component.onCompleted: {
        if (shouldBeVisible) {
            // Use Timer for actual delay to ensure dialog is fully rendered
            focusTimer.start();
        }
    }

    onShouldBeVisibleChanged: {
        if (shouldBeVisible) {
            // Use Timer for actual delay to ensure dialog is fully rendered
            focusTimer.start();
        }
    }

    Keys.onEscapePressed: closeDialog()

    Connections {
        function onCurrentNameChanged() {
            if (root.popouts.currentName === "wirelesspassword") {
                // Update network when popout becomes active
                Qt.callLater(() => {
                    // Try to get network from parent Content's networkPopout
                    const content = root.parent?.parent?.parent;
                    if (content) {
                        const networkPopout = content.children.find(c => c.name === "network");
                        if (networkPopout && networkPopout.item) {
                            root.network = networkPopout.item.passwordNetwork;
                        }
                    }
                    // Force focus to password container when popout becomes active
                    // Use Timer for actual delay to ensure dialog is fully rendered
                    focusTimer.start();
                });
            }
        }

        target: root.popouts
    }

    Timer {
        id: focusTimer

        interval: 150
        onTriggered: {
            root.forceActiveFocus();
            passwordContainer.forceActiveFocus();
        }
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.preferredWidth: 400
        implicitHeight: content.implicitHeight + Tokens.padding.extraLargeIncreased
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer
        visible: root.shouldBeVisible || root.isClosing
        opacity: root.shouldBeVisible && !root.isClosing ? 1 : 0
        scale: root.shouldBeVisible && !root.isClosing ? 1 : 0.7
        Keys.onEscapePressed: root.closeDialog()

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
                if (root.isClosing) {
                    root.isClosing = false;
                }
            }

            Anim {
                type: Anim.DefaultEffects
                target: parent
                property: "opacity"
                to: 0
            }
            Anim {
                target: parent
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
                text: Tr.tr("Enter password")
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }

            StyledText {
                id: networkNameText

                Layout.alignment: Qt.AlignHCenter
                text: {
                    if (root.network) {
                        const ssid = root.network.ssid;
                        if (ssid && ssid.length > 0) {
                            // TRANSLATORS: %1 = the network SSID
                            return Tr.tr("Network: %1").arg(ssid);
                        }
                    }
                    return Tr.tr("Unknown network");
                }
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
            }

            Timer {
                property int attempts: 0

                interval: 50
                running: root.shouldBeVisible && (!root.network || !root.network.ssid)
                repeat: true
                onTriggered: {
                    attempts++;
                    // Keep trying to get network from Network component
                    const content = root.parent?.parent?.parent;
                    if (content) {
                        const networkPopout = content.children.find(c => c.name === "network");
                        if (networkPopout && networkPopout.item && networkPopout.item.passwordNetwork) {
                            root.network = networkPopout.item.passwordNetwork;
                        }
                    }
                    // Stop if we got it or after 20 attempts (1 second)
                    if ((root.network && root.network.ssid) || attempts >= 20) {
                        stop();
                        attempts = 0;
                    }
                }
                onRunningChanged: {
                    if (!running) {
                        attempts = 0;
                    }
                }
            }

            StyledText {
                id: statusText

                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.spacing.small
                visible: connectButton.connecting || connectButton.hasError
                text: {
                    if (connectButton.hasError) {
                        return Tr.tr("Connection failed. Please check your password and try again.");
                    }
                    if (connectButton.connecting) {
                        return Tr.tr("Connecting...");
                    }
                    return "";
                }
                color: connectButton.hasError ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.small.weight(Font.Normal).build()
                wrapMode: Text.WordWrap
                Layout.maximumWidth: parent.width - Tokens.padding.extraLargeIncreased
            }

            FocusScope {
                id: passwordContainer

                property string passwordBuffer: ""

                objectName: "passwordContainer"
                Layout.topMargin: Tokens.spacing.largeIncreased
                Layout.fillWidth: true
                implicitHeight: Math.max(48, charList.implicitHeight + Tokens.padding.medium * 2)
                focus: true
                activeFocusOnTab: true

                Component.onCompleted: {
                    if (root.shouldBeVisible) {
                        // Use Timer for actual delay to ensure focus works correctly
                        passwordFocusTimer.start();
                    }
                }

                Keys.onPressed: event => {
                    // Ensure we have focus when receiving keyboard input
                    if (!activeFocus) {
                        forceActiveFocus();
                    }

                    if (event.key === Qt.Key_Escape) {
                        event.accepted = false;
                        closeDialog();
                    }

                    // Clear error when user starts typing
                    if (connectButton.hasError && event.text && event.text.length > 0) {
                        connectButton.hasError = false;
                    }

                    if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        if (connectButton.enabled) {
                            connectButton.clicked();
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Backspace) {
                        if (event.modifiers & Qt.ControlModifier) {
                            passwordBuffer = "";
                        } else {
                            passwordBuffer = passwordBuffer.slice(0, -1);
                        }
                        event.accepted = true;
                    } else if (event.text && event.text.length > 0) {
                        if (event.key === Qt.Key_Tab) {
                            event.accepted = false;
                            return;
                        }
                        passwordBuffer += event.text;
                        event.accepted = true;
                    }
                }

                Connections {
                    function onShouldBeVisibleChanged(): void {
                        if (root.shouldBeVisible) {
                            // Use Timer for actual delay to ensure focus works correctly
                            passwordFocusTimer.start();
                            passwordContainer.passwordBuffer = "";
                            connectButton.hasError = false;
                        }
                    }

                    target: root
                }

                Timer {
                    id: passwordFocusTimer

                    interval: 50
                    onTriggered: {
                        passwordContainer.forceActiveFocus();
                    }
                }

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.large
                    color: passwordContainer.activeFocus ? Qt.lighter(Colours.tPalette.m3surfaceContainer, 1.05) : Colours.tPalette.m3surfaceContainer
                    border.width: passwordContainer.activeFocus || connectButton.hasError ? 4 : (root.shouldBeVisible ? 1 : 0)
                    border.color: {
                        if (connectButton.hasError) {
                            return Colours.palette.m3error;
                        }
                        if (passwordContainer.activeFocus) {
                            return Colours.palette.m3primary;
                        }
                        return root.shouldBeVisible ? Colours.palette.m3outline : "transparent";
                    }

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
                    onClicked: passwordContainer.forceActiveFocus()
                }

                StyledText {
                    id: placeholder

                    anchors.centerIn: parent
                    text: Tr.tr("Password")
                    color: Colours.palette.m3outline
                    font: Tokens.font.mono.medium
                    opacity: passwordContainer.passwordBuffer ? 0 : 1

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                ListView {
                    id: charList

                    readonly property int fullWidth: count * (implicitHeight + spacing) - spacing

                    anchors.centerIn: parent
                    implicitWidth: fullWidth
                    implicitHeight: Tokens.font.body.medium.pointSize

                    orientation: Qt.Horizontal
                    spacing: Tokens.spacing.extraSmall
                    interactive: false

                    model: ScriptModel {
                        values: passwordContainer.passwordBuffer.split("")
                    }

                    delegate: StyledRect {
                        id: ch

                        implicitWidth: implicitHeight
                        implicitHeight: charList.implicitHeight

                        color: Colours.palette.m3onSurface
                        radius: Tokens.rounding.medium / 2

                        opacity: 0
                        scale: 0
                        Component.onCompleted: {
                            opacity = 1;
                            scale = 1;
                        }
                        ListView.onRemove: removeAnim.start()

                        SequentialAnimation {
                            id: removeAnim

                            PropertyAction {
                                target: ch
                                property: "ListView.delayRemove"
                                value: true
                            }
                            ParallelAnimation {
                                Anim {
                                    type: Anim.DefaultEffects
                                    target: ch
                                    property: "opacity"
                                    to: 0
                                }
                                Anim {
                                    target: ch
                                    property: "scale"
                                    to: 0.5
                                }
                            }
                            PropertyAction {
                                target: ch
                                property: "ListView.delayRemove"
                                value: false
                            }
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
                    }

                    Behavior on implicitWidth {
                        Anim {}
                    }
                }
            }

            RowLayout {
                Layout.topMargin: Tokens.spacing.medium
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                TextButton {
                    id: cancelButton

                    Layout.fillWidth: true
                    Layout.minimumHeight: Tokens.font.body.medium.pointSize + Tokens.padding.medium * 2
                    inactiveColour: Colours.palette.m3secondaryContainer
                    inactiveOnColour: Colours.palette.m3onSecondaryContainer
                    text: Tr.trCtx("Cancel", "button")

                    onClicked: root.closeDialog()
                }

                TextButton {
                    id: connectButton

                    property bool connecting: false
                    property bool hasError: false

                    Layout.fillWidth: true
                    Layout.minimumHeight: Tokens.font.body.medium.pointSize + Tokens.padding.medium * 2
                    inactiveColour: Colours.palette.m3primary
                    inactiveOnColour: Colours.palette.m3onPrimary
                    text: connecting ? Tr.tr("Connecting...") : Tr.tr("Connect")
                    enabled: passwordContainer.passwordBuffer.length > 0 && !connecting

                    onClicked: {
                        if (!root.network || connecting) {
                            return;
                        }

                        const password = passwordContainer.passwordBuffer;
                        if (!password || password.length === 0) {
                            return;
                        }

                        hasError = false;
                        connecting = true;

                        const network = root.network;
                        NetworkConnection.connectWithPassword(network, password, result => {
                            if (!root.shouldBeVisible || root.network !== network || !connecting)
                                return;

                            if (result?.success) {
                                root.closeDialog();
                                return;
                            }

                            hasError = true;
                            passwordContainer.passwordBuffer = "";
                            connecting = false;
                        });
                    }
                }
            }
        }
    }
}
