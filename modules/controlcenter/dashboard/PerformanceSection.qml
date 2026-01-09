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
        text: qsTr("Performance Resources")
        font.pointSize: Appearance.font.size.normal
    }

    ConnectedButtonGroup {
        rootItem: root.rootItem
        
        options: [
            {
                label: qsTr("Battery"),
                propertyName: "showBattery",
                onToggled: function(checked) {
                    root.rootItem.showBattery = checked;
                    root.rootItem.saveConfig();
                }
            },
            {
                label: qsTr("GPU"),
                propertyName: "showGpu",
                onToggled: function(checked) {
                    root.rootItem.showGpu = checked;
                    root.rootItem.saveConfig();
                }
            },
            {
                label: qsTr("CPU"),
                propertyName: "showCpu",
                onToggled: function(checked) {
                    root.rootItem.showCpu = checked;
                    root.rootItem.saveConfig();
                }
            },
            {
                label: qsTr("Memory"),
                propertyName: "showMemory",
                onToggled: function(checked) {
                    root.rootItem.showMemory = checked;
                    root.rootItem.saveConfig();
                }
            },
            {
                label: qsTr("Storage"),
                propertyName: "showStorage",
                onToggled: function(checked) {
                    root.rootItem.showStorage = checked;
                    root.rootItem.saveConfig();
                }
            }
        ]
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Resource size")
            value: root.rootItem.resourceSize
            from: 100
            to: 400
            suffix: "px"
            validator: IntValidator { bottom: 100; top: 400 }
            formatValueFunction: (val) => Math.round(val).toString()
            parseValueFunction: (text) => parseInt(text)
            
            onValueModified: (newValue) => {
                root.rootItem.resourceSize = Math.round(newValue);
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Progress thickness")
            value: root.rootItem.resourceProgessThickness
            from: 5
            to: 20
            suffix: "px"
            validator: IntValidator { bottom: 5; top: 20 }
            formatValueFunction: (val) => Math.round(val).toString()
            parseValueFunction: (text) => parseInt(text)
            
            onValueModified: (newValue) => {
                root.rootItem.resourceProgessThickness = Math.round(newValue);
                root.rootItem.saveConfig();
            }
        }
    }
}
