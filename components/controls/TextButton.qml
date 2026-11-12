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

    activeColour: type === TextButton.Filled ? Hallownest.soul : Hallownest.steel
    inactiveColour: {
        if (!isToggle && type === TextButton.Filled)
            return Hallownest.soul;
        return type === TextButton.Filled ? Hallownest.card : Hallownest.button;
    }
    activeOnColour: {
        if (type === TextButton.Text)
            return Hallownest.soul;
        return type === TextButton.Filled ? Hallownest.void_ : Hallownest.void_;
    }
    inactiveOnColour: {
        if (!isToggle && type === TextButton.Filled)
            return Hallownest.void_;
        if (type === TextButton.Text)
            return Hallownest.soul;
        return type === TextButton.Filled ? Hallownest.text : Hallownest.text;
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
