pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property string search: ""

    function matches(bind: var): bool {
        if (!search)
            return true;
        const q = search.toLowerCase();
        return bind.action.toLowerCase().includes(q) || bind.keys.toLowerCase().includes(q);
    }

    function filtered(binds: var): var {
        return binds.filter(b => root.matches(b));
    }

    title: qsTr("Keyboard shortcuts")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StyledRect {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.small
            implicitHeight: searchLayout.implicitHeight + Tokens.padding.medium * 2

            radius: Tokens.rounding.full
            color: Colours.tPalette.m3surfaceContainerLowest
            border.color: Colours.palette.m3outlineVariant

            Behavior on border.color {
                CAnim {}
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onClicked: searchField.forceActiveFocus()
            }

            RowLayout {
                id: searchLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "search"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }

                StyledTextField {
                    id: searchField

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    placeholderText: qsTr("Search shortcuts")
                    placeholderTextColor: Colours.palette.m3onSurfaceVariant
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.large

                    onTextChanged: root.search = text
                }

                IconButton {
                    visible: searchField.text.length > 0
                    icon: "close"
                    font: Tokens.font.icon.small
                    type: IconButton.Text
                    isRound: true
                    onClicked: searchField.clear()
                }
            }
        }

        Repeater {
            model: Keybinds.groups

            ColumnLayout {
                id: section

                required property var modelData
                required property int index

                readonly property var shown: root.filtered(modelData.binds)

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2
                visible: shown.length > 0

                SectionHeader {
                    first: section.index === 0
                    text: section.modelData.category
                }

                Repeater {
                    model: section.shown

                    ConnectedRect {
                        id: row

                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        first: index === 0
                        last: index === section.shown.length - 1
                        implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2

                        RowLayout {
                            id: rowLayout

                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            anchors.leftMargin: Tokens.padding.largeIncreased
                            anchors.rightMargin: Tokens.padding.largeIncreased
                            spacing: Tokens.spacing.medium

                            StyledText {
                                Layout.fillWidth: true
                                text: row.modelData.action
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            Row {
                                Layout.alignment: Qt.AlignVCenter
                                spacing: Tokens.spacing.small / 2

                                Repeater {
                                    model: row.modelData.keys.split(" + ")

                                    StyledRect {
                                        id: chip

                                        required property string modelData

                                        implicitWidth: Math.max(implicitHeight, chipLabel.implicitWidth + Tokens.padding.small * 2)
                                        implicitHeight: chipLabel.implicitHeight + Tokens.padding.extraSmall * 2

                                        radius: Tokens.rounding.small
                                        color: Colours.palette.m3surfaceContainerHighest
                                        border.color: Colours.palette.m3outlineVariant

                                        StyledText {
                                            id: chipLabel

                                            anchors.centerIn: parent
                                            text: chip.modelData
                                            color: Colours.palette.m3onSurface
                                            font: Tokens.font.label.medium
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.extraLarge * 2
            spacing: Tokens.padding.extraSmall
            visible: Keybinds.ready ? root.search.length > 0 && !Keybinds.groups.some(g => root.filtered(g.binds).length > 0) : true

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: Keybinds.ready ? "search_off" : "keyboard"
                color: Colours.palette.m3outlineVariant
                fontStyle: Tokens.font.icon.extraLarge
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Keybinds.ready ? qsTr("No matching shortcuts") : qsTr("Loading shortcuts…")
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.title.small
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: !Keybinds.ready
                text: qsTr("Reading your Hyprland keybinds")
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.body.small
            }
        }
    }
}
