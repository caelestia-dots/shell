pragma ComponentBehavior: Bound

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

    required property int thresholdIndex
    required property var thresholdData
    signal removeRequested()
    signal thresholdChanged(var newData)

    Layout.fillWidth: true
    alignTop: true

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            text: qsTr("Battery Level: ") + thresholdData.level + "%"
            font.pointSize: Appearance.font.size.normal
            font.weight: 500
            Layout.fillWidth: true
        }

        IconButton {
            icon: "delete"
            onClicked: root.removeRequested()
        }
    }

    // Battery level slider
    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        StyledText {
            text: qsTr("Trigger at battery level")
            font.pointSize: Appearance.font.size.smaller
        }

        RowLayout {
            spacing: Appearance.spacing.normal

            StyledSlider {
                Layout.fillWidth: true
                from: 5
                to: 95
                stepSize: 5
                value: thresholdData.level
                onMoved: {
                    const newData = Object.assign({}, thresholdData);
                    newData.level = Math.round(value);
                    root.thresholdChanged(newData);
                }
            }

            StyledText {
                text: Math.round(thresholdData.level) + "%"
                font.pointSize: Appearance.font.size.normal
                Layout.preferredWidth: 40
            }
        }
    }

    // Power profile selector
    SectionContainer {
        contentSpacing: Appearance.spacing.smaller

        StyledText {
            text: qsTr("Power profile")
            font.pointSize: Appearance.font.size.smaller
        }

        Flow {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            Repeater {
                model: [
                    { value: null, label: qsTr("No change") },
                    { value: "power-saver", label: qsTr("Power Saver") },
                    { value: "balanced", label: qsTr("Balanced") },
                    { value: "performance", label: qsTr("Performance") }
                ]

                delegate: ToggleButton {
                    required property var modelData

                    text: modelData.label
                    checked: thresholdData.setPowerProfile === modelData.value
                    onToggled: {
                        const newData = Object.assign({}, thresholdData);
                        newData.setPowerProfile = modelData.value;
                        root.thresholdChanged(newData);
                    }
                }
            }
        }
    }

    // Effects toggles
    TriStateRow {
        label: qsTr("Animations")
        value: thresholdData.disableAnimations
        onTriStateValueChanged: newValue => {
            const newData = Object.assign({}, thresholdData);
            newData.disableAnimations = newValue;
            root.thresholdChanged(newData);
        }
    }

    TriStateRow {
        label: qsTr("Blur")
        value: thresholdData.disableBlur
        onTriStateValueChanged: newValue => {
            const newData = Object.assign({}, thresholdData);
            newData.disableBlur = newValue;
            root.thresholdChanged(newData);
        }
    }

    TriStateRow {
        label: qsTr("Rounding")
        value: thresholdData.disableRounding
        onTriStateValueChanged: newValue => {
            const newData = Object.assign({}, thresholdData);
            newData.disableRounding = newValue;
            root.thresholdChanged(newData);
        }
    }

    TriStateRow {
        label: qsTr("Shadows")
        value: thresholdData.disableShadows
        onTriStateValueChanged: newValue => {
            const newData = Object.assign({}, thresholdData);
            newData.disableShadows = newValue;
            root.thresholdChanged(newData);
        }
    }
}
