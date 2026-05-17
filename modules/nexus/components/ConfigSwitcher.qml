pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus

ColumnLayout {
    id: root

    required property NexusSession session

    readonly property var configModel: {
        const items = [
            {
                id: "global",
                label: "Global",
                icon: "language",
                desc: "Settings apply everywhere"
            }
        ];
        for (const screen of Screens.screens) {
            items.push({
                id: screen.name,
                label: screen.name,
                icon: "monitor",
                desc: "Monitor-specific overrides"
            });
        }
        return items;
    }

    spacing: Tokens.spacing.small

    StyledText {
        text: "Editing Context"
        font.pointSize: Tokens.font.size.small
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
        color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
    }

    // Divider
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Qt.alpha(Colours.palette.m3onSurface, 0.1)
    }

    Repeater {
        model: root.configModel

        delegate: Item {
            id: configDelegate

            required property var modelData

            Layout.fillWidth: true
            Layout.preferredHeight: 48

            readonly property bool isActive: root.session.activeConfig === modelData.id

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.normal
                color: configDelegate.isActive ? Qt.alpha(Colours.palette.m3primary, 0.12) : "transparent"

                Behavior on color {
                    CAnim {}
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.spacing.normal
                    anchors.rightMargin: Tokens.spacing.normal
                    spacing: Tokens.spacing.normal

                    MaterialIcon {
                        text: configDelegate.modelData.icon
                        font.pointSize: Tokens.font.size.larger
                        color: configDelegate.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                        fill: configDelegate.isActive ? 1 : 0

                        Behavior on color {
                            CAnim {}
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: configDelegate.modelData.label
                            font.pointSize: Tokens.font.size.normal
                            font.weight: Font.Medium
                            color: configDelegate.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface

                            Behavior on color {
                                CAnim {}
                            }
                        }

                        StyledText {
                            text: configDelegate.modelData.desc
                            font.pointSize: Tokens.font.size.small - 1
                            color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
                        }
                    }

                    MaterialIcon {
                        visible: configDelegate.isActive
                        text: "check"
                        font.pointSize: Tokens.font.size.normal
                        color: Colours.palette.m3primary
                    }
                }

                StateLayer {
                    radius: parent.radius
                    color: Colours.palette.m3onSurface
                    onClicked: {
                        root.session.activeConfig = configDelegate.modelData.id;
                        root.session.configPopoutOpen = false;
                    }
                }
            }
        }
    }
}
