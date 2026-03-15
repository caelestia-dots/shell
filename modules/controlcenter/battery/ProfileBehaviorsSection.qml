import ".."
import "../components"
import "." as Power
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

SectionContainer {
    id: root

    required property var rootItem

    Layout.fillWidth: true
    alignTop: true

    property var availableRefreshRates: {
        const rates = ["" /* unchanged */];
        const monitors = Hypr.monitors.values || Object.values(Hypr.monitors);
        const uniqueRates = new Set();
        
        for (const monitor of monitors) {
            const data = monitor.lastIpcObject;
            if (data && data.availableModes) {
                for (const mode of data.availableModes) {
                    const match = mode.match(/@(\d+(?:\.\d+)?)Hz/);
                    if (match) {
                        const rate = Math.round(parseFloat(match[1]));
                        uniqueRates.add(rate);
                    }
                }
            }
        }
        
        const sortedRates = Array.from(uniqueRates).sort((a, b) => a - b);
        for (const rate of sortedRates) {
            rates.push(rate.toString());
        }
        rates.push("auto");
        return rates;
    }

    StyledText {
        text: qsTr("Power Profile Behaviors")
        font.pointSize: Appearance.font.size.normal
    }

    StyledText {
        text: qsTr("Define what Hyprland settings to apply when each power profile is active")
        font.pointSize: Appearance.font.size.smaller
        opacity: 0.7
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 0

        // Power Saver Profile Column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Appearance.spacing.normal

            SectionContainer {
                Layout.fillWidth: true
                alignTop: true

                StyledText {
                    text: qsTr("Power Saver")
                    font.pointSize: Appearance.font.size.normal
                }

                Power.RefreshRateSelector {
                    Layout.fillWidth: true
                    value: Config.general.battery.powerManagement.profileBehaviors.powerSaver.setRefreshRate
                    showRestore: true
                    showUnchanged: true
                    onRateChanged: newValue => {
                        Config.general.battery.powerManagement.profileBehaviors.powerSaver.setRefreshRate = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Animations")
                    value: Config.general.battery.powerManagement.profileBehaviors.powerSaver.disableAnimations
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.profileBehaviors.powerSaver.disableAnimations = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Blur")
                    value: Config.general.battery.powerManagement.profileBehaviors.powerSaver.disableBlur
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.profileBehaviors.powerSaver.disableBlur = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Rounding")
                    value: Config.general.battery.powerManagement.profileBehaviors.powerSaver.disableRounding
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.profileBehaviors.powerSaver.disableRounding = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Shadows")
                    value: Config.general.battery.powerManagement.profileBehaviors.powerSaver.disableShadows
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.profileBehaviors.powerSaver.disableShadows = newValue;
                        Config.save();
                    }
                }
            }
        }

        // Balanced Profile Column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Appearance.spacing.normal

            SectionContainer {
                Layout.fillWidth: true
                alignTop: true

                StyledText {
                    text: qsTr("Balanced")
                    font.pointSize: Appearance.font.size.normal
                }

                Power.RefreshRateSelector {
                    Layout.fillWidth: true
                    value: Config.general.battery.powerManagement.profileBehaviors.balanced.setRefreshRate
                    showRestore: true
                    showUnchanged: true
                    onRateChanged: newValue => {
                        Config.general.battery.powerManagement.profileBehaviors.balanced.setRefreshRate = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Animations")
                    value: Config.general.battery.powerManagement.profileBehaviors.balanced.disableAnimations
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.profileBehaviors.balanced.disableAnimations = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Blur")
                    value: Config.general.battery.powerManagement.profileBehaviors.balanced.disableBlur
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.profileBehaviors.balanced.disableBlur = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Rounding")
                    value: Config.general.battery.powerManagement.profileBehaviors.balanced.disableRounding
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.profileBehaviors.balanced.disableRounding = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Shadows")
                    value: Config.general.battery.powerManagement.profileBehaviors.balanced.disableShadows
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.profileBehaviors.balanced.disableShadows = newValue;
                        Config.save();
                    }
                }
            }
        }

        // Performance Profile Column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Appearance.spacing.normal

            SectionContainer {
                Layout.fillWidth: true
                alignTop: true

                StyledText {
                    text: qsTr("Performance")
                    font.pointSize: Appearance.font.size.normal
                }

                Power.RefreshRateSelector {
                    Layout.fillWidth: true
                    value: Config.general.battery.powerManagement.profileBehaviors.performance.setRefreshRate
                    showRestore: true
                    showUnchanged: true
                    onRateChanged: newValue => {
                        Config.general.battery.powerManagement.profileBehaviors.performance.setRefreshRate = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Animations")
                    value: Config.general.battery.powerManagement.profileBehaviors.performance.disableAnimations
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.profileBehaviors.performance.disableAnimations = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Blur")
                    value: Config.general.battery.powerManagement.profileBehaviors.performance.disableBlur
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.profileBehaviors.performance.disableBlur = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Rounding")
                    value: Config.general.battery.powerManagement.profileBehaviors.performance.disableRounding
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.profileBehaviors.performance.disableRounding = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Shadows")
                    value: Config.general.battery.powerManagement.profileBehaviors.performance.disableShadows
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.profileBehaviors.performance.disableShadows = newValue;
                        Config.save();
                    }
                }
            }
        }
    }
}
