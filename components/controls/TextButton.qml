import ".."
import QtQuick
import Caelestia.Config
import qs.services

StyledRect {
    id: root

    enum Type {
        Filled,
        Tonal,
        Text
    }

    property alias text: label.text
    property bool checked
    property bool toggle
    property real horizontalPadding: Tokens.padding.normal
    property real verticalPadding: Tokens.padding.smaller
    property alias font: label.font
    property int type: TextButton.Filled

    property alias stateLayer: stateLayer
    property alias label: label

    property bool internalChecked
    property color activeColour: type === TextButton.Filled ? Colours.palette.m3primary : Colours.palette.m3secondary
    property color inactiveColour: {
        if (!toggle && type === TextButton.Filled)
            return Colours.palette.m3primary;
        return type === TextButton.Filled ? Colours.tPalette.m3surfaceContainer : Colours.palette.m3secondaryContainer;
    }
    property color activeOnColour: {
        if (type === TextButton.Text)
            return Colours.palette.m3primary;
        return type === TextButton.Filled ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondary;
    }
    property color inactiveOnColour: {
        if (!toggle && type === TextButton.Filled)
            return Colours.palette.m3onPrimary;
        if (type === TextButton.Text)
            return Colours.palette.m3primary;
        return type === TextButton.Filled ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer;
    }

    signal clicked

    onCheckedChanged: internalChecked = checked

    radius: internalChecked ? Tokens.rounding.small : implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
    color: type === TextButton.Text ? "transparent" : internalChecked ? activeColour : inactiveColour

    implicitWidth: label.implicitWidth + horizontalPadding * 2
    implicitHeight: label.implicitHeight + verticalPadding * 2

    StateLayer {
        id: stateLayer

        function onClicked(): void {
            if (root.toggle)
                root.internalChecked = !root.internalChecked;
            root.clicked();
        }

        color: root.internalChecked ? root.activeOnColour : root.inactiveOnColour
    }

    StyledText {
        id: label

        anchors.centerIn: parent
        color: root.internalChecked ? root.activeOnColour : root.inactiveOnColour
    }

    Behavior on radius {
        Anim {}
    }
}
