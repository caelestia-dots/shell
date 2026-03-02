pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

StyledRect {
    id: root

    property string title
    property string subtitle
    required property var content

    Layout.fillWidth: true
    Layout.preferredHeight: contentColumn.implicitHeight + Appearance.padding.large * 2
    color: Colours.palette.m3surfaceContainerLow
    radius: Appearance.rounding.normal
    border.color: Colours.palette.m3outlineVariant

    ColumnLayout {
        id: contentColumn

        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.small

        StyledText {
            visible: root.title
            font.pointSize: Appearance.font.size.normal
            font.bold: true
            color: Colours.palette.m3primary
            text: root.title
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.subtitle
            font.pointSize: Appearance.font.size.normal
            color: Colours.palette.m3onSurface
            wrapMode: Text.WordWrap
            text: root.subtitle
        }

        Loader {
            Layout.fillWidth: true
            Layout.topMargin: root.title || root.subtitle ? Appearance.padding.large : 0

            sourceComponent: content
        }
    }
}