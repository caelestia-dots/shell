import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.config

Item {
    id: root

    required property string key
    property string label
    property string desc

    RowLayout {
        Layout.margins: Appearance.padding.large
        Layout.fillWidth: true

        StyledRect {
            implicitWidth: keybindingKey.implicitWidth + Appearance.padding.normal * 2
            implicitHeight: keybindingKey.implicitHeight + Appearance.padding.normal * 2
            radius: Appearance.rounding.small / 2
            color: Colours.palette.m3surfaceContainerHigh
            border.color: Colours.palette.m3outline

            StyledText {
                id: keybindingKey

                anchors.centerIn: parent
                text: root.key
                font.bold: true
                font.pointSize: Appearance.font.size.small * 0.66
                color: Colours.palette.m3primary
            }
        }

        ColumnLayout {
            spacing: 2

            StyledText {
                text: root.label
                font.pointSize: Appearance.font.size.small
                font.bold: true
                color: Colours.palette.m3onSurface
            }

            StyledText {
                text: root.desc
                visible: root.desc
                font.pointSize: Appearance.font.size.small * 0.66
                color: Colours.palette.m3onSurfaceVariant
                opacity: 0.7
            }
        }
    }
}