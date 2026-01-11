import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var rootItem

    Layout.fillWidth: true
    spacing: Appearance.spacing.normal

    // Weather Widget
    SectionContainer {
        Layout.fillWidth: true
        alignTop: true

        StyledText {
            text: qsTr("Weather Widget")
            font.pointSize: Appearance.font.size.normal
        }

        SectionContainer {
            contentSpacing: Appearance.spacing.normal

            ReadonlySlider {
                Layout.fillWidth: true
                label: qsTr("Widget width")
                value: root.rootItem.weatherWidth
                from: 150
                to: 400
                suffix: "px"
                readonly: true
            }
        }
    }

    // User Info Widget
    SectionContainer {
        Layout.fillWidth: true
        alignTop: true

        StyledText {
            text: qsTr("User Info Widget")
            font.pointSize: Appearance.font.size.normal
        }

        SectionContainer {
            contentSpacing: Appearance.spacing.normal

            ReadonlySlider {
                Layout.fillWidth: true
                label: qsTr("Info width")
                value: root.rootItem.infoWidth
                from: 150
                to: 400
                suffix: "px"
                readonly: true
            }

            ReadonlySlider {
                Layout.fillWidth: true
                label: qsTr("Icon size")
                value: root.rootItem.infoIconSize
                from: 16
                to: 48
                suffix: "px"
                readonly: true
            }
        }
    }

    // DateTime Widget
    SectionContainer {
        Layout.fillWidth: true
        alignTop: true

        StyledText {
            text: qsTr("DateTime Widget")
            font.pointSize: Appearance.font.size.normal
        }

        SectionContainer {
            contentSpacing: Appearance.spacing.normal

            ReadonlySlider {
                Layout.fillWidth: true
                label: qsTr("Widget width")
                value: root.rootItem.dateTimeWidth
                from: 80
                to: 200
                suffix: "px"
                readonly: true
            }
        }
    }

    // Tab Indicator
    SectionContainer {
        Layout.fillWidth: true
        alignTop: true

        StyledText {
            text: qsTr("Tab Indicator")
            font.pointSize: Appearance.font.size.normal
        }

        SectionContainer {
            contentSpacing: Appearance.spacing.normal

            ReadonlySlider {
                Layout.fillWidth: true
                label: qsTr("Indicator height")
                value: root.rootItem.tabIndicatorHeight
                from: 1
                to: 10
                suffix: "px"
                readonly: true
            }

            ReadonlySlider {
                Layout.fillWidth: true
                label: qsTr("Indicator spacing")
                value: root.rootItem.tabIndicatorSpacing
                from: 2
                to: 20
                suffix: "px"
                readonly: true
            }
        }
    }
}
