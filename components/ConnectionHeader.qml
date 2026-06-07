import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components

ColumnLayout {
    id: root

    required property string icon
    required property string title

    spacing: Tokens.spacing.medium
    Layout.alignment: Qt.AlignHCenter

    MaterialIcon {
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: root.icon
        fontStyle: Tokens.font.icon.builders.extraLarge.scale(3).weight(Font.Bold).build()
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: root.title
        font: Tokens.font.title.builders.medium.weight(Font.Bold).build()
    }
}
