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

        StyledText {
            text: qsTr("Font Sizes")
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Usage text")
            value: root.rootItem.usageTextSize
            from: 8
            to: 20
            stepSize: 1
            suffix: "pt"
            decimals: 0
            validator: IntValidator { bottom: 8; top: 20 }
            onValueModified: (newValue) => {
                root.rootItem.usageTextSize = newValue;
                root.rootItem.saveConfig();
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
            validator: IntValidator { bottom: 8; top: 16 }
            onValueModified: (newValue) => {
                root.rootItem.valueLabelSize = newValue;
                root.rootItem.saveConfig();
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
            validator: IntValidator { bottom: 16; top: 48 }
            onValueModified: (newValue) => {
                root.rootItem.percentageTextSize = newValue;
                root.rootItem.saveConfig();
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
            validator: IntValidator { bottom: 10; top: 20 }
            onValueModified: (newValue) => {
                root.rootItem.normalTextSize = newValue;
                root.rootItem.saveConfig();
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
            validator: IntValidator { bottom: 14; top: 32 }
            onValueModified: (newValue) => {
                root.rootItem.largeIconSize = newValue;
                root.rootItem.saveConfig();
            }
        }

        StyledText {
            text: qsTr("Temperature Bar")
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Bar height")
            value: root.rootItem.tempBarHeight
            from: 2
            to: 16
            stepSize: 1
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: 2; top: 16 }
            onValueModified: (newValue) => {
                root.rootItem.tempBarHeight = newValue;
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Bar width multiplier")
            value: root.rootItem.tempBarWidthMult
            from: 0.2
            to: 1.0
            stepSize: 0.05
            suffix: "×"
            decimals: 2
            validator: DoubleValidator { bottom: 0.2; top: 1.0; decimals: 2 }
            onValueModified: (newValue) => {
                root.rootItem.tempBarWidthMult = newValue;
                root.rootItem.saveConfig();
            }
        }

        StyledText {
            text: qsTr("Gauge Styling")
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Arc line width")
            value: root.rootItem.gaugeLineWidth
            from: 4
            to: 20
            stepSize: 1
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: 4; top: 20 }
            onValueModified: (newValue) => {
                root.rootItem.gaugeLineWidth = newValue;
                root.rootItem.saveConfig();
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
            validator: IntValidator { bottom: 4; top: 24 }
            onValueModified: (newValue) => {
                root.rootItem.gaugeRadiusOffset = newValue;
                root.rootItem.saveConfig();
            }
        }

        StyledText {
            text: qsTr("Disk Indicator")
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Indicator width")
            value: root.rootItem.diskIndicatorWidth
            from: 2
            to: 10
            stepSize: 1
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: 2; top: 10 }
            onValueModified: (newValue) => {
                root.rootItem.diskIndicatorWidth = newValue;
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Indicator radius")
            value: root.rootItem.diskIndicatorRadius
            from: 0
            to: 6
            stepSize: 1
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: 0; top: 6 }
            onValueModified: (newValue) => {
                root.rootItem.diskIndicatorRadius = newValue;
                root.rootItem.saveConfig();
            }
        }

        StyledText {
            text: qsTr("Card Margins & Padding")
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Hero card top margin")
            value: root.rootItem.heroCardTopMargin
            from: 0
            to: 32
            stepSize: 2
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: 0; top: 32 }
            onValueModified: (newValue) => {
                root.rootItem.heroCardTopMargin = newValue;
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Hero card bottom margin")
            value: root.rootItem.heroCardBottomMargin
            from: 0
            to: 32
            stepSize: 2
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: 0; top: 32 }
            onValueModified: (newValue) => {
                root.rootItem.heroCardBottomMargin = newValue;
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Hero card left margin")
            value: root.rootItem.heroCardLeftMargin
            from: 0
            to: 48
            stepSize: 2
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: 0; top: 48 }
            onValueModified: (newValue) => {
                root.rootItem.heroCardLeftMargin = newValue;
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Hero card right margin")
            value: root.rootItem.heroCardRightMargin
            from: 0
            to: 48
            stepSize: 2
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: 0; top: 48 }
            onValueModified: (newValue) => {
                root.rootItem.heroCardRightMargin = newValue;
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Hero value right margin")
            value: root.rootItem.heroCardRightValueMargin
            from: 0
            to: 64
            stepSize: 2
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: 0; top: 64 }
            onValueModified: (newValue) => {
                root.rootItem.heroCardRightValueMargin = newValue;
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Battery tank margin")
            value: root.rootItem.batteryTankMargin
            from: 0
            to: 48
            stepSize: 2
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: 0; top: 48 }
            onValueModified: (newValue) => {
                root.rootItem.batteryTankMargin = newValue;
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Gauge card margin")
            value: root.rootItem.gaugeCardMargin
            from: 0
            to: 48
            stepSize: 2
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: 0; top: 48 }
            onValueModified: (newValue) => {
                root.rootItem.gaugeCardMargin = newValue;
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Storage card margin")
            value: root.rootItem.storageCardMargin
            from: 0
            to: 48
            stepSize: 2
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: 0; top: 48 }
            onValueModified: (newValue) => {
                root.rootItem.storageCardMargin = newValue;
                root.rootItem.saveConfig();
            }
        }

        StyledText {
            text: qsTr("Spacing Adjustments")
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Main value spacing")
            value: root.rootItem.mainValueSpacing
            from: -16
            to: 8
            stepSize: 1
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: -16; top: 8 }
            onValueModified: (newValue) => {
                root.rootItem.mainValueSpacing = newValue;
                root.rootItem.saveConfig();
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
            validator: IntValidator { bottom: -16; top: 8 }
            onValueModified: (newValue) => {
                root.rootItem.percentValueSpacing = newValue;
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Disk row top margin")
            value: root.rootItem.diskRowTopMargin
            from: 0
            to: 10
            stepSize: 1
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: 0; top: 10 }
            onValueModified: (newValue) => {
                root.rootItem.diskRowTopMargin = newValue;
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Disk row bottom margin")
            value: root.rootItem.diskRowBottomMargin
            from: 0
            to: 10
            stepSize: 1
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: 0; top: 10 }
            onValueModified: (newValue) => {
                root.rootItem.diskRowBottomMargin = newValue;
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Disk progress top margin")
            value: root.rootItem.diskRowProgressTopMargin
            from: 0
            to: 10
            stepSize: 1
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: 0; top: 10 }
            onValueModified: (newValue) => {
                root.rootItem.diskRowProgressTopMargin = newValue;
                root.rootItem.saveConfig();
            }
        }

        SliderInput {
            Layout.fillWidth: true
            label: qsTr("Disk progress bottom margin")
            value: root.rootItem.diskRowProgressBottomMargin
            from: 0
            to: 10
            stepSize: 1
            suffix: "px"
            decimals: 0
            validator: IntValidator { bottom: 0; top: 10 }
            onValueModified: (newValue) => {
                root.rootItem.diskRowProgressBottomMargin = newValue;
                root.rootItem.saveConfig();
            }
        }
    }
}
