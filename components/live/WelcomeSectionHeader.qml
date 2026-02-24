import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

Item {
    id: root

    property string title: ""
    property string subtitle: ""

    height: sectionHeader.implicitHeight

    ColumnLayout {
        id: sectionHeader

        StyledText {
            text: root.title
            font.pointSize: Appearance.font.size.extraLarge
            font.bold: true
            color: Colours.palette.m3onBackground
        }

        StyledText {
            Layout.fillWidth: true
            text: root.subtitle
            font.pointSize: Appearance.font.size.normal
            color: Colours.palette.m3onSurfaceVariant
            wrapMode: Text.WordWrap
        }
    }
}