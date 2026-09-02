pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// Settings page for the privacy monitor. Reads and writes the sidecar
// privacy.json through the Privacy service rather than GlobalConfig, because
// the shell's own config schema is compiled into the C++ plugin.
PageBase {
    id: root

    title: qsTr("Privacy")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Status")
        }

        // Live readout, so it is obvious whether a quiet indicator means
        // "nothing is using your devices" or "the monitor is not running".
        ConnectedRect {
            first: true
            last: true
            Layout.fillWidth: true
            implicitHeight: statusCol.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: statusCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                StyledText {
                    text: {
                        if (!Privacy.enabled)
                            return qsTr("Monitoring is off");
                        if (!Privacy.healthy)
                            return qsTr("Monitor is not responding");
                        return Privacy.anyActive ? qsTr("In use now") : qsTr("Nothing in use");
                    }
                    font: Tokens.font.body.medium
                    color: Privacy.enabled && !Privacy.healthy ? Colours.palette.m3error : Colours.palette.m3onSurface
                }

                Repeater {
                    model: ScriptModel {
                        values: Privacy.sensors
                    }

                    RowLayout {
                        id: row

                        required property var modelData

                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: row.modelData.icon
                            fill: row.modelData.active ? 1 : 0
                            color: row.modelData.active ? Colours.palette.m3error : Colours.palette.m3outlineVariant
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            text: row.modelData.label
                            font: Tokens.font.label.large
                            color: row.modelData.watched ? Colours.palette.m3onSurface : Colours.palette.m3outlineVariant
                        }

                        // Takes the remaining width and right-aligns, rather
                        // than a spacer plus a maximumWidth derived from the
                        // row's own width -- that makes the row's width depend
                        // on itself and Qt aborts the layout as recursive.
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight

                            text: {
                                const d = row.modelData;
                                if (!d.watched)
                                    return qsTr("not watched");
                                if (d.active)
                                    return Privacy.describe(d);
                                if (d.standby)
                                    return qsTr("client registered");
                                return qsTr("idle");
                            }
                            font: Tokens.font.label.small
                            color: Colours.palette.m3outline
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("General")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Watch for microphone, camera, screen and location use")
            checked: Config.privacy.enabled
            onToggled: GlobalConfig.privacy.enabled = checked
        }

        ToggleRow {
            text: qsTr("Show indicator")
            subtext: qsTr("Drop a pill below the webcam while a device is in use")
            checked: Config.privacy.showIndicator
            onToggled: GlobalConfig.privacy.showIndicator = checked
        }

        ToggleRow {
            text: qsTr("Taskbar dot")
            subtext: qsTr("Keep a coloured dot in the bar while a device is in use")
            checked: Config.privacy.showBarIndicator
            onToggled: GlobalConfig.privacy.showBarIndicator = checked
        }

        ToggleRow {
            text: qsTr("Toasts")
            subtext: qsTr("Also raise a toast when a device starts being used")
            checked: Config.privacy.showToasts
            onToggled: GlobalConfig.privacy.showToasts = checked
        }

        StepperRow {
            last: true
            label: qsTr("Expanded time")
            subtext: qsTr("Milliseconds the pill stays open before it shrinks to a dot")
            value: Config.privacy.expandDuration
            from: 1000
            to: 10000
            stepSize: 500
            onMoved: v => GlobalConfig.privacy.expandDuration = v
        }

        SectionHeader {
            text: qsTr("Devices")
        }

        ToggleRow {
            first: true
            text: qsTr("Microphone")
            subtext: qsTr("Any application capturing audio")
            checked: Config.privacy.devices.microphone
            onToggled: GlobalConfig.privacy.devices.microphone = checked
        }

        ToggleRow {
            text: qsTr("Camera")
            subtext: qsTr("Any application holding a video device")
            checked: Config.privacy.devices.camera
            onToggled: GlobalConfig.privacy.devices.camera = checked
        }

        ToggleRow {
            text: qsTr("Screen capture")
            subtext: qsTr("Screen sharing and screen recording")
            checked: Config.privacy.devices.screen
            onToggled: GlobalConfig.privacy.devices.screen = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Location")
            subtext: qsTr("Fires when GeoClue hands a position to an application")
            checked: Config.privacy.devices.location
            onToggled: GlobalConfig.privacy.devices.location = checked
        }
    }
}
