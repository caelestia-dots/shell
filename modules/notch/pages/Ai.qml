pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.services
import qs.modules.notch

NotchPage {
    id: root

    // Same toggle as SUPER + A / SUPER + SHIFT + A (Hyprland's utils/functions.lua)
    function openAssistant(agent: string): void {
        Quickshell.execDetached(["hyprctl", "dispatch", `require("utils.functions").toggle("${agent}")`]);
        root.screenState.notch = false;
    }

    function relativeTime(ms: real): string {
        const mins = Math.floor((Date.now() - ms) / 60000);
        if (mins < 1)
            return Tr.tr("now");
        if (mins < 60)
            return Tr.tr("%1 min ago").arg(mins);
        const hours = Math.floor(mins / 60);
        if (hours < 24)
            return Tr.tr("%1 h ago").arg(hours);
        const days = Math.floor(hours / 24);
        if (days < 7)
            return Tr.tr("%1 d ago").arg(days);
        return Qt.locale().toString(new Date(ms), "d MMM");
    }

    implicitWidth: 760
    implicitHeight: layout.implicitHeight

    Component.onCompleted: AiUsage.refresh(false)

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.large
            Layout.rightMargin: Tokens.padding.small
            spacing: Tokens.spacing.medium

            Column {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true

                StyledText {
                    text: Tr.tr("Assistant")
                    color: Hallownest.text
                    font.family: Hallownest.serif
                    font.pointSize: 16
                    font.weight: Font.Bold
                }

                StyledText {
                    text: Tr.tr("Super + A · Super + Shift + A")
                    color: Hallownest.subtext
                    font.pointSize: 8
                }
            }

            HkButton {
                Layout.alignment: Qt.AlignVCenter
                filled: true
                icon: "terminal"
                text: "Claude Code"
                onClicked: root.openAssistant("claude")
            }

            HkButton {
                Layout.alignment: Qt.AlignVCenter
                icon: "terminal"
                text: "Antigravity"
                onClicked: root.openAssistant("agy")
            }
        }

        AgentApproval {
            Layout.fillWidth: true
            visible: !!AgentSessions.current
            approval: AgentSessions.current
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            Card {
                Layout.preferredWidth: 430
                Layout.fillHeight: true
                implicitHeight: liveColumn.implicitHeight + Tokens.padding.large * 2

                ColumnLayout {
                    id: liveColumn

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.small
                        Layout.bottomMargin: Tokens.spacing.extraSmall
                        spacing: Tokens.spacing.small

                        CardTitle {
                            text: Tr.tr("Live sessions")
                        }

                        StyledText {
                            visible: AgentSessions.sessions.length > 0
                            text: AgentSessions.sessions.length
                            color: Hallownest.subtext
                            font.family: Hallownest.serif
                            font.pointSize: 10
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.small
                        visible: !AgentSessions.hooksInstalled && AgentSessions.sessions.length === 0
                        spacing: Tokens.spacing.small

                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("Install the Claude Code hooks to follow your sessions live and answer their requests from here.")
                            wrapMode: Text.WordWrap
                            color: Hallownest.subtext
                            font.pointSize: 9
                        }

                        HkButton {
                            icon: "add_link"
                            text: Tr.tr("Install hooks")
                            accent: Hallownest.lifeblood
                            tinted: true
                            disabled: AgentSessions.hooksBusy
                            onClicked: AgentSessions.installHooks(true)
                        }
                    }

                    StyledText {
                        Layout.leftMargin: Tokens.padding.small
                        visible: AgentSessions.hooksInstalled && AgentSessions.sessions.length === 0
                        text: Tr.tr("No active sessions")
                        color: Hallownest.subtext
                        font.pointSize: 9
                    }

                    Repeater {
                        model: ScriptModel {
                            values: AgentSessions.sessions.slice(0, 3)
                        }

                        delegate: LiveSession {}
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: limits.implicitHeight + Tokens.padding.large * 2

                ColumnLayout {
                    id: limits

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.small

                        CardTitle {
                            Layout.fillWidth: true
                            text: Tr.tr("Limits")
                        }

                        HkButton {
                            implicitHeight: 26
                            icon: "refresh"
                            disabled: AiUsage.loading
                            onClicked: AiUsage.refresh(true)
                        }
                    }

                    AgentLimits {
                        name: "Claude Code"
                        usage: AiUsage.claude
                        signIn: "claude auth login"
                    }

                    AgentLimits {
                        name: "Antigravity"
                        usage: AiUsage.agy
                        signIn: "agy"
                    }
                }
            }
        }
    }

    component AgentLimits: ColumnLayout {
        id: agent

        property string name
        property var usage
        property string signIn

        Layout.fillWidth: true
        spacing: 6

        StyledText {
            Layout.leftMargin: Tokens.padding.small
            text: agent.name
            color: Hallownest.steel
            font.pointSize: 9
            font.weight: Font.DemiBold
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            visible: !!agent.usage?.error
            text: {
                const e = agent.usage?.error;
                if (e === "not-logged-in" || e === "auth")
                    return Tr.tr("Sign in again with `%1`").arg(agent.signIn);
                if (e === "expired")
                    return Tr.tr("Run `%1` once to refresh the sign-in").arg(agent.signIn);
                if (e === "rate-limited")
                    return Tr.tr("Too many checks, try again later");
                return Tr.tr("Couldn't reach the provider");
            }
            wrapMode: Text.WordWrap
            color: Hallownest.subtext
            font.pointSize: 8
        }

        Meter {
            title: Tr.tr("Session (5 h)")
            window: agent.usage?.session ?? null
            resetFormat: "HH:mm"
        }

        Meter {
            title: Tr.tr("Week")
            window: agent.usage?.week ?? null
            resetFormat: "ddd HH:mm"
        }
    }

    component Card: StyledRect {
        radius: Tokens.rounding.extraLarge
        color: Hallownest.card
        border.width: 1
        border.color: Hallownest.border
    }

    component CardTitle: StyledText {
        color: Hallownest.steel
        font.family: Hallownest.serif
        font.pointSize: 11
        font.weight: Font.Bold
    }

    component Meter: ColumnLayout {
        id: meter

        property string title
        property var window
        property string resetFormat
        readonly property real percent: window?.percent ?? 0
        readonly property color tone: percent >= 90 ? Hallownest.grimm : percent >= 70 ? Hallownest.gold : Hallownest.lifeblood

        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        Layout.rightMargin: Tokens.padding.small
        visible: !!window
        spacing: 4

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: meter.title
                color: Hallownest.text
                font.pointSize: 10
            }

            StyledText {
                text: `${Math.round(meter.percent)}%`
                color: meter.tone
                font.family: Hallownest.mono
                font.pointSize: 9
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 10

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 5
                radius: 2.5
                color: Hallownest.button
            }

            Item {
                anchors.fill: parent
                layer.enabled: meter.visible
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: meter.tone
                    shadowBlur: 0.55
                    shadowOpacity: 0.65
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                    blurMax: 8
                }

                Rectangle {
                    id: meterFill

                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * Math.min(1, meter.percent / 100)
                    height: 5
                    radius: 2.5
                    color: meter.tone

                    Behavior on width {
                        Anim {}
                    }
                }

                Rectangle {
                    x: meterFill.width - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6
                    height: 6
                    rotation: 45
                    radius: 1
                    color: Hallownest.soul
                    visible: meter.percent > 1
                }
            }
        }

        StyledText {
            visible: !!meter.window?.resetsAt
            text: Tr.tr("Resets %1").arg(Qt.locale().toString(new Date(meter.window?.resetsAt ?? 0), meter.resetFormat))
            color: Hallownest.faint
            font.pointSize: 8
        }
    }

    component LiveSession: StyledRect {
        id: live

        required property var modelData

        readonly property color tone: ({
                thinking: Hallownest.lifeblood,
                working: Hallownest.soul,
                waiting: Hallownest.gold,
                done: Hallownest.unn,
                error: Hallownest.grimm
            })[modelData.state] ?? Hallownest.faint
        readonly property bool busy: modelData.state === "thinking" || modelData.state === "working"
        readonly property string status: {
            const s = modelData;
            switch (s.state) {
            case "thinking":
                return Tr.tr("Thinking...");
            case "working":
                return s.tool ? AgentSessions.describe(s.tool, s.detail) : Tr.tr("Working...");
            case "waiting":
                return Tr.tr("Waiting for you");
            case "done":
                return Tr.tr("Done");
            case "error":
                return Tr.tr("Something went wrong");
            default:
                return Tr.tr("Idle");
            }
        }

        Layout.fillWidth: true
        implicitHeight: liveLayout.implicitHeight + Tokens.padding.medium * 2

        radius: Tokens.rounding.large
        color: Qt.alpha(live.tone, 0.05)
        border.width: 1
        border.color: Qt.alpha(live.tone, live.modelData.state === "waiting" ? 0.5 : 0.18)

        StateLayer {
            color: Hallownest.text
            onClicked: AgentSessions.focusTerminal(live.modelData)
        }

        ColumnLayout {
            id: liveLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.large
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                Rectangle {
                    id: liveDot

                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 8
                    implicitHeight: 8
                    rotation: 45
                    color: live.tone

                    SequentialAnimation on opacity {
                        running: live.busy
                        loops: Animation.Infinite
                        onRunningChanged: {
                            if (!running)
                                liveDot.opacity = 1;
                        }

                        NumberAnimation {
                            to: 0.3
                            duration: 700
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            to: 1
                            duration: 700
                            easing.type: Easing.InOutSine
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: live.modelData.project || "~"
                    elide: Text.ElideRight
                    color: Hallownest.text
                    font.family: Hallownest.serif
                    font.pointSize: 10
                    font.weight: Font.Bold
                }

                MaterialIcon {
                    visible: live.modelData.agent === "claude-desktop"
                    text: "desktop_windows"
                    color: Hallownest.subtext
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    text: root.relativeTime(live.modelData.updated)
                    color: Hallownest.faint
                    font.pointSize: 8
                }

                MaterialIcon {
                    text: "open_in_new"
                    color: Hallownest.subtext
                    fontStyle: Tokens.font.icon.small
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: !!live.modelData.prompt
                text: live.modelData.prompt.replace(/\s+/g, " ")
                elide: Text.ElideRight
                color: Hallownest.subtext
                font.pointSize: 9
            }

            StyledText {
                Layout.fillWidth: true
                text: live.status
                elide: Text.ElideRight
                color: live.tone
                font.pointSize: 9
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                visible: live.modelData.state === "done" && !!live.modelData.message
                text: live.modelData.message.replace(/\s+/g, " ")
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Hallownest.text
                font.pointSize: 9
            }

            Repeater {
                model: live.busy ? live.modelData.steps.slice(-2) : []

                delegate: StyledText {
                    required property string modelData

                    Layout.fillWidth: true
                    text: `· ${modelData}`
                    elide: Text.ElideRight
                    color: Hallownest.faint
                    font.pointSize: 8
                }
            }
        }
    }
}
