import QtQuick
import Caelestia.Config
import Caelestia.Scheme
import qs.components

ButtonBase {
    id: root

    property alias icon: label.text
    readonly property alias label: label

    font: Tokens.font.icon.medium
    padding: type === IconButton.Text ? Tokens.padding.extraSmall / 2 : Tokens.padding.small

    activeColour: type === IconButton.Filled ? Colours.palette.primary : Colours.palette.secondary
    inactiveColour: {
        if (!isToggle && type === IconButton.Filled)
            return Colours.palette.primary;
        return type === IconButton.Filled ? Colours.tPalette.surfaceContainer : Colours.palette.secondaryContainer;
    }
    activeOnColour: type === IconButton.Filled ? Colours.palette.onPrimary : type === IconButton.Tonal ? Colours.palette.onSecondary : Colours.palette.primary
    inactiveOnColour: {
        if (!isToggle && type === IconButton.Filled)
            return Colours.palette.onPrimary;
        return type === IconButton.Tonal ? Colours.palette.onSecondaryContainer : Colours.palette.onSurfaceVariant;
    }

    implicitWidth: implicitHeight
    implicitHeight: {
        // Ensure even size so icon is centered properly
        const h = label.implicitHeight + padding * 2;
        if (h % 2 !== 0)
            return h + 1;
        return h;
    }

    MaterialIcon {
        id: label

        anchors.centerIn: parent
        anchors.verticalCenterOffset: 1 // AHHHHHHH material symbols whyyyy
        color: root.onColour
        fontStyle: root.font
        fill: !root.isToggle || root.internalChecked ? 1 : 0

        Behavior on fill {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
