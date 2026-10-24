import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Scheme
import qs.components

StyledText {
    property bool first

    Layout.fillWidth: true
    Layout.topMargin: first ? 0 : Tokens.spacing.largeIncreased - ((parent as ColumnLayout).spacing ?? 0)
    Layout.bottomMargin: Tokens.spacing.extraSmall
    Layout.leftMargin: Tokens.padding.small

    color: Colours.palette.onSurfaceVariant
    font: Tokens.font.label.medium
    elide: Text.ElideRight
}
