import QtQuick
import QtQuick.Controls
import Caelestia.Config
import qs.components
import qs.services

TextField {
    id: root

    property string leadingIcon

    implicitHeight: 30
    leftPadding: leadingIcon ? 34 : 12
    rightPadding: 12
    topPadding: 0
    bottomPadding: 0
    verticalAlignment: TextInput.AlignVCenter
    color: Hallownest.soul
    placeholderTextColor: Hallownest.faint
    selectionColor: Qt.alpha(Hallownest.lifeblood, 0.4)
    selectedTextColor: Hallownest.soul
    font.pointSize: 10
    renderType: Text.NativeRendering

    background: Rectangle {
        radius: 9
        color: Hallownest.card
        border.width: 1
        border.color: root.activeFocus ? Qt.alpha(Hallownest.soul, 0.5) : Hallownest.border

        Behavior on border.color {
            CAnim {}
        }

        MaterialIcon {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            visible: root.leadingIcon !== ""
            text: root.leadingIcon
            color: Hallownest.subtext
            fontStyle: Tokens.font.icon.small
        }
    }
}
