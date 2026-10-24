import QtQuick
import QtQuick.Templates
import Caelestia.Config
import Caelestia.Scheme
import qs.components

RadioButton {
    id: root

    font: Tokens.font.body.small

    implicitWidth: implicitIndicatorWidth + implicitContentWidth + contentItem.anchors.leftMargin
    implicitHeight: Math.max(implicitIndicatorHeight, implicitContentHeight)

    indicator: Rectangle {
        id: outerCircle

        implicitWidth: 20
        implicitHeight: 20
        radius: Tokens.rounding.full
        color: "transparent"
        border.color: root.checked ? Colours.palette.primary : Colours.palette.onSurfaceVariant
        border.width: 2
        anchors.verticalCenter: parent.verticalCenter

        StateLayer {
            anchors.margins: -Tokens.padding.small
            color: root.checked ? Colours.palette.onSurface : Colours.palette.primary
            z: -1
            onClicked: root.click()
        }

        StyledRect {
            anchors.centerIn: parent
            implicitWidth: 8
            implicitHeight: 8

            radius: Tokens.rounding.full
            color: Qt.alpha(Colours.palette.primary, root.checked ? 1 : 0)
        }

        Behavior on border.color {
            CAnim {}
        }
    }

    contentItem: StyledText {
        text: root.text
        font: root.font
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: outerCircle.right
        anchors.right: parent.right
        anchors.leftMargin: Tokens.spacing.medium
        elide: Text.ElideRight
    }
}
