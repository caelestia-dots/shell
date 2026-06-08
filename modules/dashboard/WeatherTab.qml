import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.services
import "weather"

Item {
    id: root

    implicitWidth: layout.implicitWidth > 800 ? layout.implicitWidth : 840
    implicitHeight: layout.implicitHeight
    Component.onCompleted: Weather.reload()

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        CityInfo {}

        BigInfo {}

        DailyForecast {}
    }
}
