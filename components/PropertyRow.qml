import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property string label
    required property string value
    property bool showTopMargin: false

    spacing: Tokens.spacing.extraSmall

    StyledText {
        Layout.topMargin: root.showTopMargin ? Tokens.spacing.medium : 0
        text: root.label
    }

    StyledText {
        text: root.value
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
    }
}
