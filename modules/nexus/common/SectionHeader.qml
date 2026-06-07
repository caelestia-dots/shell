import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledText {
    property bool first

    Layout.fillWidth: true
    Layout.topMargin: first ? 0 : Tokens.spacing.largeIncreased - ((parent as ColumnLayout).spacing ?? 0)
    Layout.bottomMargin: Tokens.spacing.extraSmall
    Layout.leftMargin: Tokens.padding.small

    color: Colours.palette.m3onSurfaceVariant
    font: Tokens.font.label.medium
    elide: Text.ElideRight
}
