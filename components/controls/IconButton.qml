import ".."
import qs.services
import qs.config
import QtQuick

StyledRect {
    id: root

    enum Type {
        Filled,
        Tonal,
        Text
    }

    property alias icon: label.text
    property bool checked
    property bool toggle
    property real padding: type === IconButton.Text ? Appearance.padding.small / 2 : Appearance.padding.smaller
    property alias font: label.font
    property int type: IconButton.Filled
    property bool disabled

    property alias stateLayer: stateLayer
    property alias label: label
    property alias radiusAnim: radiusAnim

    property bool internalChecked
    property color activeColour: type === IconButton.Filled ? Colours.palette.m3primary : Colours.palette.m3secondary
    property color inactiveColour: {
        if (!toggle && type === IconButton.Filled)
            return Colours.palette.m3primary;
        return type === IconButton.Filled ? Colours.tPalette.m3surfaceContainer : Colours.palette.m3secondaryContainer;
    }
    property color activeOnColour: type === IconButton.Filled ? Colours.palette.m3onPrimary : type === IconButton.Tonal ? Colours.palette.m3onSecondary : Colours.palette.m3primary
    property color inactiveOnColour: {
        if (!toggle && type === IconButton.Filled)
            return Colours.palette.m3onPrimary;
        return type === IconButton.Tonal ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant;
    }
    property color disabledColour: Qt.alpha(Colours.palette.m3onSurface, 0.1)
    property color disabledOnColour: Qt.alpha(Colours.palette.m3onSurface, 0.38)

    signal clicked

    onCheckedChanged: internalChecked = checked

    radius: internalChecked ? Appearance.rounding.small : implicitHeight / 2
    color: type === IconButton.Text ? "transparent" : disabled ? disabledColour : internalChecked ? activeColour : inactiveColour

    implicitWidth: implicitHeight
    implicitHeight: label.implicitHeight + padding * 2

    StateLayer {
        id: stateLayer

        color: root.internalChecked ? root.activeOnColour : root.inactiveOnColour
        disabled: root.disabled

        function onClicked(): void {
            if (root.toggle)
                root.internalChecked = !root.internalChecked;
            root.clicked();
        }
    }

    MaterialIcon {
        id: label

        anchors.centerIn: parent
        color: root.disabled ? root.disabledOnColour : root.internalChecked ? root.activeOnColour : root.inactiveOnColour
        fill: !root.toggle || root.internalChecked ? 1 : 0

        Behavior on fill {
            Anim {}
        }
    }

    Behavior on radius {
        Anim {
            id: radiusAnim
        }
    }
}
