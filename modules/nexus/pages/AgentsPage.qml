import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("AI agents")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Claude Code")
        }

        ConnectedRect {
            first: true
            Layout.fillWidth: true
            implicitHeight: hooksRow.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: hooksRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Claude Code hooks")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: AgentSessions.hooksInstalled ? Tr.tr("Live sessions and approvals in the notch") : Tr.tr("Adds hooks to ~/.claude/settings.json (with a backup)")
                        color: Hallownest.subtext
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                HkButton {
                    icon: AgentSessions.hooksInstalled ? "link_off" : "add_link"
                    text: AgentSessions.hooksInstalled ? Tr.tr("Remove") : Tr.tr("Install")
                    accent: AgentSessions.hooksInstalled ? Hallownest.grimm : Hallownest.lifeblood
                    tinted: true
                    disabled: AgentSessions.hooksBusy
                    onClicked: AgentSessions.installHooks(!AgentSessions.hooksInstalled)
                }
            }
        }

        NotchToggle {
            key: "agentAlerts"
            text: Tr.tr("Approvals in the notch")
            subtext: Tr.tr("Allow or deny Claude's requests from the collapsed notch")
        }

        NotchToggle {
            last: true
            key: "agentOsd"
            text: Tr.tr("Finished sessions")
            subtext: Tr.tr("Show an overlay when Claude finishes")
        }
    }
}
