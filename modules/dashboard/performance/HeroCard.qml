import QtQuick
import QtQuick.Layouts
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property string icon
    required property string label
    required property string subLabel
    required property color accent
    required property real usage
    required property real temperature

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraLarge

    implicitWidth: Tokens.sizes.dashboard.perfHeroCardWidth
    implicitHeight: Math.max(tempProg.implicitHeight + detailsRow.implicitHeight + Tokens.spacing.large, usageShape.implicitHeight + usageLabel.implicitHeight) + Tokens.padding.large * 2

    CircularProgress {
        id: tempProg

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: Tokens.padding.large

        fgColour: root.accent

        spacing: Tokens.spacing.extraSmall
        strokeWidth: Tokens.padding.extraSmall
        implicitSize: Math.max(icon.implicitWidth, icon.implicitHeight) + Tokens.padding.medium * 2
        value: root.usage

        Behavior on clampedVal {
            Anim {}
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            text: root.icon
            color: root.accent
            fontStyle: Tokens.font.icon.medium
        }
    }

    ColumnLayout {
        anchors.left: tempProg.right
        anchors.right: parent.right
        anchors.verticalCenter: tempProg.verticalCenter
        anchors.margins: Tokens.spacing.large
        spacing: Tokens.spacing.extraSmall

        StyledText {
            text: root.label
            font: Tokens.font.title.medium
            color: root.accent
        }

        StyledText {
            Layout.fillWidth: true
            text: root.subLabel
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
            elide: Text.ElideRight
        }
    }

    ColumnLayout {
        id: detailsRow

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.extraSmall

        RowLayout {
            Layout.leftMargin: -Tokens.padding.extraSmall
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                Layout.topMargin: Math.round(fontInfo.pointSize * 0.08)
                text: root.temperature > 90 ? "thermometer_alert" : "thermometer"
                color: root.temperature > 90 ? Colours.palette.m3error : root.accent
                fontStyle: Tokens.font.icon.medium
                fill: 1
            }

            StyledText {
                text: `${Math.ceil(GlobalConfig.services.useFahrenheitPerformance ? root.temperature * 1.8 + 32 : root.temperature)}°${GlobalConfig.services.useFahrenheitPerformance ? "F" : "C"}`
                font: Tokens.font.body.builders.medium.build()
            }
        }

        StyledProgressBar {
            value: root.temperature / 100
            implicitHeight: Tokens.padding.small
            fgColour: root.accent
            indeterminate: isNaN(root.usage) || isNaN(root.temperature)
        }
    }

    MaterialShape {
        id: usageShape

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.medium

        implicitSize: Tokens.sizes.dashboard.perfUsageShapeSize
        color: Colours.palette.m3secondaryContainer
        shape: {
            if (root.usage >= 0.8)
                return MaterialShape.SoftBurst;
            if (root.usage >= 0.4)
                return MaterialShape.Sunny;
            return MaterialShape.Cookie4Sided;
        }

        Behavior on color {
            CAnim {}
        }

        StyledText {
            id: usageLabel

            anchors.bottom: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            text: qsTr("Usage")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
        }

        StyledText {
            anchors.centerIn: parent
            text: isNaN(root.usage) ? "...%" : Math.round(root.usage * 100) + "%"
            color: root.accent
            font: Tokens.font.headline.builders.small.width(50).build()
        }
    }
}
