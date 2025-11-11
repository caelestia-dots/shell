pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var network
    signal accepted(password: string)
    signal cancelled()

    anchors.fill: parent

    // Backdrop
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.6

        StateLayer {
            function onClicked(): void {
                root.cancelled();
            }
        }
    }

    // Elevation shadow
    Elevation {
        anchors.fill: dialog
        radius: dialog.radius
        level: 3
    }

    // Dialog
    StyledRect {
        id: dialog

        anchors.centerIn: parent
        implicitWidth: Math.min(parent.width * 0.8, 400)
        implicitHeight: dialogContent.implicitHeight + Appearance.padding.large * 4

        radius: Appearance.rounding.large
        color: Colours.palette.m3surface

        ColumnLayout {
            id: dialogContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large * 2

            spacing: Appearance.spacing.large

            // Title
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: "lock"
                    font.pointSize: Appearance.font.size.extraLarge
                    color: Colours.palette.m3primary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Enter Password")
                    font.pointSize: Appearance.font.size.large
                    font.weight: 700
                }
            }

            // Network info
            StyledText {
                Layout.fillWidth: true
                text: qsTr("Network: %1").arg(root.network.ssid)
                color: Colours.palette.m3outline
                wrapMode: Text.Wrap
            }

            // Password field
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    text: qsTr("Password")
                    font.weight: 600
                }

                StyledTextField {
                    id: passwordField

                    Layout.fillWidth: true
                    placeholderText: qsTr("Enter network password")
                    echoMode: showPassword.checked ? TextInput.Normal : TextInput.Password

                    onAccepted: {
                        if (text.length > 0) {
                            root.accepted(text);
                        }
                    }

                    Component.onCompleted: forceActiveFocus()

                    Keys.onEscapePressed: root.cancelled()
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledRect {
                        implicitWidth: checkBox.implicitWidth + Appearance.padding.small * 2
                        implicitHeight: checkBox.implicitHeight + Appearance.padding.small * 2

                        radius: Appearance.rounding.small
                        color: showPassword.checked ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHighest

                        StateLayer {
                            color: showPassword.checked ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

                            function onClicked(): void {
                                showPassword.checked = !showPassword.checked;
                            }
                        }

                        MaterialIcon {
                            id: checkBox

                            anchors.centerIn: parent
                            text: showPassword.checked ? "check_box" : "check_box_outline_blank"
                            font.pointSize: Appearance.font.size.normal
                            color: showPassword.checked ? Colours.palette.m3primary : Colours.palette.m3outline
                        }
                    }

                    QtObject {
                        id: showPassword
                        property bool checked: false
                    }

                    StyledText {
                        text: qsTr("Show password")
                        font.pointSize: Appearance.font.size.small

                        StateLayer {
                            function onClicked(): void {
                                showPassword.checked = !showPassword.checked;
                            }
                        }
                    }
                }
            }

            // Error message
            StyledText {
                id: errorText

                Layout.fillWidth: true
                visible: false
                text: qsTr("Failed to connect. Please check your password.")
                color: Colours.palette.m3error
                font.pointSize: Appearance.font.size.small
                wrapMode: Text.Wrap
            }

            // Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.normal
                spacing: Appearance.spacing.normal

                Item {
                    Layout.fillWidth: true
                }

                StyledRect {
                    implicitWidth: cancelBtn.implicitWidth + Appearance.padding.large * 2
                    implicitHeight: cancelBtn.implicitHeight + Appearance.padding.normal

                    radius: Appearance.rounding.normal
                    color: "transparent"

                    StateLayer {
                        color: Colours.palette.m3onSurface

                        function onClicked(): void {
                            root.cancelled();
                        }
                    }

                    StyledText {
                        id: cancelBtn

                        anchors.centerIn: parent
                        text: qsTr("Cancel")
                        font.weight: 600
                        color: Colours.palette.m3onSurface
                    }
                }

                StyledRect {
                    implicitWidth: connectBtn.implicitWidth + Appearance.padding.large * 2
                    implicitHeight: connectBtn.implicitHeight + Appearance.padding.normal

                    radius: Appearance.rounding.normal
                    color: passwordField.text.length > 0 ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest

                    StateLayer {
                        color: Colours.palette.m3onPrimary
                        disabled: passwordField.text.length === 0

                        function onClicked(): void {
                            if (passwordField.text.length > 0) {
                                root.accepted(passwordField.text);
                            }
                        }
                    }

                    StyledText {
                        id: connectBtn

                        anchors.centerIn: parent
                        text: qsTr("Connect")
                        font.weight: 600
                        color: passwordField.text.length > 0 ? Colours.palette.m3onPrimary : Colours.palette.m3outline
                    }
                }
            }
        }

        // Scale animation
        scale: 0
        opacity: 0

        Component.onCompleted: {
            scaleAnim.start();
            opacityAnim.start();
        }

        NumberAnimation {
            id: scaleAnim
            target: dialog
            property: "scale"
            from: 0.8
            to: 1
            duration: Appearance.anim.durations.normal
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: opacityAnim
            target: dialog
            property: "opacity"
            from: 0
            to: 1
            duration: Appearance.anim.durations.normal
            easing.type: Easing.OutCubic
        }
    }

    function showError(): void {
        errorText.visible = true;
    }
}
