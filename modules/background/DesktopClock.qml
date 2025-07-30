import qs.widgets
import qs.services
import qs.config
import QtQuick

Item {
    implicitWidth: timeText.implicitWidth + Appearance.padding.large * 2
    implicitHeight: timeText.implicitHeight + Appearance.padding.large * 2

    StyledText {
        id: timeText

        anchors.centerIn: parent
        text: Time.format(Config.services.useTwelveHourClock ? "hh:mm:ss A" : "hh:mm:ss")
        font.pointSize: Appearance.font.size.extraLarge
        font.bold: true
    }
}
