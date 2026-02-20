import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string description: ""

    implicitHeight: 160
    radius: 16
    color: Colours.palette.m3surfaceContainerHigh

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        MaterialIcon {
            text: root.icon
            font.pointSize: 32
            color: Colours.palette.m3primary
        }

        Text {
            text: root.title
            font.pointSize: 14
            font.bold: true
            color: Colours.palette.m3onSurface
        }

        Text {
            Layout.fillWidth: true
            text: root.description
            font.pointSize: 10
            color: Colours.palette.m3onSurfaceVariant
            wrapMode: Text.WordWrap
        }
    }
}