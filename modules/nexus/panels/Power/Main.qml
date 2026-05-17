pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.components.power
import qs.modules.nexus.components.common

Item {
    id: root

    property int activeTabIndex: 0

    readonly property bool hasBattery: UPower.displayDevice?.isLaptopBattery ?? false

    readonly property var pm: GlobalConfig.general.battery?.powerManagement
    readonly property bool pmEnabled: pm && pm.enabled === true
    readonly property var onCharging: (pm && pm.onCharging) || {}
    readonly property var onUnplugged: (pm && pm.onUnplugged) || {}
    readonly property var profileBehaviors: (pm && pm.profileBehaviors) || {}
    readonly property var thresholds: (pm && pm.thresholds) || []

    TabStack {
        anchors.fill: parent
        currentIndex: root.activeTabIndex

        // Tab 0: Inhibit and idle
        Flickable {
            id: inhibitFlick

            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: inhibitGrid.implicitHeight + Tokens.padding.large * 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            GridLayout {
                id: inhibitGrid

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                columns: (width > 0 && width < 700) ? 1 : 2
                columnSpacing: Tokens.spacing.large * 2
                rowSpacing: Tokens.spacing.large

                // Section: Inhibit settings
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: Tokens.spacing.normal

                    StyledText {
                        text: qsTr("Inhibit settings")
                        font.pointSize: Tokens.font.size.normal * 1.2
                        font.weight: Font.Medium
                    }

                    StyledText {
                        text: qsTr("Control when the system should stay awake")
                        font.pointSize: Tokens.font.size.small
                        color: Qt.alpha(Colours.palette.m3onSurface, 0.6)
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    SwitchRow {
                        Layout.fillWidth: true
                        label: qsTr("Inhibit when audio is playing")
                        checked: GlobalConfig.general.idle?.inhibitWhenAudio ?? false
                        onToggled: c => GlobalConfig.general.idle.inhibitWhenAudio = c
                    }

                    SwitchRow {
                        Layout.fillWidth: true
                        label: qsTr("Lock before sleep")
                        checked: GlobalConfig.general.idle?.lockBeforeSleep ?? false
                        onToggled: c => GlobalConfig.general.idle.lockBeforeSleep = c
                    }
                }

                // Section: Idle timeouts
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: Tokens.spacing.normal

                    StyledText {
                        text: qsTr("Idle timeouts")
                        font.pointSize: Tokens.font.size.normal * 1.2
                        font.weight: Font.Medium
                    }

                    StyledText {
                        text: qsTr("Actions to perform after periods of inactivity")
                        font.pointSize: Tokens.font.size.small
                        color: Qt.alpha(Colours.palette.m3onSurface, 0.6)
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Loader {
                        id: idleListLoader

                        Layout.fillWidth: true
                        sourceComponent: IdleTimeoutList {}
                    }
                }
            }
        }

        // Tab 1: Battery & power behavior
        Loader {
            active: root.hasBattery
            sourceComponent: Flickable {
                id: thrFlick

                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: thrCol.implicitHeight + Tokens.padding.large * 2
                clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                ColumnLayout {
                    id: thrCol

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: Tokens.spacing.large

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: qsTr("Current power profile")
                            font.pointSize: Tokens.font.size.normal * 1.2
                            font.weight: Font.Medium
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.normal

                            MaterialIcon {
                                text: {
                                    switch (PowerProfiles.profile) {
                                    case PowerProfile.PowerSaver:
                                        return "battery_saver";
                                    case PowerProfile.Performance:
                                        return "rocket_launch";
                                    default:
                                        return "balance";
                                    }
                                }
                                color: Colours.palette.m3primary
                                font.pointSize: Tokens.font.size.large
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: {
                                    switch (PowerProfiles.profile) {
                                    case PowerProfile.PowerSaver:
                                        return qsTr("Power Saver");
                                    case PowerProfile.Performance:
                                        return qsTr("Performance");
                                    default:
                                        return qsTr("Balanced");
                                    }
                                }
                                font.pointSize: Tokens.font.size.normal
                                font.weight: Font.Medium
                            }

                            StyledText {
                                text: UPower.onBattery ? qsTr("On battery") : qsTr("Plugged in")
                                font.pointSize: Tokens.font.size.small
                                color: Qt.alpha(Colours.palette.m3onSurface, 0.6)
                            }
                        }
                    }

                    SwitchRow {
                        Layout.bottomMargin: Tokens.spacing.larger * 2
                        label: qsTr("Enable power management")
                        checked: root.pmEnabled
                        onToggled: c => {
                            const next = JSON.parse(JSON.stringify(GlobalConfig.general.battery.powerManagement || {}));
                            next.enabled = c;
                            GlobalConfig.general.battery.powerManagement = next;
                        }
                    }

                    // Battery behavior
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Tokens.spacing.larger * 1.2
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: qsTr("Battery & charging behavior")
                            font.pointSize: Tokens.font.size.normal * 1.2
                            font.weight: Font.Medium
                        }

                        StyledText {
                            text: qsTr("Define what happens when the battery reaches certain thresholds or charging status changes")
                            font.pointSize: Tokens.font.size.small
                            color: Qt.alpha(Colours.palette.m3onSurface, 0.6)
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: Tokens.spacing.large
                            Layout.bottomMargin: Tokens.spacing.larger * 4
                            spacing: Tokens.spacing.large
                            enabled: root.pmEnabled

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                Layout.alignment: Qt.AlignTop
                                spacing: Tokens.spacing.large

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.large

                                    BehaviorSection {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignTop
                                        titleText: qsTr("When plugged in")
                                        section: "onCharging"
                                        cfg: root.onCharging
                                    }

                                    BehaviorSection {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignTop
                                        titleText: qsTr("When unplugged")
                                        section: "onUnplugged"
                                        cfg: root.onUnplugged
                                        showEvaluateThresholds: true
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                Layout.maximumWidth: parent.width * 0.4
                                Layout.alignment: Qt.AlignTop
                                spacing: Tokens.spacing.large

                                StyledText {
                                    text: qsTr("Battery Level Thresholds")
                                    font.pointSize: Tokens.font.size.normal
                                    font.weight: Font.Medium
                                }

                                ThresholdList {
                                    Layout.fillWidth: true
                                    enabled: root.pmEnabled
                                    thresholds: root.thresholds
                                }
                            }
                        }
                    }

                    // Power Profile Behaviors
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Tokens.spacing.larger * 1.2
                        spacing: Tokens.spacing.small
                        enabled: root.pmEnabled

                        StyledText {
                            text: qsTr("Power Profile Behaviors")
                            font.pointSize: Tokens.font.size.normal * 1.2
                            font.weight: Font.Medium
                        }

                        StyledText {
                            text: qsTr("Define what Hyprland settings to apply when each power profile is active")
                            font.pointSize: Tokens.font.size.small
                            color: Qt.alpha(Colours.palette.m3onSurface, 0.6)
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: Tokens.spacing.large
                            spacing: Tokens.spacing.large

                            ProfileBehaviorColumn {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                Layout.alignment: Qt.AlignTop
                                titleText: qsTr("Power Saver")
                                profileKey: "powerSaver"
                                cfg: root.profileBehaviors.powerSaver || ({})
                            }

                            ProfileBehaviorColumn {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                Layout.alignment: Qt.AlignTop
                                titleText: qsTr("Balanced")
                                profileKey: "balanced"
                                cfg: root.profileBehaviors.balanced || ({})
                            }

                            ProfileBehaviorColumn {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                Layout.alignment: Qt.AlignTop
                                titleText: qsTr("Performance")
                                profileKey: "performance"
                                cfg: root.profileBehaviors.performance || ({})
                            }
                        }
                    }
                }
            }
        }
    }
}
