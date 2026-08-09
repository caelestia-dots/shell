pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    required property bool newLevelPage

    readonly property var batteryLevel: nState.selectedBatteryLevel
    readonly property var lowWarning: nState.lowWarningSelected

    function toggleProperty(propName) {
        setValueProperty(propName, !batteryLevel[propName]);
    }

    function setValueProperty(propName, propValue) {
        let originalConfig = lowWarning ? GlobalConfig.general.battery.lowBatteryWarnLevels : GlobalConfig.general.battery.chargingWarnLevels;
        let configCopy = Array.from(originalConfig);
        let targetItem = configCopy.find(item => (item.level === batteryLevel.level) & (item.title === batteryLevel.title));

        if (targetItem && !newLevelPage) {
            targetItem[propName] = propValue;
            if (lowWarning)
                GlobalConfig.general.battery.lowBatteryWarnLevels = configCopy;
            else
                GlobalConfig.general.battery.chargingWarnLevels = configCopy;

            nState.selectedBatteryLevel = targetItem;
        } else {
            let temporaryLevel = Object.assign({}, batteryLevel);
            temporaryLevel[propName] = propValue;
            nState.selectedBatteryLevel = temporaryLevel;
        }
    }

    function deleteLevel() {
        if (newLevelPage)
            return;
        let originalConfig = lowWarning ? GlobalConfig.general.battery.lowBatteryWarnLevels : GlobalConfig.general.battery.chargingWarnLevels;
        let configCopy = Array.from(originalConfig);
        let filteredConfig = configCopy.filter(item => !(item.level === batteryLevel.level && item.title === batteryLevel.title));

        if (lowWarning)
            GlobalConfig.general.battery.lowBatteryWarnLevels = filteredConfig;
        else
            GlobalConfig.general.battery.chargingWarnLevels = filteredConfig;
    }

    function addLevel(levelToAdd) {
        let originalConfig = lowWarning ? GlobalConfig.general.battery.lowBatteryWarnLevels : GlobalConfig.general.battery.chargingWarnLevels;
        let configCopy = Array.from(originalConfig);

        if (!levelToAdd) {
            return;
        }

        configCopy.push({
            level: levelToAdd.level,
            title: levelToAdd.title,
            message: levelToAdd.message,
            icon: levelToAdd.icon,
            enabled: levelToAdd.enabled,
            critical: levelToAdd.critical
        });

        if (lowWarning)
            GlobalConfig.general.battery.lowBatteryWarnLevels = configCopy;
        else
            GlobalConfig.general.battery.chargingWarnLevels = configCopy;
    }

    title: qsTr("%1 warning").arg(lowWarning ? "Low battery" : "Overcharge battery")
    isSubPage: true

    // So we need the following information
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ColumnLayout {
            Layout.topMargin: Tokens.spacing.medium
            Layout.preferredHeight: implicitHeight
            Layout.preferredWidth: root.cappedWidth
            spacing: Tokens.spacing.large

            // Title
            StyledTextField {
                id: warningTitleField

                property bool isSaved: false

                Layout.fillWidth: true
                placeholderText: "Warning title"
                // supportingText: "First line of text displayed during the battery toast"
                leadingIcon: "label"

                text: root.batteryLevel?.title ?? ""
                enabled: root.batteryLevel?.enabled ?? false

                onAccepted: {
                    root.setValueProperty("title", text);
                    isSaved = true;
                    saveTimerTitle.restart();
                }

                supportingText: isSaved ? "✓ Settings saved successfully!" : "First line of text displayed during the battery toast"

                Timer {
                    id: saveTimerTitle

                    interval: 1500 // Flash for 1.5 seconds
                    onTriggered: warningTitleField.isSaved = false
                }
            }

            // Message
            StyledTextField {
                id: warningMessageField

                property bool isSaved: false

                Layout.fillWidth: true
                placeholderText: "Warning message"
                leadingIcon: "text_fields"

                text: root.batteryLevel?.message ?? ""
                enabled: root.batteryLevel?.enabled ?? false

                onAccepted: {
                    root.setValueProperty("message", text);
                    isSaved = true;
                    saveTimerMessage.restart();
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
            valueLabel: root.batteryLevel?.level + "%"
            value: root.batteryLevel?.level / 100
            enabled: root.batteryLevel?.enabled ?? false
            onMoved: v => {
                root.setValueProperty("level", Math.round(v * 100));
                if (root.batteryLevel?.autopick ?? false) {
                    root.setValueProperty("icon", Icons.getBatteryHorizontalIcon(v, false, root.batteryLevel?.critical ?? false, GlobalConfig.general.battery.framedMaterialIcons));
                }
            }
        }

        StyledTextField {
            id: batteryIconField

            property bool isSaved: false

            Layout.fillWidth: true
            placeholderText: "Warning icon"

            text: root.batteryLevel?.icon ?? ""
            enabled: (root.batteryLevel?.enabled ?? false) && (!root.batteryLevel?.autopick ?? false)

            trailingIcon: text

            onAccepted: {
                root.setValueProperty("icon", text);
                isSaved = true;
                saveTimerIcon.restart();
            }

            supportingText: isSaved ? "✓ Settings saved successfully!" : "Icon for the battery toast. Required to be a valid Material Icon from Google."

            Timer {
                id: saveTimerIcon

                interval: 1500 // Flash for 1.5 seconds
                onTriggered: warningMessageField.isSaved = false
            }
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
                    root.toggleProperty("enabled");
            }
        }
        // Icon auto picked from slider
        ToggleRow {
            verticalPadding: Tokens.padding.large
            text: qsTr("Automatic Toast Icon")
            subtext: qsTr("Let the icon be automatically picked from the slider's value")
            checked: root.batteryLevel?.autopick ?? false
            onToggled: {
                if (root.batteryLevel)
                    root.toggleProperty("autopick");
            }
        }
        // Criticality
        ToggleRow {
            enabled: root.batteryLevel?.enabled ?? false
            verticalPadding: Tokens.padding.large
            last: true
            text: qsTr("Critical")
            subtext: qsTr("Change the battery warning toast from regular to a critical-red toast")
            checked: root.batteryLevel?.critical ?? false
            onToggled: {
                if (root.batteryLevel)
                    root.toggleProperty("critical");
            }
        }

        ButtonRow {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: Math.round(root.newLevelPage ? root.cappedWidth * 0.7 : root.cappedWidth * 0.5)
            spacing: Tokens.spacing.small

            ButtonBase {
                id: deleteBtn

                visible: !root.newLevelPage

                fillWidth: true
                shapeMorph: true
                isRound: true

                inactiveColour: Colours.palette.m3errorContainer
                inactiveOnColour: Colours.palette.m3onErrorContainer

                implicitWidth: deleteBtnLayout.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: deleteBtnLayout.implicitHeight + Tokens.padding.medium * 2

                onClicked: {
                    root.deleteLevel();
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

                visible: root.newLevelPage

                fillWidth: true
                shapeMorph: true
                isRound: true

                inactiveColour: Colours.palette.m3primaryContainer
                inactiveOnColour: Colours.palette.m3onPrimaryContainer

                implicitWidth: addBtnLayout.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: addBtnLayout.implicitHeight + Tokens.padding.medium * 2

                onClicked: {
                    root.addLevel(root.batteryLevel);
                    root.nState.closeSubPage();
                }

                ColumnLayout {
                    id: addBtnLayout

                    anchors.centerIn: parent
                    spacing: 0

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "add"
                        color: addBtn.onColour
                        fontStyle: Tokens.font.icon.medium
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Add")
                        color: addBtn.onColour
                    }
                }
            }
        }
    }
}
