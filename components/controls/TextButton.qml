import QtQuick
import Caelestia.Config
import qs.components
import qs.services

ButtonBase {
    id: root

    property alias text: label.text
    readonly property alias label: label

    horizontalPadding: Tokens.padding.medium
    verticalPadding: Tokens.padding.small

    activeColour: type === TextButton.Filled ? Colours.palette.m3primary : Colours.palette.m3secondary
    inactiveColour: {
        if (!isToggle && type === TextButton.Filled)
            return Colours.palette.m3primary;
        return type === TextButton.Filled ? Colours.tPalette.m3surfaceContainer : Colours.palette.m3secondaryContainer;
    }
    activeOnColour: {
        if (type === TextButton.Text)
            return Colours.palette.m3primary;
        return type === TextButton.Filled ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondary;
    }
    inactiveOnColour: {
        if (!isToggle && type === TextButton.Filled)
            return Colours.palette.m3onPrimary;
        if (type === TextButton.Text)
            return Colours.palette.m3primary;
        return type === TextButton.Filled ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer;
    }

    implicitWidth: label.implicitWidth + horizontalPadding * 2
    implicitHeight: label.implicitHeight + verticalPadding * 2

    StyledText {
        id: label

        anchors.centerIn: parent
        color: root.onColour
        font: root.font
    }
}
