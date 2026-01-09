import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

SectionContainer {
    id: root

    required property var rootItem

    Layout.fillWidth: true
    alignTop: true

    StyledText {
        text: qsTr("Media Widget")
        font.pointSize: Appearance.font.size.normal
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Update interval")
            value: root.rootItem.mediaUpdateInterval
            from: 100
            to: 2000
            suffix: "ms"
            validator: IntValidator { bottom: 100; top: 2000 }
            formatValueFunction: (val) => Math.round(val).toString()
            parseValueFunction: (text) => parseInt(text)
            
            onValueModified: (newValue) => {
                root.rootItem.mediaUpdateInterval = Math.round(newValue);
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Widget width")
            value: root.rootItem.mediaWidth
            from: 150
            to: 400
            suffix: "px"
            validator: IntValidator { bottom: 150; top: 400 }
            formatValueFunction: (val) => Math.round(val).toString()
            parseValueFunction: (text) => parseInt(text)
            
            onValueModified: (newValue) => {
                root.rootItem.mediaWidth = Math.round(newValue);
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Cover art size")
            value: root.rootItem.mediaCoverArtSize
            from: 80
            to: 250
            suffix: "px"
            validator: IntValidator { bottom: 80; top: 250 }
            formatValueFunction: (val) => Math.round(val).toString()
            parseValueFunction: (text) => parseInt(text)
            
            onValueModified: (newValue) => {
                root.rootItem.mediaCoverArtSize = Math.round(newValue);
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Progress sweep angle")
            value: root.rootItem.mediaProgressSweep
            from: 90
            to: 270
            suffix: "°"
            validator: IntValidator { bottom: 90; top: 270 }
            formatValueFunction: (val) => Math.round(val).toString()
            parseValueFunction: (text) => parseInt(text)
            
            onValueModified: (newValue) => {
                root.rootItem.mediaProgressSweep = Math.round(newValue);
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Progress thickness")
            value: root.rootItem.mediaProgressThickness
            from: 4
            to: 16
            suffix: "px"
            validator: IntValidator { bottom: 4; top: 16 }
            formatValueFunction: (val) => Math.round(val).toString()
            parseValueFunction: (text) => parseInt(text)
            
            onValueModified: (newValue) => {
                root.rootItem.mediaProgressThickness = Math.round(newValue);
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Visualiser size")
            value: root.rootItem.mediaVisualiserSize
            from: 40
            to: 150
            suffix: "px"
            validator: IntValidator { bottom: 40; top: 150 }
            formatValueFunction: (val) => Math.round(val).toString()
            parseValueFunction: (text) => parseInt(text)
            
            onValueModified: (newValue) => {
                root.rootItem.mediaVisualiserSize = Math.round(newValue);
                root.rootItem.saveConfig();
            }
        }
    }
}
