pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components.filedialog
import qs.utils
import qs.modules.nexus.common
import qs.modules.nexus.pages.battery

PageBase {
    id: root

    readonly property FileDialog lowBatSoundPicker: FileDialog {
        title: qsTr("Select a sound file")
        filterLabel: qsTr("Sound files")
        filters: Sounds.validSoundExtensions
        onAccepted: path => {
            GlobalConfig.paths.lowBatNotifSound = path;
            Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "Warning sound replaced", `Low battery warning sound replaced to ${Paths.shortenHome(path)}`]);
        }
    }

    readonly property FileDialog chargingSoundPicker: FileDialog {
        title: qsTr("Select a sound file")
        filterLabel: qsTr("Sound files")
        filters: Sounds.validSoundExtensions
        onAccepted: path => {
            GlobalConfig.paths.highBatNotifSound = path;
            Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "Warning sound replaced", `Charging warning sound replaced to ${Paths.shortenHome(path)}`]);
        }
    }

    function toggleLowWarns() {
        GlobalConfig.general.battery.enableLowBatteryWarning = !GlobalConfig.general.battery.enableLowBatteryWarning;
    }

    function toggleHighWarns() {
        GlobalConfig.general.battery.enableHighBatteryWarning = !GlobalConfig.general.battery.enableHighBatteryWarning;
    }

    function toggleFrame(iconName, wantFramed) {
        if (iconName.includes("alert"))
            return iconName;
        let isFramed = iconName.includes("android_frame_");
        if (wantFramed && !isFramed)
            return iconName.replace("android_", "android_frame_");
        if (!wantFramed && isFramed)
            return iconName.replace("android_frame_", "android_");
        return iconName; // already in the desired state
    }

    function changeToastIconVariant() {
        let framed = GlobalConfig.general.battery.framedMaterialIcons;
        let lowWarnConfig = Array.from(GlobalConfig.general.battery.lowBatteryWarnLevels);
        let highWarnConfig = Array.from(GlobalConfig.general.battery.chargingWarnLevels);
        const changeIcon = level => {
            level.icon = toggleFrame(level.icon, framed);
        };
        lowWarnConfig.forEach(changeIcon);
        highWarnConfig.forEach(changeIcon);
    }

    title: qsTr("Power")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            id: lowWarnToggle

            Layout.topMargin: Tokens.spacing.large
            first: true
            text: qsTr("Low Battery Warnings")
            font: Tokens.font.body.medium
            horizontalPadding: Tokens.padding.largeIncreased
            checked: GlobalConfig.general.battery.enableLowBatteryWarning
            onToggled: root.toggleLowWarns()
        }

        BatteryWarningList {
            isToggled: lowWarnToggle.checked
            isLowWarning: true
            nState: root.nState
        }

        RowButton {
            last: true
            icon: "add"
            text: qsTr("Add new warning")
            disabled: !lowWarnToggle.checked
            onClicked: {
                root.nState.lowWarningSelected = true;
                root.nState.selectedBatteryLevel = {
                    level: 0,
                    title: "",
                    message: "",
                    icon: "",
                    enabled: true,
                    critical: false,
                    autopick: true
                };
                root.nState.openSubPage(2);
            }
        }

        ToggleRow {
            id: highWarnToggle

            Layout.topMargin: Tokens.spacing.large
            first: true
            text: qsTr("Overcharge Battery Warnings")
            font: Tokens.font.body.medium
            horizontalPadding: Tokens.padding.largeIncreased
            checked: GlobalConfig.general.battery.enableHighBatteryWarning
            onToggled: root.toggleHighWarns()
        }

        BatteryWarningList {
            isToggled: highWarnToggle.checked
            isLowWarning: false
            nState: root.nState
        }

        RowButton {
            last: true
            icon: "add"
            text: qsTr("Add new warning")
            disabled: !highWarnToggle.checked
            onClicked: {
                root.nState.lowWarningSelected = false;
                root.nState.selectedBatteryLevel = {
                    level: 0,
                    title: "",
                    message: "",
                    icon: "",
                    enabled: true,
                    critical: false,
                    autopick: true
                };
                root.nState.openSubPage(2);
            }
        }

        SectionHeader {
            text: qsTr("Warning sound options")
        }

        ToggleRow {
            first: true
            text: qsTr("Battery Toast Sound")
            subtext: qsTr("Enables sound effect for battery toasts (charge and discharge)")
            checked: GlobalConfig.general.battery.toastSound ?? false
            onToggled: {
                GlobalConfig.general.battery.toastSound = !GlobalConfig.general.battery.toastSound;
            }
        }

        FileSelectRow {
            disabled: !GlobalConfig.general.battery.toastSound
            filePicker: root.lowBatSoundPicker
            label: "Low battery sound"
            icon: "music_note"
            value: GlobalConfig.paths.lowBatNotifSound
            onResetRequested: {
                GlobalConfig.paths.resetOption("lowBatNotifSound");
            }
        }

        FileSelectRow {
            disabled: !GlobalConfig.general.battery.toastSound
            last: true
            filePicker: root.chargingSoundPicker
            label: "Charging battery sound"
            icon: "music_note"
            value: GlobalConfig.paths.highBatNotifSound
            onResetRequested: {
                GlobalConfig.paths.resetOption("highBatNotifSound");
            }
        }

        SectionHeader {
            text: qsTr("Other power options")
        }

        SliderRow {
            first: true
            icon: "battery_android_alert"

            label: qsTr("Critical Battery Level")
            valueLabel: GlobalConfig.general.battery.criticalLevel + "%"
            value: GlobalConfig.general.battery.criticalLevel / 100

            onMoved: v => {
                GlobalConfig.general.battery.criticalLevel = Math.round(v * 100);
            }
        }

        ToggleRow {
            verticalPadding: Tokens.padding.large

            text: qsTr("Framed Toast Icon")
            subtext: qsTr("Enables the framed variant of Material battery icons")
            checked: GlobalConfig.general.battery.framedMaterialIcons ?? false
            onToggled: {
                GlobalConfig.general.battery.framedMaterialIcons = !GlobalConfig.general.battery.framedMaterialIcons;
                root.changeToastIconVariant();
            }
        }
    }
}
