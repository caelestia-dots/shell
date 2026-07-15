import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property int rootHeight

    spacing: Tokens.spacing.extraSmall

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: Weather.description
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.large
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.medium

        StyledText {
            id: temp

            animate: true
            text: Weather.temp
            color: Colours.palette.m3primary
            font: Tokens.font.headline.builders.large.scale(1.5).weight(Font.DemiBold).width(80).build()
        }

        MaterialIcon {
            animate: true
            text: Weather.icon
            color: Colours.palette.m3secondary
            fontStyle: Tokens.font.headline.builders.large.scale(1.5).build()
        }
    }

    StyledText {
        visible: root.rootHeight > Tokens.sizes.lock.showWeatherDetailsHeight
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: qsTr("Feels like %1").arg(Weather.temp)
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.large
    }

    StyledText {
        visible: root.rootHeight > Tokens.sizes.lock.showWeatherDetailsHeight
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: {
            const today = Weather.forecast[0];
            return qsTr("High %1 • Low %2").arg(Weather.formatTemp(today?.maxTempC)).arg(Weather.formatTemp(today?.minTempC));
        }
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.medium
    }
}
