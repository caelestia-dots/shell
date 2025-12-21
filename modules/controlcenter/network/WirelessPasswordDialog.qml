pragma ComponentBehavior: Bound

import ".."
import "."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session

    readonly property var network: {
        if (session.network.pendingNetwork) {
            return session.network.pendingNetwork;
        }
        if (session.network.active) {
            return session.network.active;
        }
        return null;
    }

    property bool isClosing: false
    visible: session.network.showPasswordDialog || isClosing
    enabled: session.network.showPasswordDialog && !isClosing
    focus: enabled

    Keys.onEscapePressed: {
        closeDialog();
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: root.session.network.showPasswordDialog && !root.isClosing ? 1 : 0

        Behavior on opacity {
            Anim {}
        }

        MouseArea {
            anchors.fill: parent
            onClicked: closeDialog()
        }
    }

    StyledRect {
        id: dialog

        anchors.centerIn: parent

        implicitWidth: 400
        implicitHeight: content.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surface
        opacity: root.session.network.showPasswordDialog && !root.isClosing ? 1 : 0
        scale: root.session.network.showPasswordDialog && !root.isClosing ? 1 : 0.7

        Behavior on opacity {
            Anim {}
        }

        Behavior on scale {
            Anim {}
        }

        ParallelAnimation {
            running: root.isClosing
            onFinished: {
                if (root.isClosing) {
                    root.session.network.showPasswordDialog = false;
                    root.isClosing = false;
                }
            }

            Anim {
                target: dialog
                property: "opacity"
                to: 0
            }
            Anim {
                target: dialog
                property: "scale"
                to: 0.7
            }
        }

        Keys.onEscapePressed: closeDialog()

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            spacing: Appearance.spacing.normal

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "lock"
                font.pointSize: Appearance.font.size.extraLarge * 2
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Enter password")
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.network ? qsTr("Network: %1").arg(root.network.ssid) : ""
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                id: statusText

                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.small
                visible: connectButton.connecting || connectButton.hasError
                text: {
                    if (connectButton.hasError) {
                        return qsTr("Connection failed. Please check your password and try again.");
                    }
                    if (connectButton.connecting) {
                        return qsTr("Connecting...");
                    }
                    return "";
                }
                color: connectButton.hasError ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
                font.weight: 400
                wrapMode: Text.WordWrap
                Layout.maximumWidth: parent.width - Appearance.padding.large * 2
            }

            Item {
                id: passwordContainer
                Layout.topMargin: Appearance.spacing.large
                Layout.fillWidth: true
                implicitHeight: Math.max(48, charList.implicitHeight + Appearance.padding.normal * 2)

                focus: true
                Keys.onPressed: event => {
                    if (!activeFocus) {
                        forceActiveFocus();
                    }

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
                        passwordBuffer += event.text;
                        event.accepted = true;
                    }
                }

                property string passwordBuffer: ""

                Connections {
                    target: root.session.network
                    function onShowPasswordDialogChanged(): void {
                        if (root.session.network.showPasswordDialog) {
                            Qt.callLater(() => {
                                passwordContainer.forceActiveFocus();
                                passwordContainer.passwordBuffer = "";
                                connectButton.hasError = false;
                            });
                        }
                    }
                }

                Connections {
                    target: root
                    function onVisibleChanged(): void {
                        if (root.visible) {
                            Qt.callLater(() => {
                                passwordContainer.forceActiveFocus();
                            });
                        }
                    }
                }

                StyledRect {
                    anchors.fill: parent
                    radius: Appearance.rounding.normal
                    color: passwordContainer.activeFocus ? Qt.lighter(Colours.tPalette.m3surfaceContainer, 1.05) : Colours.tPalette.m3surfaceContainer
                    border.width: passwordContainer.activeFocus || connectButton.hasError ? 4 : (root.visible ? 1 : 0)
                    border.color: {
                        if (connectButton.hasError) {
                            return Colours.palette.m3error;
                        }
                        if (passwordContainer.activeFocus) {
                            return Colours.palette.m3primary;
                        }
                        return root.visible ? Colours.palette.m3outline : "transparent";
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

                    function onClicked(): void {
                        passwordContainer.forceActiveFocus();
                    }
                }

                StyledText {
                    id: placeholder
                    anchors.centerIn: parent
                    text: qsTr("Password")
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.normal
                    font.family: Appearance.font.family.mono
                    opacity: passwordContainer.passwordBuffer ? 0 : 1

                    Behavior on opacity {
                        Anim {}
                    }
                }

                ListView {
                    id: charList

                    readonly property int fullWidth: count * (implicitHeight + spacing) - spacing

                    anchors.centerIn: parent
                    implicitWidth: fullWidth
                    implicitHeight: Appearance.font.size.normal

                    orientation: Qt.Horizontal
                    spacing: Appearance.spacing.small / 2
                    interactive: false

                    model: ScriptModel {
                        values: passwordContainer.passwordBuffer.split("")
                    }

                    delegate: StyledRect {
                        id: ch

                        implicitWidth: implicitHeight
                        implicitHeight: charList.implicitHeight

                        color: Colours.palette.m3onSurface
                        radius: Appearance.rounding.small / 2

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
                            Anim {}
                        }

                        Behavior on scale {
                            Anim {
                                duration: Appearance.anim.durations.expressiveFastSpatial
                                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                            }
                        }
                    }

                    Behavior on implicitWidth {
                        Anim {}
                    }
                }
            }

            RowLayout {
                Layout.topMargin: Appearance.spacing.normal
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                TextButton {
                    id: cancelButton

                    Layout.fillWidth: true
                    Layout.minimumHeight: Appearance.font.size.normal + Appearance.padding.normal * 2
                    inactiveColour: Colours.palette.m3secondaryContainer
                    inactiveOnColour: Colours.palette.m3onSecondaryContainer
                    text: qsTr("Cancel")

                    onClicked: root.closeDialog()
                }

                TextButton {
                    id: connectButton

                    property bool connecting: false
                    property bool hasError: false

                    Layout.fillWidth: true
                    Layout.minimumHeight: Appearance.font.size.normal + Appearance.padding.normal * 2
                    inactiveColour: Colours.palette.m3primary
                    inactiveOnColour: Colours.palette.m3onPrimary
                    text: qsTr("Connect")
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
                        enabled = false;
                        text = qsTr("Connecting...");

                        NetworkConnection.connectWithPassword(root.network, password, result => {
                            if (result && result.success) {
                            } else if (result && result.needsPassword) {
                                connectionMonitor.stop();
                                connecting = false;
                                hasError = true;
                                enabled = true;
                                text = qsTr("Connect");
                                passwordContainer.passwordBuffer = "";
                                if (root.network && root.network.ssid) {
                                    Nmcli.forgetNetwork(root.network.ssid);
                                }
                            } else {
                                connectionMonitor.stop();
                                connecting = false;
                                hasError = true;
                                enabled = true;
                                text = qsTr("Connect");
                                passwordContainer.passwordBuffer = "";
                                if (root.network && root.network.ssid) {
                                    Nmcli.forgetNetwork(root.network.ssid);
                                }
                            }
                        });

                        connectionMonitor.start();
                    }
                }
            }
        }
    }

    function checkConnectionStatus(): void {
        if (!root.visible || !connectButton.connecting) {
            return;
        }

        const isConnected = root.network && Nmcli.active && Nmcli.active.ssid && Nmcli.active.ssid.toLowerCase().trim() === root.network.ssid.toLowerCase().trim();

        if (isConnected) {
            connectionSuccessTimer.start();
            return;
        }

        if (Nmcli.pendingConnection === null && connectButton.connecting) {
            if (connectionMonitor.repeatCount > 10) {
                connectionMonitor.stop();
                connectButton.connecting = false;
                connectButton.hasError = true;
                connectButton.enabled = true;
                connectButton.text = qsTr("Connect");
                passwordContainer.passwordBuffer = "";
                if (root.network && root.network.ssid) {
                    Nmcli.forgetNetwork(root.network.ssid);
                }
            }
        }
    }

    Timer {
        id: connectionMonitor
        interval: 1000
        repeat: true
        triggeredOnStart: false
        property int repeatCount: 0

        onTriggered: {
            repeatCount++;
            checkConnectionStatus();
        }

        onRunningChanged: {
            if (!running) {
                repeatCount = 0;
            }
        }
    }

    Timer {
        id: connectionSuccessTimer
        interval: 500
        onTriggered: {
            if (root.visible && Nmcli.active && Nmcli.active.ssid) {
                const stillConnected = Nmcli.active.ssid.toLowerCase().trim() === root.network.ssid.toLowerCase().trim();
                if (stillConnected) {
                    connectionMonitor.stop();
                    connectButton.connecting = false;
                    connectButton.text = qsTr("Connect");
                    closeDialog();
                }
            }
        }
    }

    Connections {
        target: Nmcli
        function onActiveChanged() {
            if (root.visible) {
                checkConnectionStatus();
            }
        }
        function onConnectionFailed(ssid: string) {
            if (root.visible && root.network && root.network.ssid === ssid && connectButton.connecting) {
                connectionMonitor.stop();
                connectButton.connecting = false;
                connectButton.hasError = true;
                connectButton.enabled = true;
                connectButton.text = qsTr("Connect");
                passwordContainer.passwordBuffer = "";
                Nmcli.forgetNetwork(ssid);
            }
        }
    }

    function closeDialog(): void {
        if (isClosing) {
            return;
        }

        isClosing = true;
        passwordContainer.passwordBuffer = "";
        connectButton.connecting = false;
        connectButton.hasError = false;
        connectButton.text = qsTr("Connect");
        connectionMonitor.stop();
    }
}
