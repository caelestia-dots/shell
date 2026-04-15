import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components

ColumnLayout {
    id: root

    required property string icon
    required property string title

    spacing: Tokens.spacing.normal
    Layout.alignment: Qt.AlignHCenter

    MaterialIcon {
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: root.icon
        font.pointSize: Tokens.font.size.extraLarge * 3
        font.bold: true
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: root.title
        font.pointSize: Tokens.font.size.large
        font.bold: true
    }
}
