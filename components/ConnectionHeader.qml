import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property string icon
    required property string title

    spacing: Appearance.spacing.normal
    Layout.alignment: Qt.AlignHCenter

    MaterialIcon {
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: root.icon
        font.pointSize: Appearance.font.size.extraLarge * 3
        font.bold: true
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: root.title
        font.pointSize: Appearance.font.size.large
        font.bold: true
    }
}

