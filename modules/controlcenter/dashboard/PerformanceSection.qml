import ".."
import "../components"
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.components
import qs.components.controls
import qs.config
import qs.services

SectionContainer {
    id: root

    required property var rootItem
    // GPU toggle is hidden when gpuType is "NONE" (no GPU data available)
    readonly property bool gpuAvailable: SystemUsage.gpuType !== "NONE"
    // Battery toggle is hidden when no laptop battery is present
    readonly property bool batteryAvailable: UPower.displayDevice.isLaptopBattery

    Layout.fillWidth: true
    alignTop: true

    StyledText {
        text: qsTr("Performance Resources")
        font.pointSize: Appearance.font.size.normal
    }

    ConnectedButtonGroup {
        rootItem: root.rootItem
        options: {
            let opts = [];
            if (root.batteryAvailable)
                opts.push({
                    "label": qsTr("Battery"),
                    "propertyName": "showBattery",
                    "onToggled": function(checked) {
                        root.rootItem.showBattery = checked;
                        root.rootItem.saveConfig();
                    }
                });

            if (root.gpuAvailable)
                opts.push({
                "label": qsTr("GPU"),
                "propertyName": "showGpu",
                "onToggled": function(checked) {
                    root.rootItem.showGpu = checked;
                    root.rootItem.saveConfig();
                }
            });

            opts.push({
                "label": qsTr("CPU"),
                "propertyName": "showCpu",
                "onToggled": function(checked) {
                    root.rootItem.showCpu = checked;
                    root.rootItem.saveConfig();
                }
            }, {
                "label": qsTr("Memory"),
                "propertyName": "showMemory",
                "onToggled": function(checked) {
                    root.rootItem.showMemory = checked;
                    root.rootItem.saveConfig();
                }
            }, {
                "label": qsTr("Storage"),
                "propertyName": "showStorage",
                "onToggled": function(checked) {
                    root.rootItem.showStorage = checked;
                    root.rootItem.saveConfig();
                }
            }, {
                "label": qsTr("Network"),
                "propertyName": "showNetwork",
                "onToggled": function(checked) {
                    root.rootItem.showNetwork = checked;
                    root.rootItem.saveConfig();
                }
            });
            return opts;
        }
    }

    SliderInput {
        Layout.fillWidth: true
        label: qsTr("Update interval")
        value: root.rootItem.updateInterval
        from: 500
        to: 10000
        stepSize: 500
        suffix: "ms"
        decimals: 0
        onValueModified: (newValue) => {
            root.rootItem.updateInterval = newValue;
            root.rootItem.saveConfig();
        }

        validator: IntValidator {
            bottom: 500
            top: 10000
        }

    }

}
