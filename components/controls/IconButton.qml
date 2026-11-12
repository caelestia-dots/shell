import QtQuick
import Caelestia.Config
import qs.components
import qs.services

ButtonBase {
    id: root

    property alias icon: label.text
    readonly property alias label: label

    font: Tokens.font.icon.medium
    padding: type === IconButton.Text ? Tokens.padding.extraSmall / 2 : Tokens.padding.small

    activeColour: type === IconButton.Filled ? Hallownest.soul : Hallownest.steel
    inactiveColour: {
        if (!isToggle && type === IconButton.Filled)
            return Hallownest.soul;
        return type === IconButton.Filled ? Hallownest.card : Hallownest.button;
    }
    activeOnColour: type === IconButton.Filled ? Hallownest.void_ : type === IconButton.Tonal ? Hallownest.void_ : Hallownest.soul
    inactiveOnColour: {
        if (!isToggle && type === IconButton.Filled)
            return Hallownest.void_;
        return type === IconButton.Tonal ? Hallownest.text : Hallownest.subtext;
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
