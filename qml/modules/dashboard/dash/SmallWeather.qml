import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    anchors.centerIn: parent

    implicitWidth: icon.implicitWidth + info.implicitWidth + info.anchors.leftMargin
    implicitHeight: Math.max(icon.implicitHeight, info.implicitHeight) + Tokens.padding.largeIncreased * 2

    Component.onCompleted: Weather.reload()

    MaterialIcon {
        id: icon

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        animate: true
        text: Weather.icon
        color: Colours.palette.m3secondary
        fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.6).build()
    }

    Column {
        id: info

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: icon.right
        anchors.leftMargin: Tokens.spacing.largeIncreased

        spacing: Tokens.spacing.extraSmall

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter

            animate: true
            text: Weather.temp
            color: Colours.palette.m3primary
            font: Tokens.font.headline.builders.medium.width(110).weight(Font.DemiBold).build()
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter

            animate: true
            text: Weather.description
            font: Tokens.font.body.small

            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.parent.width - icon.implicitWidth - info.anchors.leftMargin - Tokens.padding.extraLargeIncreased)
        }
    }
}
