import QtQuick
import Caelestia.Config
import Caelestia.Scheme
import qs.components

ButtonBase {
    id: root

    property alias text: label.text
    readonly property alias label: label

    horizontalPadding: Tokens.padding.medium
    verticalPadding: Tokens.padding.small

    activeColour: type === TextButton.Filled ? Colours.palette.primary : Colours.palette.secondary
    inactiveColour: {
        if (!isToggle && type === TextButton.Filled)
            return Colours.palette.primary;
        return type === TextButton.Filled ? Colours.tPalette.surfaceContainer : Colours.palette.secondaryContainer;
    }
    activeOnColour: {
        if (type === TextButton.Text)
            return Colours.palette.primary;
        return type === TextButton.Filled ? Colours.palette.onPrimary : Colours.palette.onSecondary;
    }
    inactiveOnColour: {
        if (!isToggle && type === TextButton.Filled)
            return Colours.palette.onPrimary;
        if (type === TextButton.Text)
            return Colours.palette.primary;
        return type === TextButton.Filled ? Colours.palette.onSurface : Colours.palette.onSecondaryContainer;
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
