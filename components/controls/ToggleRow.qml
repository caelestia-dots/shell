import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls

RowLayout {
    id: root

    required property string label
    property alias checked: toggle.checked
    property alias toggle: toggle

    Layout.fillWidth: true
    spacing: Tokens.spacing.normal

    StyledText {
        Layout.fillWidth: true
        text: root.label
    }

    StyledSwitch {
        id: toggle

        cLayer: 2
    }
}
