import qs.widgets
import qs.services
import qs.config
import QtQuick

Item {
    implicitWidth: timeText.implicitWidth + Appearance.padding.large * 2
    implicitHeight: timeText.implicitHeight + Appearance.padding.large * 2

    StyledText {
        id: timeText

        readonly property string clockFormat: Config.services.useTwelveHourClock ? "hh:mm:ss A" : "hh:mm:ss"

        anchors.centerIn: parent
        text: Time.format(clockFormat)
        font.pointSize: Appearance.font.size.extraLarge
        font.bold: true
    }
}
