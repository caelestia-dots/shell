import QtQuick
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property string keys
    required property string label
    property bool danger

    signal clicked

    implicitWidth: buttonText.implicitWidth + Tokens.padding.medium * 2
    implicitHeight: buttonText.implicitHeight + Tokens.padding.small * 2

    radius: Tokens.rounding.full
    color: danger ? Colours.palette.m3errorContainer : Colours.palette.m3surfaceContainerHigh

    StateLayer {
        radius: root.radius
        onClicked: root.clicked()
    }

    StyledText {
        id: buttonText

        anchors.centerIn: parent

        text: `${root.keys} ${root.label}`
        color: root.danger ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurfaceVariant
        font: Tokens.font.label.small
    }
}
