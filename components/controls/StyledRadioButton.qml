import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Templates

RadioButton {
    id: root

    font.pointSize: Appearance.font.size.smaller

    implicitWidth: implicitIndicatorWidth + implicitContentWidth + contentItem.anchors.leftMargin
    implicitHeight: Math.max(implicitIndicatorHeight, implicitContentHeight)

    indicator: Rectangle {
        id: outerCircle

        implicitWidth: 20
        implicitHeight: 20
        radius: Appearance.rounding.full
        color: "transparent"
        border.color: root.checked ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        border.width: 2
        anchors.verticalCenter: parent.verticalCenter

        StateLayer {
            anchors.margins: -Appearance.padding.smaller
            color: root.checked ? Colours.palette.m3onSurface : Colours.palette.m3primary
            z: -1

            function onClicked(): void {
                root.click();
            }
        }

        StyledRect {
            anchors.centerIn: parent
            implicitWidth: 8
            implicitHeight: 8

            radius: Appearance.rounding.full
            color: Qt.alpha(Colours.palette.m3primary, root.checked ? 1 : 0)
        }

        Behavior on border.color {
            CAnim {}
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
