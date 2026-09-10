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
        highlight.active = false;
        highlight.active = true;
    }

    color: Colours.tPalette.m3surfaceContainer
    topLeftRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    topRightRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomLeftRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomRightRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall

    // Created only while flashing, so rows don't each carry the animation
    Loader {
        id: highlight

        anchors.fill: parent
        active: false

        sourceComponent: StyledRect {
            topLeftRadius: root.topLeftRadius
            topRightRadius: root.topRightRadius
            bottomLeftRadius: root.bottomLeftRadius
            bottomRightRadius: root.bottomRightRadius
            color: Colours.palette.m3primary
            opacity: 0

            SequentialAnimation on opacity {
                onFinished: highlight.active = false

                Anim {
                    to: 0.2
                    duration: Tokens.anim.durations.small
                }
                Anim {
                    to: 0.08
                    duration: Tokens.anim.durations.normal
                }
                Anim {
                    to: 0.2
                    duration: Tokens.anim.durations.small
                }
                Anim {
                    to: 0
                    duration: Tokens.anim.durations.extraLarge
                }
            }
        }
    }
}
