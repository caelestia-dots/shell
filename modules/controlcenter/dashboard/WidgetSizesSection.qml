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

            SliderInput {
                Layout.fillWidth: true
                
                label: qsTr("Widget width")
                value: root.rootItem.weatherWidth
                from: 150
                to: 400
                suffix: "px"
                validator: IntValidator { bottom: 150; top: 400 }
                formatValueFunction: (val) => Math.round(val).toString()
                parseValueFunction: (text) => parseInt(text)
                
                onValueModified: (newValue) => {
                    root.rootItem.weatherWidth = Math.round(newValue);
                    root.rootItem.saveConfig();
                }
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

            SliderInput {
                Layout.fillWidth: true
                
                label: qsTr("Info width")
                value: root.rootItem.infoWidth
                from: 150
                to: 400
                suffix: "px"
                validator: IntValidator { bottom: 150; top: 400 }
                formatValueFunction: (val) => Math.round(val).toString()
                parseValueFunction: (text) => parseInt(text)
                
                onValueModified: (newValue) => {
                    root.rootItem.infoWidth = Math.round(newValue);
                    root.rootItem.saveConfig();
                }
            }

            SliderInput {
                Layout.fillWidth: true
                
                label: qsTr("Icon size")
                value: root.rootItem.infoIconSize
                from: 16
                to: 48
                suffix: "px"
                validator: IntValidator { bottom: 16; top: 48 }
                formatValueFunction: (val) => Math.round(val).toString()
                parseValueFunction: (text) => parseInt(text)
                
                onValueModified: (newValue) => {
                    root.rootItem.infoIconSize = Math.round(newValue);
                    root.rootItem.saveConfig();
                }
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

            SliderInput {
                Layout.fillWidth: true
                
                label: qsTr("Widget width")
                value: root.rootItem.dateTimeWidth
                from: 80
                to: 200
                suffix: "px"
                validator: IntValidator { bottom: 80; top: 200 }
                formatValueFunction: (val) => Math.round(val).toString()
                parseValueFunction: (text) => parseInt(text)
                
                onValueModified: (newValue) => {
                    root.rootItem.dateTimeWidth = Math.round(newValue);
                    root.rootItem.saveConfig();
                }
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

            SliderInput {
                Layout.fillWidth: true
                
                label: qsTr("Indicator height")
                value: root.rootItem.tabIndicatorHeight
                from: 1
                to: 10
                suffix: "px"
                validator: IntValidator { bottom: 1; top: 10 }
                formatValueFunction: (val) => Math.round(val).toString()
                parseValueFunction: (text) => parseInt(text)
                
                onValueModified: (newValue) => {
                    root.rootItem.tabIndicatorHeight = Math.round(newValue);
                    root.rootItem.saveConfig();
                }
            }

            SliderInput {
                Layout.fillWidth: true
                
                label: qsTr("Indicator spacing")
                value: root.rootItem.tabIndicatorSpacing
                from: 2
                to: 20
                suffix: "px"
                validator: IntValidator { bottom: 2; top: 20 }
                formatValueFunction: (val) => Math.round(val).toString()
                parseValueFunction: (text) => parseInt(text)
                
                onValueModified: (newValue) => {
                    root.rootItem.tabIndicatorSpacing = Math.round(newValue);
                    root.rootItem.saveConfig();
                }
            }
        }
    }
}
