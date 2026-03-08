import ".."
import "../components"
import "." as Power
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
    Layout.fillHeight: true
    alignTop: true
    
    Behavior on implicitHeight {
        Anim {}
    }

    StyledText {
        text: qsTr("Charging & Unplugged Behavior")
        font.pointSize: Appearance.font.size.normal
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 0

        // Charging behavior column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Appearance.spacing.normal

            SectionContainer {
                Layout.fillWidth: true
                alignTop: true

                StyledText {
                    text: qsTr("When Plugged In")
                    font.pointSize: Appearance.font.size.normal
                }

                Power.PowerProfileSelector {
                    Layout.fillWidth: true
                    value: Config.general.battery.powerManagement.onCharging.setPowerProfile
                    showRestore: true
                    showUnchanged: true
                    onProfileChanged: newValue => {
                        Config.general.battery.powerManagement.onCharging.setPowerProfile = newValue;
                        Config.save();
                    }
                }

                Power.RefreshRateSelector {
                    Layout.fillWidth: true
                    value: Config.general.battery.powerManagement.onCharging.setRefreshRate
                    showRestore: true
                    showUnchanged: true
                    onRateChanged: newValue => {
                        Config.general.battery.powerManagement.onCharging.setRefreshRate = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Animations")
                    value: Config.general.battery.powerManagement.onCharging.disableAnimations
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.onCharging.disableAnimations = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Blur")
                    value: Config.general.battery.powerManagement.onCharging.disableBlur
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.onCharging.disableBlur = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Rounding")
                    value: Config.general.battery.powerManagement.onCharging.disableRounding
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.onCharging.disableRounding = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Shadows")
                    value: Config.general.battery.powerManagement.onCharging.disableShadows
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.onCharging.disableShadows = newValue;
                        Config.save();
                    }
                }
            }
        }

        // Unplugged behavior column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Appearance.spacing.normal

            SectionContainer {
                Layout.fillWidth: true
                alignTop: true

                StyledText {
                    text: qsTr("When Unplugged")
                    font.pointSize: Appearance.font.size.normal
                }

                Power.PowerProfileSelector {
                    Layout.fillWidth: true
                    value: Config.general.battery.powerManagement.onUnplugged.setPowerProfile
                    showRestore: true
                    showUnchanged: true
                    onProfileChanged: newValue => {
                        Config.general.battery.powerManagement.onUnplugged.setPowerProfile = newValue;
                        Config.save();
                    }
                }

                Power.RefreshRateSelector {
                    Layout.fillWidth: true
                    value: Config.general.battery.powerManagement.onUnplugged.setRefreshRate
                    showRestore: true
                    showUnchanged: true
                    onRateChanged: newValue => {
                        Config.general.battery.powerManagement.onUnplugged.setRefreshRate = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Animations")
                    value: Config.general.battery.powerManagement.onUnplugged.disableAnimations
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.onUnplugged.disableAnimations = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Blur")
                    value: Config.general.battery.powerManagement.onUnplugged.disableBlur
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.onUnplugged.disableBlur = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Rounding")
                    value: Config.general.battery.powerManagement.onUnplugged.disableRounding
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.onUnplugged.disableRounding = newValue;
                        Config.save();
                    }
                }

                TriStateRow {
                    label: qsTr("Shadows")
                    value: Config.general.battery.powerManagement.onUnplugged.disableShadows
                    onTriStateValueChanged: newValue => {
                        Config.general.battery.powerManagement.onUnplugged.disableShadows = newValue;
                        Config.save();
                    }
                }

                SwitchRow {
                    label: qsTr("Evaluate battery thresholds")
                    checked: Config.general.battery.powerManagement.onUnplugged.evaluateThresholds
                    onToggled: checked => {
                        Config.general.battery.powerManagement.onUnplugged.evaluateThresholds = checked;
                        Config.save();
                    }
                }
            }
        }
    }
}
