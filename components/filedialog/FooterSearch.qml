import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls

StyledTextField {
    id: root

    required property DialogState dState

    implicitWidth: Math.max(Tokens.sizes.fileDialog.minSearchWidth, parent.width * 0.7)
    radius: Tokens.rounding.small
    verticalPadding: Tokens.padding.small
    placeholderText: dState.save ? Tr.trCtx("Save as", "save file") : Tr.trCtx("Search", "search files")
    persistentSelection: true

    Keys.onUpPressed: cursorPosition = 0
    Keys.onDownPressed: cursorPosition = length
    Keys.onLeftPressed: cursorPosition--
    Keys.onRightPressed: cursorPosition++

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
            if (s && !s.isDir) {
                root.text = s.name;
                root.select(0, root.length - s.suffix.length - 1);
            }
        }

        target: root.dState
    }
}
