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

        ReadonlySlider {
            Layout.fillWidth: true
            label: qsTr("Widget width")
            value: root.rootItem.mediaWidth
            from: 150
            to: 400
            suffix: "px"
            readonly: true
        }

        ReadonlySlider {
            Layout.fillWidth: true
            label: qsTr("Cover art size")
            value: root.rootItem.mediaCoverArtSize
            from: 80
            to: 250
            suffix: "px"
            readonly: true
        }

        ReadonlySlider {
            Layout.fillWidth: true
            label: qsTr("Progress sweep angle")
            value: root.rootItem.mediaProgressSweep
            from: 90
            to: 270
            suffix: "°"
            readonly: true
        }

        ReadonlySlider {
            Layout.fillWidth: true
            label: qsTr("Progress thickness")
            value: root.rootItem.mediaProgressThickness
            from: 4
            to: 16
            suffix: "px"
            readonly: true
        }

        ReadonlySlider {
            Layout.fillWidth: true
            label: qsTr("Visualiser size")
            value: root.rootItem.mediaVisualiserSize
            from: 40
            to: 150
            suffix: "px"
            readonly: true
        }
    }
}
