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

    // Id of the bind currently being re-recorded ("" if none). A string, not the
    // bind object, since bind objects lose identity crossing the var boundary.
    property string recordingId: ""

    function isModifier(k: int): bool {
        return k === Qt.Key_Super_L || k === Qt.Key_Super_R || k === Qt.Key_Meta || k === Qt.Key_Control || k === Qt.Key_Alt || k === Qt.Key_AltGr || k === Qt.Key_Shift || k === Qt.Key_CapsLock || k === Qt.Key_NumLock;
    }

    // Map a Qt key event to a Hyprland keysym name (null if unmappable).
    function keyName(event: var): string {
        const k = event.key;
        if (k >= Qt.Key_A && k <= Qt.Key_Z)
            return String.fromCharCode(k);
        if (k >= Qt.Key_0 && k <= Qt.Key_9)
            return String.fromCharCode(k);
        if (k >= Qt.Key_F1 && k <= Qt.Key_F35)
            return "F" + (k - Qt.Key_F1 + 1);
        switch (k) {
        case Qt.Key_Space:
            return "space";
        case Qt.Key_Return:
        case Qt.Key_Enter:
            return "Return";
        case Qt.Key_Tab:
        case Qt.Key_Backtab:
            return "Tab";
        case Qt.Key_Escape:
            return "Escape";
        case Qt.Key_Backspace:
            return "BackSpace";
        case Qt.Key_Delete:
            return "Delete";
        case Qt.Key_Insert:
            return "Insert";
        case Qt.Key_Home:
            return "Home";
        case Qt.Key_End:
            return "End";
        case Qt.Key_PageUp:
            return "Prior";
        case Qt.Key_PageDown:
            return "Next";
        case Qt.Key_Left:
            return "Left";
        case Qt.Key_Right:
            return "Right";
        case Qt.Key_Up:
            return "Up";
        case Qt.Key_Down:
            return "Down";
        case Qt.Key_Minus:
            return "minus";
        case Qt.Key_Equal:
            return "equal";
        case Qt.Key_Comma:
            return "comma";
        case Qt.Key_Period:
            return "period";
        case Qt.Key_Slash:
            return "slash";
        case Qt.Key_Backslash:
            return "backslash";
        case Qt.Key_Semicolon:
            return "semicolon";
        case Qt.Key_Apostrophe:
            return "apostrophe";
        case Qt.Key_BracketLeft:
            return "bracketleft";
        case Qt.Key_BracketRight:
            return "bracketright";
        case Qt.Key_QuoteLeft:
            return "grave";
        case Qt.Key_Print:
            return "Print";
        case Qt.Key_Pause:
            return "Pause";
        }
        if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 0x20)
            return event.text.toUpperCase();
        return null;
    }

    // Build a Hyprland key combo string (e.g. "SUPER + T") from a key event.
    function luaFromEvent(event: var): string {
        const name = root.keyName(event);
        if (!name)
            return "";
        const mods = [];
        if (event.modifiers & Qt.MetaModifier)
            mods.push("SUPER");
        if (event.modifiers & Qt.ControlModifier)
            mods.push("CTRL");
        if (event.modifiers & Qt.AltModifier)
            mods.push("ALT");
        if (event.modifiers & Qt.ShiftModifier)
            mods.push("SHIFT");
        return [...mods, name].join(" + ");
    }

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

                            readonly property bool recording: root.recordingId !== "" && root.recordingId === row.modelData.id
                            readonly property bool editable: !!row.modelData.edit

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

                            StyledText {
                                visible: rowLayout.recording
                                Layout.alignment: Qt.AlignVCenter
                                text: qsTr("Press keys…")
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.medium
                            }

                            Row {
                                visible: !rowLayout.recording
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

                            IconButton {
                                visible: rowLayout.editable
                                Layout.alignment: Qt.AlignVCenter
                                icon: rowLayout.recording ? "close" : "edit"
                                font: Tokens.font.icon.small
                                type: IconButton.Text
                                isRound: true
                                onClicked: root.recordingId = rowLayout.recording ? "" : row.modelData.id
                            }

                            Item {
                                id: capture

                                implicitWidth: 0
                                implicitHeight: 0

                                // Grab keyboard focus whenever this row enters
                                // recording, regardless of how it was triggered.
                                onRecordingChanged: if (recording)
                                    forceActiveFocus()
                                property bool recording: rowLayout.recording

                                Keys.onShortcutOverride: event => event.accepted = rowLayout.recording
                                Keys.onPressed: event => {
                                    if (!rowLayout.recording)
                                        return;
                                    event.accepted = true;
                                    if (event.key === Qt.Key_Escape) {
                                        root.recordingId = "";
                                        return;
                                    }
                                    if (root.isModifier(event.key))
                                        return;
                                    const combo = root.luaFromEvent(event);
                                    if (!combo)
                                        return;
                                    Keybinds.setBind(row.modelData.edit, combo);
                                    root.recordingId = "";
                                }
                                onActiveFocusChanged: {
                                    if (!activeFocus && rowLayout.recording)
                                        root.recordingId = "";
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
