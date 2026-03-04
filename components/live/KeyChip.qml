import QtQuick
import qs.components
import qs.services
import qs.config

StyledRect {
    id: root

    required property string keyText

    implicitWidth: keyLabel.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: keyLabel.implicitHeight + Appearance.padding.small * 2
    radius: Appearance.rounding.small
    color: Colours.palette.m3surfaceContainerHigh

    StyledText {
        id: keyLabel

        anchors.centerIn: parent
        text: root.keyText
        font.family: "monospace"
        font.pointSize: Appearance.font.size.small
        color: Colours.palette.m3onSurface
    }
}
