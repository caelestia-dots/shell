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
        text: qsTr("General Settings")
        font.pointSize: Appearance.font.size.normal
    }

    SwitchRow {
        label: qsTr("Enabled")
        checked: root.rootItem.enabled
        onToggled: checked => {
            root.rootItem.enabled = checked;
            root.rootItem.saveConfig();
        }
    }

    SwitchRow {
        label: qsTr("Show on hover")
        checked: root.rootItem.showOnHover
        onToggled: checked => {
            root.rootItem.showOnHover = checked;
            root.rootItem.saveConfig();
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Update interval")
            value: root.rootItem.updateInterval
            from: 100
            to: 10000
            stepSize: 100
            suffix: "ms"
            validator: IntValidator { bottom: 100; top: 10000 }
            formatValueFunction: (val) => Math.round(val).toString()
            parseValueFunction: (text) => parseInt(text)
            
            onValueModified: (newValue) => {
                root.rootItem.updateInterval = Math.round(newValue);
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Drag threshold")
            value: root.rootItem.dragThreshold
            from: 0
            to: 100
            suffix: "px"
            validator: IntValidator { bottom: 0; top: 100 }
            formatValueFunction: (val) => Math.round(val).toString()
            parseValueFunction: (text) => parseInt(text)
            
            onValueModified: (newValue) => {
                root.rootItem.dragThreshold = Math.round(newValue);
                root.rootItem.saveConfig();
            }
        }
    }
}
