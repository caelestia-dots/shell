import QtQuick
import QtQuick.Templates
import Caelestia.Config
import Caelestia.Scheme
import qs.components

TextArea {
    id: root

    implicitWidth: contentWidth + leftPadding + rightPadding
    implicitHeight: contentHeight + topPadding + bottomPadding

    color: Colours.palette.onSurface
    placeholderTextColor: Colours.palette.onSurfaceVariant
    selectionColor: Qt.alpha(Colours.palette.primary, 0.4)
    selectedTextColor: color

    font: Tokens.font.body.small
    renderType: TextEdit.NativeRendering
    wrapMode: TextEdit.Wrap
    cursorVisible: !readOnly

    cursorDelegate: Item {}

    Behavior on color {
        CAnim {}
    }

    Behavior on selectionColor {
        CAnim {}
    }

    TextCursor {
        editor: root
    }
}
