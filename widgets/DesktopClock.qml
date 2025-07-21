import QtQuick
import QtQuick.Controls
import qs.config

Item {
    id: clockRoot
    width: 200
    height: 80

    property alias time: timeText.text

    Timer {
        id: timer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date();
            var h = now.getHours().toString().padStart(2, '0');
            var m = now.getMinutes().toString().padStart(2, '0');
            var s = now.getSeconds().toString().padStart(2, '0');
            timeText.text = h + ":" + m + ":" + s;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#00000080"
        radius: 16
    }

    Text {
        id: timeText
        anchors.centerIn: parent
        font.pixelSize: 48
        color: Appearance.desktopClock.color
        font.bold: true
        text: "--:--:--"
    }
}
