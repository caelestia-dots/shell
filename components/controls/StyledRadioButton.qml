import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Controls

RadioButton {
    id: root

    font.pointSize: Appearance.font.size.smaller

    indicator: Rectangle {
        id: outerCircle

        implicitWidth: 18
        implicitHeight: 18
        radius: Appearance.rounding.full
        color: "transparent"
        border.color: root.checked ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        border.width: 2
        anchors.verticalCenter: parent.verticalCenter

        Behavior on border.color {
            ColorAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }

        StyledRect {
            id: innerDot

            implicitWidth: 8
            implicitHeight: 8
            radius: Appearance.rounding.full
            color: root.checked ? Colours.palette.m3primary : "transparent"
            anchors.centerIn: parent
        }
    }

    contentItem: StyledText {
        text: root.text
        font.pointSize: root.font.pointSize
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: outerCircle.right
        anchors.leftMargin: Appearance.spacing.smaller
    }
}
