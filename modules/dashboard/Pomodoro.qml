import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.services
import Caelestia.Config

Item {
    id: root

    property var svc: PomodoroService

    // ── Colors ────────────────────────────────────────────────────────────
    readonly property color phaseColor: {
        if (svc.idleMode)                           return Colours.palette.m3onSurfaceVariant
        if (svc.currentPhase.type === "work")       return Colours.palette.m3primary
        if (svc.phaseIndex === 5 && svc.useLongBreak) return Colours.palette.m3secondary
        return Colours.palette.m3tertiary
    }

    readonly property color onPhaseColor: {
        if (svc.idleMode)                           return Colours.palette.m3onSurface
        if (svc.currentPhase.type === "work")       return Colours.palette.m3onPrimary
        if (svc.phaseIndex === 5 && svc.useLongBreak) return Colours.palette.m3onSecondary
        return Colours.palette.m3onTertiary
    }

    readonly property bool needsKeyboard: settingsSection.expanded

    implicitWidth: 480
    implicitHeight: outerCol.implicitHeight + Tokens.padding.large * 2

    StyledRect {
        anchors.fill: parent
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.large

        ColumnLayout {
            id: outerCol

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Tokens.padding.large
            }
            spacing: Tokens.spacing.normal

            // ── Header ────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "timer"
                    font.pointSize: Tokens.font.size.large
                    color: root.phaseColor
                    Behavior on color { CAnim { duration: Tokens.anim.durations.normal } }
                }

                StyledText {
                    text: qsTr("Pomodoro")
                    font.pointSize: Tokens.font.size.large
                    font.weight: Font.Medium
                    color: Colours.palette.m3onSurface
                }

                Item { Layout.fillWidth: true }

                // Stats + reset cluster
                RowLayout {
                    spacing: Tokens.spacing.normal

                    RowLayout {
                        spacing: Tokens.spacing.smaller

                        MaterialIcon {
                            text: "local_fire_department"
                            font.pointSize: Tokens.font.size.normal
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            text: svc.pomodoroCount
                            font.pointSize: Tokens.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    RowLayout {
                        spacing: Tokens.spacing.smaller

                        MaterialIcon {
                            text: "sync"
                            font.pointSize: Tokens.font.size.normal
                            color: Colours.palette.m3secondary
                        }

                        StyledText {
                            text: svc.cycleCount
                            font.pointSize: Tokens.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    // ↺ Reset — lives in header so it doesn't offset the centered playback controls
                    IconButton {
                        type: IconButton.Text
                        icon: "restart_alt"
                        font.pointSize: Tokens.font.size.normal
                        onClicked: svc.resetCurrent()
                    }
                }
            }

            // ── Phase dot strip ───────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Repeater {
                    model: svc.phases.length

                    Item {
                        id: dotItem

                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: 8

                        readonly property bool isCurrent: dotItem.index === svc.phaseIndex && !svc.idleMode
                        readonly property bool isDone: dotItem.index < svc.phaseIndex
                            || (svc.idleMode && dotItem.index <= svc.phaseIndex)
                        readonly property color dotColor: {
                            if (dotItem.isCurrent) return root.phaseColor
                            if (dotItem.isDone) return Qt.alpha(root.phaseColor, 0.35)
                            return Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.18)
                        }

                        StyledRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.full
                            color: dotItem.dotColor
                            Behavior on color { CAnim { duration: Tokens.anim.durations.normal } }
                        }
                    }
                }
            }

            // ── Timer ring ────────────────────────────────────────────────
            Item {
                id: ringItem

                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 220
                implicitHeight: 220

                // Geometry for annular hit-test (matches CircularProgress internals)
                // arcRadius = (size - strokeWidth) / 2 = (220 - 12) / 2 = 104
                readonly property real ringRadius: 104
                readonly property real ringStroke: 12
                readonly property real innerHitRadius: ringRadius - ringStroke * 3
                readonly property real outerHitRadius: ringRadius + ringStroke * 2.5

                CircularProgress {
                    id: timerRing

                    anchors.fill: parent
                    value: svc.idleMode ? 1.0 : svc.animatedProgress
                    startAngle: -90
                    strokeWidth: 12
                    fgColour: svc.idleMode
                        ? Qt.alpha(root.phaseColor, 0.22)
                        : root.phaseColor
                    bgColour: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.12)

                    Behavior on fgColour { CAnim { duration: Tokens.anim.durations.normal } }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.smaller

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: svc.idleMode
                            ? `+${svc.formatTime(svc.idleElapsed)}`
                            : svc.formatTime(svc.timeRemaining)
                        font.pointSize: Tokens.font.size.extraLarge * 1.35
                        font.weight: Font.Medium
                        color: svc.idleMode
                            ? Colours.palette.m3onSurfaceVariant
                            : root.phaseColor
                        Behavior on color { CAnim { duration: Tokens.anim.durations.normal } }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: svc.idleMode ? qsTr("Rest ended") : svc.currentPhase.name
                        font.pointSize: Tokens.font.size.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 8
                        implicitHeight: 8

                        StyledRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.full
                            color: (svc.isRunning && !svc.idleMode)
                                ? root.phaseColor
                                : Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.25)
                            Behavior on color { CAnim { duration: Tokens.anim.durations.normal } }
                        }
                    }
                }

                // ── Ring drag-to-seek (annular zone only) ─────────────────
                MouseArea {
                    id: ringDrag
                    anchors.fill: parent
                    hoverEnabled: true

                    property bool dragging: false

                    function distFromCenter(mx, my) {
                        const dx = mx - width / 2
                        const dy = my - height / 2
                        return Math.sqrt(dx * dx + dy * dy)
                    }

                    function onRing(mx, my) {
                        const d = distFromCenter(mx, my)
                        return d >= ringItem.innerHitRadius && d <= ringItem.outerHitRadius
                    }

                    function angleToProgress(mx, my) {
                        const cx = width / 2
                        const cy = height / 2
                        return (((Math.atan2(my - cy, mx - cx) * 180 / Math.PI) + 90) + 360) % 360 / 360
                    }

                    cursorShape: {
                        if (svc.idleMode) return Qt.ArrowCursor
                        return onRing(mouseX, mouseY) ? Qt.SizeAllCursor : Qt.ArrowCursor
                    }

                    onPressed: mouse => {
                        if (svc.idleMode || !onRing(mouse.x, mouse.y)) {
                            mouse.accepted = false
                            return
                        }
                        dragging = true
                        svc.smoothProgress = false
                        svc.elapsed = Math.round(angleToProgress(mouse.x, mouse.y) * svc.currentPhase.duration)
                    }

                    onPositionChanged: mouse => {
                        if (!dragging) return
                        svc.elapsed = Math.round(angleToProgress(mouse.x, mouse.y) * svc.currentPhase.duration)
                    }

                    onReleased: {
                        if (dragging) {
                            dragging = false
                            Qt.callLater(function() { svc.smoothProgress = true })
                        }
                    }
                }
            }

            // ── Idle banner ───────────────────────────────────────────────
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: idleRow.implicitHeight + Tokens.padding.normal * 2
                radius: Tokens.rounding.normal
                color: Qt.alpha(Colours.palette.m3tertiary, 0.1)
                visible: svc.idleMode

                RowLayout {
                    id: idleRow

                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: Tokens.padding.normal
                    }
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "coffee"
                        font.pointSize: Tokens.font.size.normal
                        color: Colours.palette.m3tertiary
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Break ended — press ▶ to start next session")
                        font.pointSize: Tokens.font.size.small
                        color: Colours.palette.m3tertiary
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // ── Controls (prev / play-pause / next) — centred, no asymmetric buttons ──
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: false
                Layout.bottomMargin: Tokens.spacing.normal
                spacing: Tokens.spacing.small

                // ← Prev
                Item {
                    implicitWidth: prevIcon.implicitWidth + Tokens.padding.small
                    implicitHeight: prevIcon.implicitHeight + Tokens.padding.small

                    MaterialIcon {
                        id: prevIcon
                        anchors.centerIn: parent
                        text: "skip_previous"
                        font.pointSize: Math.round(Tokens.font.size.extraLarge * 1.1)
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StateLayer {
                        color: Colours.palette.m3onSurfaceVariant
                        onClicked: svc.goToPrev()
                    }
                }

                // ▶/⏸ Play-Pause — always circular, bypasses Tokens.rounding.scale
                Item {
                    id: playBtnItem

                    readonly property real btnSize: playBtnIcon.implicitHeight + Tokens.padding.small * 2
                    implicitWidth: btnSize
                    implicitHeight: btnSize

                    StyledRect {
                        anchors.fill: parent
                        radius: width / 2
                        color: root.phaseColor
                        Behavior on color { CAnim { duration: Tokens.anim.durations.normal } }
                    }

                    MaterialIcon {
                        id: playBtnIcon
                        anchors.centerIn: parent
                        text: svc.isRunning ? "pause" : "play_arrow"
                        color: root.onPhaseColor
                        font.pointSize: Math.round(Tokens.font.size.extraLarge * 1.3)
                        Behavior on color { CAnim { duration: Tokens.anim.durations.normal } }
                    }

                    StateLayer {
                        radius: width / 2
                        color: root.onPhaseColor
                        onClicked: svc.togglePlayPause()
                    }
                }

                // → Next
                Item {
                    implicitWidth: nextIcon.implicitWidth + Tokens.padding.small
                    implicitHeight: nextIcon.implicitHeight + Tokens.padding.small

                    MaterialIcon {
                        id: nextIcon
                        anchors.centerIn: parent
                        text: "skip_next"
                        font.pointSize: Math.round(Tokens.font.size.extraLarge * 1.1)
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StateLayer {
                        color: Colours.palette.m3onSurfaceVariant
                        onClicked: svc.skipToNext()
                    }
                }
            }

            // ── Settings ──────────────────────────────────────────────────
            CollapsibleSection {
                id: settingsSection
                Layout.fillWidth: true
                title: qsTr("Settings")
                showBackground: true

                SpinBoxRow {
                    label: qsTr("Work (min)")
                    value: PomodoroService.workDuration
                    min: 1
                    max: 120
                    onValueModified: value => { PomodoroService.workDuration = value }
                }

                SpinBoxRow {
                    label: qsTr("Short break (min)")
                    value: PomodoroService.shortBreakDuration
                    min: 1
                    max: 60
                    onValueModified: value => { PomodoroService.shortBreakDuration = value }
                }

                SpinBoxRow {
                    label: qsTr("Long break (min)")
                    value: PomodoroService.longBreakDuration
                    min: 1
                    max: 120
                    onValueModified: value => { PomodoroService.longBreakDuration = value }
                }

                SwitchRow {
                    label: qsTr("Long break after cycle")
                    checked: PomodoroService.useLongBreak
                    onToggled: checked => { PomodoroService.useLongBreak = checked }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: soundRow.implicitHeight + Tokens.padding.large * 2
                    radius: Tokens.rounding.normal
                    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                    RowLayout {
                        id: soundRow

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Tokens.padding.large
                        spacing: Tokens.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Sound notifications")
                        }

                        CustomSpinBox {
                            min: 0
                            max: 100
                            step: 5
                            value: PomodoroService.soundVolume
                            enabled: PomodoroService.soundEnabled
                            opacity: PomodoroService.soundEnabled ? 1.0 : 0.4
                            onValueModified: value => { PomodoroService.soundVolume = value }

                            Behavior on opacity { CAnim {} }
                        }

                        StyledSwitch {
                            checked: PomodoroService.soundEnabled
                            onToggled: PomodoroService.soundEnabled = checked
                        }
                    }
                }
            }
        }
    }
}
