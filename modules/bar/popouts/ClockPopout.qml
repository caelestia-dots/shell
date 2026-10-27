pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.modules.dashboard.dash
import qs.services

ColumnLayout {
    id: root

    required property ScreenState screenState

    width: 340
    spacing: Tokens.spacing.medium

    function customMinutes(): real {
        const field = customMins.contentItem;
        if (field?.text !== undefined) {
            const parsed = customMins.valueFromText(field.text, customMins.locale);
            if (!Number.isNaN(parsed))
                return Math.min(customMins.to, Math.max(customMins.from, parsed));
        }
        return customMins.value;
    }

    function addCustomTimer(): void {
        const mins = root.customMinutes();
        customMins.value = mins;
        Timers.addMinutes(mins, "");
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: Hydration.enabled ? hydration.implicitHeight : calendar.implicitHeight
        radius: Tokens.rounding.extraLarge
        color: Hydration.enabled ? "transparent" : Colours.tPalette.m3surfaceContainerHigh

        Calendar {
            id: calendar

            visible: !Hydration.enabled
            anchors.left: parent.left
            anchors.right: parent.right
            screenState: root.screenState
        }

        HydrationWidget {
            id: hydration

            visible: Hydration.enabled
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: Timers.enabled
        spacing: Tokens.spacing.small

        StyledText {
            text: Tr.tr("Timers")
            font: Tokens.font.title.small
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            Repeater {
                model: [5, 10, 20, 30]

                StyledRect {
                    id: preset

                    required property int modelData

                    Layout.fillWidth: true
                    implicitHeight: presetLabel.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.full
                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                    StateLayer {
                        radius: parent.radius
                        onClicked: Timers.addMinutes(preset.modelData, "")
                    }

                    StyledText {
                        id: presetLabel

                        anchors.centerIn: parent
                        text: Tr.trN("%n min", "%n mins", preset.modelData)
                        font: Tokens.font.label.small
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledSpinBox {
                id: customMins

                Layout.fillWidth: true
                from: 1
                to: 180
                value: 30
                editable: true

                Keys.onReturnPressed: root.addCustomTimer()
                Keys.onEnterPressed: root.addCustomTimer()

                Connections {
                    target: customMins.contentItem

                    function onAccepted(): void {
                        root.addCustomTimer();
                    }
                }
            }

            IconButton {
                isRound: true
                icon: "add"
                type: IconButton.Tonal
                onClicked: root.addCustomTimer()
            }
        }

        StyledText {
            visible: Timers.timers.length === 0
            Layout.fillWidth: true
            text: Tr.tr("No active timers")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
        }

        Repeater {
            model: Timers.timers

            StyledRect {
                id: timerRow

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: timerInner.implicitHeight + Tokens.padding.small * 2
                radius: Tokens.rounding.large
                color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                RowLayout {
                    id: timerInner

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "timer"
                        color: Colours.palette.m3secondary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: timerRow.modelData.label
                            elide: Text.ElideRight
                            font: Tokens.font.label.medium
                        }

                        StyledText {
                            text: Timers.formatRemaining(timerRow.modelData.remainingMs)
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.mono.small
                        }
                    }

                    IconButton {
                        isRound: true
                        icon: "close"
                        type: IconButton.Text
                        onClicked: Timers.cancel(timerRow.modelData.id)
                    }
                }
            }
        }
    }
}
