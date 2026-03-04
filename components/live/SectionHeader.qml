import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property int fontSize: Appearance.font.size.extraLarge

    Layout.fillWidth: true
    height: sectionHeader.implicitHeight

    ColumnLayout {
        id: sectionHeader

        spacing: Appearance.spacing.small

        StyledText {
            text: root.title
            font.pointSize: root.fontSize
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