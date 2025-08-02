import qs.services
import qs.config
import QtQuick
import QtQuick.Controls

RadioButton {
    id: root

    implicitWidth: contentItem.implicitWidth + 32

    indicator: Rectangle {
        id: outerCircle
        width: 18
        height: 18
        radius: width / 2
        color: "transparent"
        border.color: checked ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        border.width: 2
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            id: innerDot
            width: 8
            height: 8
            radius: width / 2
            color: Colours.palette.m3primary
            anchors.centerIn: parent
            visible: root.checked
        }
    }

    contentItem: StyledText {
        text: root.text
        font.pointSize: root.font.pointSize
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: outerCircle.right
        anchors.leftMargin: 8
    }
}
