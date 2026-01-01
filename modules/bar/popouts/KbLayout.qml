import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Appearance.spacing.normal

    StyledText {
        Layout.topMargin: Appearance.padding.normal
        Layout.rightMargin: Appearance.padding.normal
        text: qsTr("Keyboard layout: %1").arg(Hypr.kbLayoutFull)
        font.weight: 500
    }

    TextButton {
        Layout.bottomMargin: Appearance.padding.normal
        Layout.rightMargin: Appearance.padding.normal
        Layout.fillWidth: true

        text: qsTr("Switch layout")
        onClicked: Hypr.extras.message("switchxkblayout all next")
    }
}
