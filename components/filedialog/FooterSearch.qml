import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls

StyledTextField {
    id: root

    required property DialogState dState

    function selectName(name: string): void {
        text = name;
        const idx = name.indexOf(".");
        // >0 to fully select hidden files
        select(0, idx > 0 ? idx : length);
    }

    implicitWidth: Math.max(Tokens.sizes.fileDialog.minSearchWidth, parent.width * 0.7)
    radius: Tokens.rounding.small
    verticalPadding: Tokens.padding.small
    placeholderText: dState.save ? Tr.trCtx("Save as", "save file") : Tr.trCtx("Search", "search files")
    persistentSelection: true

    Keys.onUpPressed: event => {
        if (event.modifiers & Qt.ShiftModifier)
            moveCursorSelection(0);
        else
            cursorPosition = 0;
    }
    Keys.onDownPressed: event => {
        if (event.modifiers & Qt.ShiftModifier)
            moveCursorSelection(length);
        else
            cursorPosition = length;
    }
    Keys.onLeftPressed: event => {
        if (cursorPosition > 0)
            event.accepted = false;
        else if (!(event.modifiers & Qt.ShiftModifier))
            deselect();
    }
    Keys.onRightPressed: event => {
        if (cursorPosition < length)
            event.accepted = false;
        else if (!(event.modifiers & Qt.ShiftModifier))
            deselect();
    }

    Binding {
        target: root.dState
        property: "search"
        value: root.text
    }

    Connections {
        function onSelectedPathChanged(): void {
            if (!root.dState.save)
                return;

            const s = root.dState.selectedPath;
            if (s && !s.isDir)
                root.selectName(s.name);
        }

        target: root.dState
    }
}
