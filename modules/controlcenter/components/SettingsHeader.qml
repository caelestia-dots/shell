pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components

Item {
    id: root

    required property string icon
    required property string title

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column

        anchors.centerIn: parent
        spacing: Tokens.spacing.normal

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            font.pointSize: Tokens.font.size.extraLarge * 3
            font.bold: true
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.title
            font.pointSize: Tokens.font.size.large
            font.bold: true
        }
    }
}
