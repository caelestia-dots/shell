pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common
import qs.modules.nexus.pages.battery

PageBase {
    id: root

    title: qsTr("Power")

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
            onToggled: toggleLowWarns()
        }

        BatteryWarningList {
            isToggled: lowWarnToggle.checked
            isLowWarning: true
            nState: root.nState
        }

        ConnectedRect {
            Layout.fillWidth: true
            implicitHeight: addLowWarnLayout.implicitHeight + addLowWarnLayout.anchors.margins * 2
            last: true

            StateLayer {
                // This is for the add new level.
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

            RowLayout {
                id: addLowWarnLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium
                opacity: lowWarnToggle.checked ? 1 : 0.5

                Behavior on opacity {
                    Anim {}
                }

                MaterialIcon {
                    text: "add"
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Add new warning")
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
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
            onToggled: toggleHighWarns()
        }

        BatteryWarningList {
            isToggled: highWarnToggle.checked
            isLowWarning: false
            nState: root.nState
        }

        ConnectedRect {
            Layout.fillWidth: true
            implicitHeight: addHighWarnLayout.implicitHeight + addHighWarnLayout.anchors.margins * 2
            last: true

            StateLayer {
                // This is for the add new level.
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

            RowLayout {
                id: addHighWarnLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium
                opacity: highWarnToggle.checked ? 1 : 0.5

                Behavior on opacity {
                    Anim {}
                }

                MaterialIcon {
                    text: "add"
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Add new warning")
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }
        }

        // Framed Icons
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
            last: true
            text: qsTr("Framed Toast Icon")
            subtext: qsTr("Enables the framed variant of Material battery icons")
            checked: GlobalConfig.general.battery.framedMaterialIcons ?? false
            onToggled: {
                GlobalConfig.general.battery.framedMaterialIcons = !GlobalConfig.general.battery.framedMaterialIcons;
                changeToastIconVariant();
            }
        }
    }
}
