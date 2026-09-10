pragma ComponentBehavior: Bound

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
            id: flash

            topLeftRadius: root.topLeftRadius
            topRightRadius: root.topRightRadius
            bottomLeftRadius: root.bottomLeftRadius
            bottomRightRadius: root.bottomRightRadius
            color: Colours.palette.m3primary
            opacity: 0

            SequentialAnimation {
                running: true
                onFinished: highlight.active = false

                Anim {
                    target: flash
                    property: "opacity"
                    to: 0.2
                    duration: Tokens.anim.durations.small
                }
                Anim {
                    target: flash
                    property: "opacity"
                    to: 0.08
                    duration: Tokens.anim.durations.normal
                }
                Anim {
                    target: flash
                    property: "opacity"
                    to: 0.2
                    duration: Tokens.anim.durations.small
                }
                Anim {
                    target: flash
                    property: "opacity"
                    to: 0
                    duration: Tokens.anim.durations.extraLarge
                }
            }
        }
    }
}
