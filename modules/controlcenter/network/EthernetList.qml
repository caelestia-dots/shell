pragma ComponentBehavior: Bound

import ".."
import "../components"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

DeviceList {
    id: root

    required property Session session

    title: qsTr("Devices (%1)").arg(Nmcli.ethernetDevices.length)
    description: qsTr("All available ethernet devices")
    activeItem: session.ethernet.active

    model: Nmcli.ethernetDevices

    headerComponent: Component {
        RowLayout {
            spacing: Tokens.spacing.smaller

            StyledText {
                text: qsTr("Settings")
                font.pointSize: Tokens.font.size.large
                font.weight: 500
            }

            Item {
                Layout.fillWidth: true
            }

            ToggleButton {
                toggled: !root.session.ethernet.active
                icon: "settings"
                accent: "Primary"
                iconSize: Tokens.font.size.normal
                horizontalPadding: Tokens.padding.normal
                verticalPadding: Tokens.padding.smaller

                onClicked: {
                    if (root.session.ethernet.active)
                        root.session.ethernet.active = null;
                    else {
                        root.session.ethernet.active = root.view.model.get(0)?.modelData ?? null;
                    }
                }
            }
        }
    }

    delegate: Component {
        StyledRect {
            id: ethernetItem

            required property var modelData
            readonly property bool isActive: root.activeItem && modelData && root.activeItem.interface === modelData.interface

            width: ListView.view ? ListView.view.width : undefined
            implicitHeight: rowLayout.implicitHeight + Tokens.padding.normal * 2

            color: Qt.alpha(Colours.tPalette.m3surfaceContainer, ethernetItem.isActive ? Colours.tPalette.m3surfaceContainer.a : 0)
            radius: Tokens.rounding.normal

            StateLayer {
                id: stateLayer

                onClicked: {
                    root.session.ethernet.active = modelData;
                }
            }

            RowLayout {
                id: rowLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.normal

                spacing: Tokens.spacing.normal

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: icon.implicitHeight + Tokens.padding.normal * 2

                    radius: Tokens.rounding.normal
                    color: modelData.connected ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                    StyledRect {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.alpha(modelData.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface, stateLayer.pressed ? 0.1 : stateLayer.containsMouse ? 0.08 : 0)
                    }

                    MaterialIcon {
                        id: icon

                        anchors.centerIn: parent
                        text: "cable"
                        font.pointSize: Tokens.font.size.large
                        fill: modelData.connected ? 1 : 0
                        color: modelData.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

                        Behavior on fill {
                            Anim {}
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.interface || qsTr("Unknown")
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.smaller

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.connected ? qsTr("Connected") : qsTr("Disconnected")
                            color: modelData.connected ? Colours.palette.m3primary : Colours.palette.m3outline
                            font.pointSize: Tokens.font.size.small
                            font.weight: modelData.connected ? 500 : 400
                            elide: Text.ElideRight
                        }
                    }
                }

                StyledRect {
                    id: connectBtn

                    implicitWidth: implicitHeight
                    implicitHeight: connectIcon.implicitHeight + Tokens.padding.smaller * 2

                    radius: Tokens.rounding.full
                    color: Qt.alpha(Colours.palette.m3primaryContainer, modelData.connected ? 1 : 0)

                    StateLayer {
                        onClicked: {
                            if (modelData.connected && modelData.connection) {
                                Nmcli.disconnectEthernet(modelData.connection, () => {});
                            } else {
                                Nmcli.connectEthernet(modelData.connection || "", modelData.interface || "", () => {});
                            }
                        }

                        color: modelData.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    }

                    MaterialIcon {
                        id: connectIcon

                        anchors.centerIn: parent
                        animate: true
                        text: modelData.connected ? "link_off" : "link"
                        color: modelData.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    }
                }
            }
        }
    }

    onItemSelected: function (item) {
        session.ethernet.active = item;
    }
}
