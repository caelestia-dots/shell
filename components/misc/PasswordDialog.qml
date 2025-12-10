pragma ComponentBehavior: Bound

import ".."
import "../controls"
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property string ssid
    property alias password: passwordField.text

    signal accepted()
    signal rejected()

    implicitHeight: dialogContent.implicitHeight
    visible: opacity > 0
    opacity: 0

    function open(): void {
        opacity = 1;
        passwordField.forceActiveFocus();
    }

    function close(): void {
        opacity = 0;
        passwordField.text = "";
    }

    Behavior on opacity {
        Anim {
            duration: Appearance.anim.durations.normal
        }
    }

    StyledRect {
        anchors.fill: parent
        color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)
        radius: Appearance.rounding.normal

        ColumnLayout {
            id: dialogContent

            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Enter password for \"%1\"").arg(root.ssid)
                font.weight: 500
                wrapMode: Text.WordWrap
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: passwordField.implicitHeight + Appearance.padding.normal

                radius: Appearance.rounding.small
                color: Colours.palette.m3surfaceContainerHighest

                StyledTextField {
                    id: passwordField

                    anchors.fill: parent
                    anchors.leftMargin: Appearance.padding.small
                    anchors.rightMargin: Appearance.padding.small
                    verticalAlignment: TextInput.AlignVCenter

                    echoMode: TextInput.Password
                    placeholderText: qsTr("Password")

                    Keys.onReturnPressed: root.accepted()
                    Keys.onEnterPressed: root.accepted()
                    Keys.onEscapePressed: root.rejected()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                Item {
                    Layout.fillWidth: true
                }

                StyledRect {
                    implicitWidth: cancelText.implicitWidth + Appearance.padding.normal
                    implicitHeight: cancelText.implicitHeight + Appearance.padding.small

                    radius: Appearance.rounding.full
                    color: "transparent"

                    StateLayer {
                        color: Colours.palette.m3onSurface

                        function onClicked(): void {
                            root.rejected();
                        }
                    }

                    StyledText {
                        id: cancelText

                        anchors.centerIn: parent
                        text: qsTr("Cancel")
                        color: Colours.palette.m3onSurface
                    }
                }

                StyledRect {
                    implicitWidth: connectText.implicitWidth + Appearance.padding.normal
                    implicitHeight: connectText.implicitHeight + Appearance.padding.small

                    radius: Appearance.rounding.full
                    color: Colours.palette.m3primary

                    StateLayer {
                        color: Colours.palette.m3onPrimary
                        disabled: passwordField.text.length === 0

                        function onClicked(): void {
                            root.accepted();
                        }
                    }

                    StyledText {
                        id: connectText

                        anchors.centerIn: parent
                        text: qsTr("Connect")
                        color: Colours.palette.m3onPrimary
                    }
                }
            }
        }
    }
}
