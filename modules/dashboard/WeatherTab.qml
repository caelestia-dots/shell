import QtQuick
import QtQuick.Layouts
import qs.services
import qs.config
import "weather"

Item {
    id: root

    implicitWidth: layout.implicitWidth > 800 ? layout.implicitWidth : 840
    implicitHeight: layout.implicitHeight
    Component.onCompleted: Weather.reload()

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Appearance.spacing.smaller

        CityInfo {}

        BigInfo {}

        DailyForecast {}
    }
}
