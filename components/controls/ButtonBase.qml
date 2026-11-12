import QtQuick
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    enum ButtonType {
        Filled,
        Tonal,
        Text
    }

    property bool checked
    property alias disabled: stateLayer.disabled
    property bool isToggle
    property bool isRound

    property bool radiusMorph: true
    property alias shapeMorph: stateLayer.shapeMorph
    property bool fillWidth // For ButtonRow

    property font font: Tokens.font.body.small
    property int type: ButtonBase.Filled

    property real padding
    property real horizontalPadding: padding
    property real verticalPadding: padding

    readonly property alias pressed: stateLayer.pressed
    readonly property alias hovered: stateLayer.containsMouse
    readonly property alias stateLayer: stateLayer
    readonly property alias radiusAnim: radiusAnim

    property color activeColour
    property color inactiveColour
    property color activeOnColour
    property color inactiveOnColour
    property color disabledColour: Qt.alpha(Hallownest.text, 0.1)
    property color disabledOnColour: Qt.alpha(Hallownest.text, 0.38)

    property bool internalChecked
    property real shapeMorphExpansion: 0
    readonly property color onColour: disabled ? disabledOnColour : internalChecked ? activeOnColour : inactiveOnColour

    property real pressedRadius: Tokens.rounding.small
    property real defaultRadius: Tokens.rounding.large

    signal clicked

    onCheckedChanged: internalChecked = checked

    radius: Math.min((height || implicitHeight) / 2, isRound ? 999 : 16)
    color: type === ButtonBase.Text ? "transparent" : disabled ? disabledColour : internalChecked ? activeColour : inactiveColour
    border.width: type === ButtonBase.Text ? 0 : 1
    border.color: internalChecked ? Qt.alpha(activeOnColour, 0.25) : Hallownest.border
    scale: pressed ? 0.95 : 1

    Behavior on scale {
        Anim {
            type: Anim.FastSpatial
        }
    }

    // Make size required so we don't forget to set it
    required implicitWidth
    required implicitHeight

    StateLayer {
        id: stateLayer

        color: root.internalChecked ? root.activeOnColour : root.inactiveOnColour
        disabled: root.disabled
        onClicked: {
            if (root.isToggle)
                root.internalChecked = !root.internalChecked;
            root.clicked();
        }
    }

    Behavior on radius {
        Anim {
            id: radiusAnim

            type: Anim.DefaultEffects
        }
    }

    Behavior on shapeMorphExpansion {
        Anim {
            type: Anim.FastSpatial
        }
    }
}
