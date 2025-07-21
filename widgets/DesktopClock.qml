import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.widgets

Item {
    id: clockRoot
    width: timeText.implicitWidth + Appearance.padding.large * 2
    height: timeText.implicitHeight + Appearance.padding.large * 2


    StyledText {
        id: timeText
        anchors.centerIn: parent
        font.pointSize: Appearance.font.size.extraLarge
        font.bold: true
        text: Time.format("hh:mm:ss");
    }
}
