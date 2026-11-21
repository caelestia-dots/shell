import QtQuick
import QtQuick.Templates
import Caelestia.Config
import Caelestia.Scheme
import qs.components

TextField {
    id: root

    readonly property alias cursor: cursor

    implicitWidth: contentWidth + leftPadding + rightPadding
    implicitHeight: contentHeight + topPadding + bottomPadding

    color: Colours.palette.onSurface
    placeholderTextColor: Colours.palette.onSurfaceVariant // No anim cause placeholder is custom
    selectionColor: Qt.alpha(Colours.palette.primary, 0.4)
    selectedTextColor: color

    font: Tokens.font.body.small
    renderType: echoMode === TextField.Password ? TextField.QtRendering : TextField.NativeRendering
    cursorVisible: !readOnly
    verticalAlignment: TextInput.AlignVCenter

    cursorDelegate: Item {}

    Behavior on color {
        CAnim {}
    }

    Behavior on selectionColor {
        CAnim {}
    }

    TextCursor {
        id: cursor

        editor: root
    }
}
