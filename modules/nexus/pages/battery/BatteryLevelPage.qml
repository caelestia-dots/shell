pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import qs.utils

PageBase {
    id: root

    required property bool newLevelPage

    readonly property var batteryLevel: nState.selectedBatteryLevel
    readonly property var lowWarning: nState.lowWarningSelected

    title: qsTr("%1 warning").arg(lowWarning ? "Low battery" : "Overcharge battery")
    isSubPage: true

    function toggleProperty(propName) {
        setValueProperty(propName, !batteryLevel[propName]);
    }

    function setValueProperty(propName, propValue) {
        let originalConfig = lowWarning 
            ? GlobalConfig.general.battery.lowBatteryWarnLevels 
            : GlobalConfig.general.battery.chargingBatteryWarnLevels;
        let configCopy = Array.from(originalConfig);
        let targetItem = configCopy.find(item => (item.level === batteryLevel.level) & (item.title === batteryLevel.title));

        if (targetItem) {
            targetItem[propName] = propValue;
            if (lowWarning)
                GlobalConfig.general.battery.lowBatteryWarnLevels = configCopy;
            else
                GlobalConfig.general.battery.chargingBatteryWarnLevels = configCopy;

            nState.selectedBatteryLevel = targetItem;
        }
    }

    function deleteLevel() {
        let originalConfig = lowWarning 
            ? GlobalConfig.general.battery.lowBatteryWarnLevels 
            : GlobalConfig.general.battery.chargingBatteryWarnLevels;
        let configCopy = Array.from(originalConfig);
        let filteredConfig = configCopy.filter(item => 
            !(item.level === batteryLevel.level && item.title === batteryLevel.title)
        );

        if (lowWarning)
            GlobalConfig.general.battery.lowBatteryWarnLevels = filteredConfig;
        else
            GlobalConfig.general.battery.chargingBatteryWarnLevels = filteredConfig;
    }

    // So we need the following information
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ColumnLayout{
            Layout.topMargin: Tokens.spacing.medium
            Layout.preferredHeight: implicitHeight
            width: root.cappedWidth
            spacing: Tokens.spacing.large

            // Title
            M3TextField {
                id: warningTitleField
                Layout.fillWidth: true 
                label: "Warning title"
                // supportingText: "First line of text displayed during the battery toast"
                leadingIcon: "label"

                text: root.batteryLevel?.title
                enabled: root.batteryLevel?.enabled

                property bool isSaved: false 
                onAccepted: {
                    setValueProperty("title", text);
                    isSaved = true;
                    saveTimerTitle.restart()
                }

                supportingText: isSaved ? "✓ Settings saved successfully!" : "First line of text displayed during the battery toast"

                Timer {
                    id: saveTimerTitle
                    interval: 1500 // Flash for 1.5 seconds
                    onTriggered: warningTitleField.isSaved = false
                }
            }

            // Message
            M3TextField {
                id: warningMessageField
                Layout.fillWidth: true 
                label: "Warning message"
                leadingIcon: "text_fields"

                text: root.batteryLevel?.message
                enabled: root.batteryLevel?.enabled

                property bool isSaved: false 
                onAccepted: {
                    setValueProperty("message", text);
                    isSaved = true;
                    saveTimerMessage.restart()
                }

                supportingText: isSaved ? "✓ Settings saved successfully!" : "Second line of text displayed during the battery toast. Can be HTML formatted"

                Timer {
                    id: saveTimerMessage
                    interval: 1500 // Flash for 1.5 seconds
                    onTriggered: warningMessageField.isSaved = false
                }
            }
        }

        // Battery level
        SliderRow {
            first: true
            last: true
            icon: Icons.getBatteryIcon(value, false)
            label: qsTr("Battery Percentage")
            valueLabel: root.batteryLevel.level + "%"
            value: root.batteryLevel.level / 100
            enabled: root.batteryLevel.enabled
            onMoved: v => setValueProperty("level", Math.round(v * 100));
        }

        SectionHeader {
            text: qsTr("Toggleable options")
        }

        // Enabled?
        ToggleRow {
            verticalPadding: Tokens.padding.large
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Enable this battery warning toast")
            checked: root.batteryLevel?.enabled ?? false
            onToggled: {
                if (root.batteryLevel)
                    toggleProperty("enabled");
            }
        }
        // Criticality
        ToggleRow {
            verticalPadding: Tokens.padding.large
            last: true
            text: qsTr("Critical")
            subtext: qsTr("Change the battery warning toast from regular to a critical-red toast")
            checked: root.batteryLevel?.critical ?? false
            onToggled: {
                if (root.batteryLevel)
                    toggleProperty("critical");
            }
        }

        ButtonRow {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: Math.round(root.cappedWidth * newLevelPage ? 0.7 : 0.5)
            spacing: Tokens.spacing.small

            ButtonBase {
                id: deleteBtn

                fillWidth: true
                shapeMorph: true
                isRound: true

                inactiveColour: Colours.palette.m3errorContainer
                inactiveOnColour: Colours.palette.m3onErrorContainer

                implicitWidth: deleteBtnLayout.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: deleteBtnLayout.implicitHeight + Tokens.padding.medium * 2

                onClicked: {
                    root.nState.closeSubPage();
                }

                ColumnLayout {
                    id: deleteBtnLayout

                    anchors.centerIn: parent
                    spacing: 0

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "delete"
                        color: deleteBtn.onColour
                        fontStyle: Tokens.font.icon.medium
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Delete")
                        color: deleteBtn.onColour
                    }
                }
            }

            ButtonBase {
                id: addBtn
                visible: newLevelPage

                fillWidth: true
                shapeMorph: true
                isRound: true

                inactiveColour: Colours.palette.m3primaryContainer
                inactiveOnColour: Colours.palette.m3onPrimaryContainer

                implicitWidth: addBtnLayout.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: addBtnLayout.implicitHeight + Tokens.padding.medium * 2

                onClicked: {
                    root.nState.closeSubPage();
                }

                ColumnLayout {
                    id: addBtnLayout

                    anchors.centerIn: parent
                    spacing: 0

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "delete"
                        color: addBtn.onColour
                        fontStyle: Tokens.font.icon.medium
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Delete")
                        color: addBtn.onColour
                    }
                }
            }
        }
    }
}
