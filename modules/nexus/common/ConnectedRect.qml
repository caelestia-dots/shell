import QtQuick
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    property bool first
    property bool last
    // Identifier used by the settings search to scroll to this row.
    property string settingAnchor

    // Briefly flash the row, used when the settings search jumps to it.
    function flashHighlight(): void {
        flash.restart();
    }

    color: Colours.tPalette.m3surfaceContainer
    topLeftRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    topRightRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomLeftRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomRightRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall

    StyledRect {
        id: highlight

        anchors.fill: parent

        radius: parent.radius
        topLeftRadius: parent.topLeftRadius
        topRightRadius: parent.topRightRadius
        bottomLeftRadius: parent.bottomLeftRadius
        bottomRightRadius: parent.bottomRightRadius
        color: Colours.palette.m3primary
        opacity: 0

        SequentialAnimation {
            id: flash

            Anim {
                target: highlight
                property: "opacity"
                to: 0.12
                duration: Tokens.anim.durations.normal
            }
            Anim {
                target: highlight
                property: "opacity"
                to: 0
                duration: Tokens.anim.durations.large
            }
        }
    }
}
