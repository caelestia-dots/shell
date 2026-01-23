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
    }
}
