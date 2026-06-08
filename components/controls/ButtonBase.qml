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

    property font font
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
    property color disabledColour: Qt.alpha(Colours.palette.m3onSurface, 0.1)
    property color disabledOnColour: Qt.alpha(Colours.palette.m3onSurface, 0.38)

    property bool internalChecked
    property real shapeMorphExpansion: shapeMorph && pressed ? 24 : 0 // Apparently it's always 24px no matter the width of the button
    readonly property color onColour: disabled ? disabledOnColour : internalChecked ? activeOnColour : inactiveOnColour

    property real pressedRadius: Tokens.rounding.small
    property real checkedRadius: Tokens.rounding.medium
    property real defaultRadius: Tokens.rounding.large

    signal clicked

    onCheckedChanged: internalChecked = checked

    radius: {
        if (radiusMorph && pressed)
            return pressedRadius;
        if (internalChecked)
            return checkedRadius;
        if (isRound)
            return (height || implicitHeight) / 2 * Math.min(1, Tokens.rounding.scale);
        return defaultRadius;
    }
    color: type === ButtonBase.Text ? "transparent" : disabled ? disabledColour : internalChecked ? activeColour : inactiveColour

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
