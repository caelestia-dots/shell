pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    spacing: Tokens.spacing.large

    RowLayout {
        Layout.fillWidth: true
        Layout.margins: Tokens.padding.medium

        StyledText {
            text: qsTr("Monitors")
            font: Tokens.font.title.large
            Layout.fillWidth: true
        }

        IconTextButton {
            icon: "info"
            text: qsTr("Identify")
            isToggle: true
            checked: Monitors.identifying
            onClicked: Monitors.toggleIdentification()
        }
    }

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: monitorsLayout.implicitHeight
        clip: true

        ColumnLayout {
            id: monitorsLayout

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Tokens.spacing.medium

            Repeater {
                model: Hyprctl.monitors

                delegate: StyledRect {
                    id: monitorDelegate

                    required property var modelData

                    readonly property var mon: monitorDelegate.modelData
                    readonly property var brightnessMon: Brightness.getMonitor(monitorDelegate.mon.name)

                    Layout.fillWidth: true
                    implicitHeight: monitorContent.implicitHeight + Tokens.padding.large * 2
                    color: Colours.tPalette.m3surfaceContainerHigh
                    radius: Tokens.rounding.large

                    ColumnLayout {
                        id: monitorContent

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.large
                        spacing: Tokens.spacing.medium

                        RowLayout {
                            Layout.fillWidth: true
                            MaterialIcon {
                                text: "monitor"
                                color: Colours.palette.m3primary
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    text: `${monitorDelegate.mon.name} - ${monitorDelegate.mon.make} ${monitorDelegate.mon.model}`
                                    font: Tokens.font.title.medium
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    text: `${monitorDelegate.mon.width}x${monitorDelegate.mon.height}@${(monitorDelegate.mon.refreshRate ?? 0).toFixed(2)}Hz`
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.body.small
                                }
                            }
                            StyledText {
                                text: `ID: ${monitorDelegate.mon.id}`
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }

                        // Brightness
                        RowLayout {
                            Layout.fillWidth: true
                            visible: !!monitorDelegate.brightnessMon

                            MaterialIcon {
                                text: "brightness_medium"
                                fontStyle: Tokens.font.icon.medium
                            }

                            StyledSlider {
                                Layout.fillWidth: true
                                value: monitorDelegate.brightnessMon?.brightness ?? 0
                                onMoved: if (monitorDelegate.brightnessMon)
                                    monitorDelegate.brightnessMon.setBrightness(value)
                            }

                            StyledText {
                                text: `${Math.round((monitorDelegate.brightnessMon?.brightness ?? 0) * 100)}%`
                                Layout.preferredWidth: 40
                            }
                        }

                        // Scaling
                        RowLayout {
                            Layout.fillWidth: true

                            MaterialIcon {
                                text: "zoom_in"
                                fontStyle: Tokens.font.icon.medium
                            }

                            StyledSlider {
                                Layout.fillWidth: true
                                from: 0.5
                                to: 3.0
                                value: monitorDelegate.mon.scale
                                onMoved: Monitors.setScale(monitorDelegate.mon.name, value)
                            }

                            StyledText {
                                text: `${monitorDelegate.mon.scale.toFixed(2)}x`
                                Layout.preferredWidth: 40
                            }
                        }

                        // Refresh Rate
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledText {
                                text: qsTr("Refresh Rate")
                                Layout.fillWidth: true
                            }

                            CustomSpinBox {
                                id: rrSelector

                                min: 10
                                max: 1000
                                step: 1
                                value: monitorDelegate.mon.refreshRate
                                onValueModified: val => Monitors.setRefreshRate(monitorDelegate.mon.name, val)
                            }
                        }

                        // Rotation
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledText {
                                text: qsTr("Rotation")
                                Layout.fillWidth: true
                            }

                            Repeater {
                                model: [
                                    {
                                        label: "0°",
                                        val: 0,
                                        icon: "screen_rotation"
                                    },
                                    {
                                        label: "90°",
                                        val: 1,
                                        icon: "screen_rotation"
                                    },
                                    {
                                        label: "180°",
                                        val: 2,
                                        icon: "screen_rotation"
                                    },
                                    {
                                        label: "270°",
                                        val: 3,
                                        icon: "screen_rotation"
                                    }
                                ]

                                delegate: IconButton {
                                    required property var modelData
                                    required property int index

                                    icon: modelData.icon
                                    isToggle: true
                                    checked: monitorDelegate.mon.transform === modelData.val
                                    onClicked: Monitors.rotate(monitorDelegate.mon.name, modelData.val * 90)
                                }
                            }
                        }

                        // Arrangement
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledText {
                                text: qsTr("Position relative to:")
                                Layout.fillWidth: true
                            }

                            CustomSpinBox {
                                id: targetMonSelector

                                min: 0
                                max: Math.max(0, (Hyprctl.monitors.length ?? 1) - 1)
                                value: 0
                            }

                            IconButton {
                                icon: "arrow_back"
                                onClicked: Monitors.arrange(monitorDelegate.mon.name, "left", targetMonSelector.value)
                            }
                            IconButton {
                                icon: "arrow_forward"
                                onClicked: Monitors.arrange(monitorDelegate.mon.name, "right", targetMonSelector.value)
                            }
                            IconButton {
                                icon: "arrow_upward"
                                onClicked: Monitors.arrange(monitorDelegate.mon.name, "top", targetMonSelector.value)
                            }
                            IconButton {
                                icon: "arrow_downward"
                                onClicked: Monitors.arrange(monitorDelegate.mon.name, "bottom", targetMonSelector.value)
                            }
                        }
                    }
                }
            }
        }
    }
}
