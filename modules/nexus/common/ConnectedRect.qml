import QtQuick
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    property bool first
    property bool last
    // Identifier used by the settings search to scroll to this row.
    property string settingAnchor

    color: Colours.tPalette.m3surfaceContainer
    topLeftRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    topRightRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomLeftRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomRightRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
}
