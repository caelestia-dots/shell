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

    CollapsibleSection {
        title: qsTr("Font Sizes")
        showBackground: true

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Usage text")
            value: root.rootItem.usageTextSize
            from: 8
            to: 20
            stepSize: 1
            suffix: "pt"
            decimals: 0
            onValueModified: (newValue) => {
                root.rootItem.usageTextSize = newValue;
                root.rootItem.saveConfig();
            }

            validator: IntValidator {
                bottom: 8
                top: 20
            }

        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Value label")
            value: root.rootItem.valueLabelSize
            from: 8
            to: 16
            stepSize: 1
            suffix: "pt"
            decimals: 0
            onValueModified: (newValue) => {
                root.rootItem.valueLabelSize = newValue;
                root.rootItem.saveConfig();
            }

            validator: IntValidator {
                bottom: 8
                top: 16
            }

        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Percentage text")
            value: root.rootItem.percentageTextSize
            from: 16
            to: 48
            stepSize: 1
            suffix: "pt"
            decimals: 0
            onValueModified: (newValue) => {
                root.rootItem.percentageTextSize = newValue;
                root.rootItem.saveConfig();
            }

            validator: IntValidator {
                bottom: 16
                top: 48
            }

        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Normal text")
            value: root.rootItem.normalTextSize
            from: 10
            to: 20
            stepSize: 1
            suffix: "pt"
            decimals: 0
            onValueModified: (newValue) => {
                root.rootItem.normalTextSize = newValue;
                root.rootItem.saveConfig();
            }

            validator: IntValidator {
                bottom: 10
                top: 20
            }

        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Large icon")
            value: root.rootItem.largeIconSize
            from: 14
            to: 32
            stepSize: 1
            suffix: "pt"
            decimals: 0
            onValueModified: (newValue) => {
                root.rootItem.largeIconSize = newValue;
                root.rootItem.saveConfig();
            }

            validator: IntValidator {
                bottom: 14
                top: 32
            }

        }

    }

    CollapsibleSection {
        title: qsTr("Temperature Bar")
        showBackground: true

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Bar height")
            value: root.rootItem.tempBarHeight
            from: 2
            to: 16
            stepSize: 1
            suffix: "px"
            decimals: 0
            onValueModified: (newValue) => {
                root.rootItem.tempBarHeight = newValue;
                root.rootItem.saveConfig();
            }

            validator: IntValidator {
                bottom: 2
                top: 16
            }

        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Bar width multiplier")
            value: root.rootItem.tempBarWidthMult
            from: 0.2
            to: 1
            stepSize: 0.05
            suffix: "x"
            decimals: 2
            onValueModified: (newValue) => {
                root.rootItem.tempBarWidthMult = newValue;
                root.rootItem.saveConfig();
            }

            validator: DoubleValidator {
                bottom: 0.2
                top: 1
                decimals: 2
            }

        }

    }

    CollapsibleSection {
        title: qsTr("Gauge Styling")
        showBackground: true

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Arc line width")
            value: root.rootItem.gaugeLineWidth
            from: 4
            to: 20
            stepSize: 1
            suffix: "px"
            decimals: 0
            onValueModified: (newValue) => {
                root.rootItem.gaugeLineWidth = newValue;
                root.rootItem.saveConfig();
            }

            validator: IntValidator {
                bottom: 4
                top: 20
            }

        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Arc radius offset")
            value: root.rootItem.gaugeRadiusOffset
            from: 4
            to: 24
            stepSize: 1
            suffix: "px"
            decimals: 0
            onValueModified: (newValue) => {
                root.rootItem.gaugeRadiusOffset = newValue;
                root.rootItem.saveConfig();
            }

            validator: IntValidator {
                bottom: 4
                top: 24
            }

        }

    }

    CollapsibleSection {
        title: qsTr("Spacing Adjustments")
        showBackground: true

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Main value spacing")
            value: root.rootItem.mainValueSpacing
            from: -16
            to: 8
            stepSize: 1
            suffix: "px"
            decimals: 0
            onValueModified: (newValue) => {
                root.rootItem.mainValueSpacing = newValue;
                root.rootItem.saveConfig();
            }

            validator: IntValidator {
                bottom: -16
                top: 8
            }

        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Percent value spacing")
            value: root.rootItem.percentValueSpacing
            from: -16
            to: 8
            stepSize: 1
            suffix: "px"
            decimals: 0
            onValueModified: (newValue) => {
                root.rootItem.percentValueSpacing = newValue;
                root.rootItem.saveConfig();
            }

            validator: IntValidator {
                bottom: -16
                top: 8
            }

        }

    }

}
