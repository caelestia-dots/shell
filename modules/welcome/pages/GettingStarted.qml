import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: 24

    Text {
        text: "Getting Started"
        font.pointSize: 28
        font.bold: true
        color: "#cdd6f4"
    }

    Text {
        Layout.fillWidth: true
        text: "Learn how to use and update Caelestia shell"
        font.pointSize: 12
        color: "#a6adc8"
        wrapMode: Text.WordWrap
    }

    // Placeholder content
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 200
        radius: 12
        color: "#181825"

        Text {
            anchors.centerIn: parent
            text: "Content coming soon:\n• How to update the shell\n• CLI usage\n• FAQ"
            font.pointSize: 11
            color: "#a6adc8"
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Item { Layout.fillHeight: true }
}