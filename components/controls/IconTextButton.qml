import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ButtonBase {
    id: root

    property alias icon: iconLabel.text
    property alias text: label.text
    property alias spacing: row.spacing

    readonly property alias iconLabel: iconLabel
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

    implicitWidth: row.implicitWidth + horizontalPadding * 2
    implicitHeight: row.implicitHeight + verticalPadding * 2

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        MaterialIcon {
            id: iconLabel

            Layout.alignment: Qt.AlignVCenter
            color: root.onColour
            fill: root.internalChecked ? 1 : 0
            fontStyle: {
                const f = Qt.font(root.font);
                f.pointSize = Math.round(root.font.pointSize * 1.2);
                return f;
            }

            Behavior on fill {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        StyledText {
            id: label

            Layout.alignment: Qt.AlignVCenter
            Layout.topMargin: 1
            color: root.onColour
            font: root.font
        }
    }
}
