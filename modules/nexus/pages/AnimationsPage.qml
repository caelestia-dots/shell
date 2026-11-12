import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Animations")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Notch")
        }

        NotchToggle {
            first: true
            key: "mascot"
            text: Tr.tr("Mascot")
            subtext: Tr.tr("Show the Knight when idle")
        }

        NotchToggle {
            key: "animTyping"
            text: Tr.tr("Dialogue typing")
            subtext: Tr.tr("Notifications are typed out like an NPC")
        }

        NotchToggle {
            last: true
            key: "animGoo"
            text: Tr.tr("Island and dock transition")
            subtext: Tr.tr("Drops travel along the frame when switching modes")
        }

        SectionHeader {
            text: Tr.tr("Scenes")
        }

        NotchToggle {
            first: true
            key: "animWeather"
            text: Tr.tr("Weather scenes")
            subtext: Tr.tr("Animated landscape in the Weather page")
        }

        NotchToggle {
            key: "animSeasons"
            text: Tr.tr("Seasons")
            subtext: Tr.tr("Grimm embers in October and snow in December")
        }

        NotchToggle {
            last: true
            key: "animBench"
            text: Tr.tr("Bench rest")
            subtext: Tr.tr("Darken before locking and the Knight on the bench in the lock screen")
        }
    }
}
