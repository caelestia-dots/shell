pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Appearance.spacing.small

    RowLayout {
        spacing: Appearance.spacing.smaller

        StyledText {
            text: qsTr("Settings")
            font.pointSize: Appearance.font.size.large
            font.weight: 500
        }

        Item {
            Layout.fillWidth: true
        }

        ToggleButton {
            toggled: !root.session.ethernet.active
            icon: "settings"
            accent: "Primary"

            onClicked: {
                if (root.session.ethernet.active)
                    root.session.ethernet.active = null;
                else {
                    root.session.ethernet.active = view.model.get(0)?.modelData ?? null;
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        StyledText {
            text: qsTr("Devices (%1)").arg(Nmcli.ethernetDevices.length)
            font.pointSize: Appearance.font.size.large
            font.weight: 500
        }
    }

    StyledText {
        text: qsTr("All available ethernet devices")
        color: Colours.palette.m3outline
    }

    StyledListView {
        id: view

        Layout.fillWidth: true
        Layout.fillHeight: true

        model: Nmcli.ethernetDevices

        spacing: Appearance.spacing.small / 2
        clip: true

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: view
        }

        delegate: StyledRect {
            required property var modelData

            anchors.left: parent.left
            anchors.right: parent.right

            color: Qt.alpha(Colours.tPalette.m3surfaceContainer, root.session.ethernet.active === modelData ? Colours.tPalette.m3surfaceContainer.a : 0)
            radius: Appearance.rounding.normal
            border.width: root.session.ethernet.active === modelData ? 1 : 0
            border.color: Colours.palette.m3primary

            StateLayer {
                function onClicked(): void {
                    root.session.ethernet.active = modelData;
                }
            }

            RowLayout {
                id: rowLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Appearance.padding.normal

                spacing: Appearance.spacing.normal

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: icon.implicitHeight + Appearance.padding.normal * 2

                    radius: Appearance.rounding.normal
                    color: modelData.connected ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                    MaterialIcon {
                        id: icon

                        anchors.centerIn: parent
                        text: "cable"
                        font.pointSize: Appearance.font.size.large
                        fill: modelData.connected ? 1 : 0
                        color: modelData.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    maximumLineCount: 1

                    text: modelData.interface || qsTr("Unknown")
                }

                StyledText {
                    text: modelData.connected ? qsTr("Connected") : qsTr("Disconnected")
                    color: modelData.connected ? Colours.palette.m3primary : Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                    font.weight: modelData.connected ? 500 : 400
                }

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: connectIcon.implicitHeight + Appearance.padding.smaller * 2

                    radius: Appearance.rounding.full
                    color: Qt.alpha(Colours.palette.m3primaryContainer, modelData.connected ? 1 : 0)

                    StateLayer {
                        function onClicked(): void {
                            if (modelData.connected && modelData.connection) {
                                Nmcli.disconnectEthernet(modelData.connection, () => {});
                            } else {
                                Nmcli.connectEthernet(modelData.connection || "", modelData.interface || "", () => {});
                            }
                        }
                    }

                    MaterialIcon {
                        id: connectIcon

                        anchors.centerIn: parent
                        text: modelData.connected ? "link_off" : "link"
                        color: modelData.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    }
                }
            }

            implicitHeight: rowLayout.implicitHeight + Appearance.padding.normal * 2
        }
    }
}