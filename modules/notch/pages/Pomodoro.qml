pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.services
import qs.modules.notch

NotchPage {
    id: root

    readonly property bool focusMode: Pomodoro.mode === "focus"
    readonly property color accent: focusMode ? Hallownest.infection : Hallownest.lifeblood
    readonly property int cycleFilled: Pomodoro.completedToday === 0 ? 0 : ((Pomodoro.completedToday - 1) % 4) + 1

    function adjustDuration(delta: int): void {
        if (Pomodoro.running)
            return;
        if (focusMode)
            NotchSettings.set("pomodoroFocus", Math.max(5, Math.min(90, NotchSettings.pomodoroFocus + delta)));
        else
            NotchSettings.set("pomodoroBreak", Math.max(1, Math.min(30, NotchSettings.pomodoroBreak + delta)));
    }

    implicitWidth: 580
    implicitHeight: card.implicitHeight

    HkCard {
        id: card

        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: layout.implicitHeight + Tokens.padding.large * 2
        ornate: true
        clip: true

        // Soft ambient glow behind the Soul Vessel tinted to the current mode
        Rectangle {
            x: -24
            anchors.verticalCenter: parent.verticalCenter
            width: 180
            height: 180
            radius: 90
            color: Qt.alpha(root.accent, Pomodoro.running ? 0.16 : 0.08)
            layer.enabled: root.visible
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1
                blurMax: 52
            }

            Behavior on color {
                CAnim {
                    duration: 600
                }
            }
        }

        RowLayout {
            id: layout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.large + 4
            anchors.rightMargin: Tokens.padding.large + 4
            spacing: Tokens.spacing.large + 4

            Item {
                implicitWidth: 96
                implicitHeight: 96

                SoulParticles {
                    anchors.fill: parent
                    anchors.margins: -10
                    running: Pomodoro.running && root.visible
                    visible: Pomodoro.running
                    count: 8
                    size: 2.5
                    colour: root.accent
                    duration: 3600
                }

                SoulVessel {
                    anchors.centerIn: parent
                    implicitWidth: 92
                    implicitHeight: 92
                    level: 1 - Pomodoro.progress
                    colour: root.accent
                    running: Pomodoro.running
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                // Segmented Focus / Break mode switch
                Rectangle {
                    implicitWidth: modeRow.implicitWidth + 6
                    implicitHeight: 26
                    radius: 13
                    color: Hallownest.void_
                    border.width: 1
                    border.color: Hallownest.border

                    Row {
                        id: modeRow

                        anchors.centerIn: parent
                        spacing: 2

                        ModeTab {
                            icon: "psychology"
                            label: Tr.tr("Focus")
                            active: root.focusMode
                            accent: Hallownest.infection
                            onClicked: Pomodoro.setMode("focus")
                        }

                        ModeTab {
                            icon: "coffee"
                            label: Tr.tr("Break")
                            active: !root.focusMode
                            accent: Hallownest.lifeblood
                            onClicked: Pomodoro.setMode("break")
                        }
                    }
                }

                RowLayout {
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: Pomodoro.remainingStr
                        color: Hallownest.soul
                        font.family: Hallownest.mono
                        font.pointSize: 30
                        font.weight: Font.Bold
                    }

                    Row {
                        Layout.alignment: Qt.AlignVCenter
                        visible: !Pomodoro.active
                        spacing: 2

                        GhostIcon {
                            icon: "remove"
                            onClicked: root.adjustDuration(root.focusMode ? -5 : -1)
                        }

                        GhostIcon {
                            icon: "add"
                            onClicked: root.adjustDuration(root.focusMode ? 5 : 1)
                        }
                    }
                }

                // 4 Charm-diamond cycle progress notches + daily session counter
                Row {
                    spacing: 6

                    Repeater {
                        model: 4

                        Rectangle {
                            required property int index
                            readonly property bool filled: index < root.cycleFilled

                            anchors.verticalCenter: parent.verticalCenter
                            width: 6
                            height: 6
                            rotation: 45
                            color: filled ? root.accent : "transparent"
                            border.width: 1
                            border.color: filled ? root.accent : Qt.alpha(Hallownest.steel, 0.35)

                            Behavior on color {
                                CAnim {}
                            }
                        }
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 4
                        text: Tr.tr("%1 today").arg(Pomodoro.completedToday)
                        color: Hallownest.subtext
                        font.pointSize: 8.5
                    }
                }
            }

            // Right: Clean transport controls
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Tokens.spacing.small

                HkButton {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 110
                    implicitHeight: 34
                    icon: Pomodoro.running ? "pause" : "play_arrow"
                    text: Pomodoro.running ? Tr.tr("Pause") : Pomodoro.active ? Tr.tr("Resume") : Tr.tr("Start")
                    accent: Pomodoro.running ? root.accent : Hallownest.soul
                    filled: true
                    onClicked: Pomodoro.toggle()
                }

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.small

                    GhostIcon {
                        icon: "restart_alt"
                        disabled: !Pomodoro.active
                        onClicked: Pomodoro.reset()
                    }

                    GhostIcon {
                        icon: "skip_next"
                        onClicked: Pomodoro.skip()
                    }
                }
            }
        }
    }

    component ModeTab: Rectangle {
        id: tab

        property string icon
        property string label
        property bool active
        property color accent: Hallownest.soul

        signal clicked

        implicitWidth: tabRow.implicitWidth + 16
        implicitHeight: 20
        radius: 10
        color: active ? Qt.alpha(accent, 0.18) : tabArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.45) : "transparent"

        Behavior on color {
            CAnim {}
        }

        Row {
            id: tabRow

            anchors.centerIn: parent
            spacing: 4

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: tab.icon
                color: tab.active ? tab.accent : tabArea.containsMouse ? Hallownest.soul : Hallownest.subtext
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: tab.label
                color: tab.active ? Hallownest.soul : tabArea.containsMouse ? Hallownest.soul : Hallownest.subtext
                font.pointSize: 8
                font.weight: tab.active ? Font.DemiBold : Font.Medium
            }
        }

        MouseArea {
            id: tabArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tab.clicked()
        }
    }

    component GhostIcon: Rectangle {
        id: ghost

        property string icon
        property bool disabled

        signal clicked

        implicitWidth: 28
        implicitHeight: 28
        radius: 14
        color: ghostArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.6) : "transparent"
        opacity: disabled ? 0.3 : 1
        scale: ghostArea.pressed ? 0.92 : 1

        Behavior on color {
            CAnim {}
        }

        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: ghost.icon
            color: ghostArea.containsMouse ? Hallownest.soul : Hallownest.steel
            fontStyle: Tokens.font.icon.small
        }

        MouseArea {
            id: ghostArea

            anchors.fill: parent
            enabled: !ghost.disabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ghost.clicked()
        }
    }
}
