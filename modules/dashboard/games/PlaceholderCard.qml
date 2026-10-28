import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property string icon
    required property string title
    required property string body

    implicitWidth: 840
    implicitHeight: col.implicitHeight + Tokens.padding.extraLarge * 2
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: col

        anchors.centerIn: parent
        width: Math.max(200, root.width - Tokens.padding.extraLarge * 2)
        spacing: Tokens.spacing.small

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.6).build()
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.title
            font: Tokens.font.title.medium
            color: Colours.palette.m3onSurface
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.body
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
            wrapMode: Text.WordWrap
        }
    }
}
