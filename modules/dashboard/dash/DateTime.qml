import qs.widgets
import qs.services
import qs.config
import QtQuick

Item {
    id: root

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Config.dashboard.sizes.dateTimeWidth

    StyledText {
        id: hours

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: (root.height - (hours.implicitHeight + sep.implicitHeight + sep.anchors.topMargin + mins.implicitHeight + mins.anchors.topMargin + date.implicitHeight + date.anchors.topMargin)) / 2

        horizontalAlignment: Text.AlignHCenter
        text: Time.format("HH")
        color: Colours.palette.m3secondary
        font.pointSize: Appearance.font.size.extraLarge
        font.weight: 500
    }

    StyledText {
        id: sep

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: hours.bottom
        anchors.topMargin: -font.pointSize * 0.5

        horizontalAlignment: Text.AlignHCenter
        text: "•••"
        color: Colours.palette.m3primary
        font.pointSize: Appearance.font.size.extraLarge * 0.9
    }

    StyledText {
        id: mins

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sep.bottom
        anchors.topMargin: -sep.font.pointSize * 0.45

        horizontalAlignment: Text.AlignHCenter
        text: Time.format("mm")
        color: Colours.palette.m3secondary
        font.pointSize: Appearance.font.size.extraLarge
        font.weight: 500
    }

    StyledText {
        id: date

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: mins.bottom
        anchors.topMargin: Appearance.spacing.normal

        horizontalAlignment: Text.AlignHCenter
        text: Time.format("ddd, d")
        color: Colours.palette.m3tertiary
        font.pointSize: Appearance.font.size.normal
        font.weight: 500
    }
}
