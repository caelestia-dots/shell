import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> mascotItems: [
        MenuItem {
            text: Tr.tr("The Knight")
            value: "knight"
        },
        MenuItem {
            text: Tr.tr("Grimm")
            value: "grimm"
        },
        MenuItem {
            text: Tr.tr("Hornet")
            value: "hornet"
        }
    ]

    title: Tr.tr("Notch")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Island")
        }

        NotchToggle {
            first: true
            key: "minimal"
            text: Tr.tr("Minimal notch")
            subtext: Tr.tr("Collapse to a thin line")
        }

        NotchToggle {
            key: "twelveHour"
            text: Tr.tr("12-hour clock")
        }

        NotchToggle {
            key: "showDate"
            text: Tr.tr("Show date")
        }

        NotchStepper {
            last: true
            key: "scale"
            label: Tr.tr("Scale")
            from: 0.7
            to: 1.6
            stepSize: 0.05
        }

        SectionHeader {
            text: Tr.tr("Mascot")
        }

        SelectRow {
            first: true
            label: Tr.tr("Mascot")
            subtext: Tr.tr("Grimm takes the Knight's place in October")
            menuItems: root.mascotItems
            active: root.mascotItems.find(i => i.value === NotchSettings.values.mascotKind) ?? null
            onSelected: item => NotchSettings.set("mascotKind", item.value)
        }

        NotchToggle {
            key: "mascotRandom"
            text: Tr.tr("Random visits")
            subtext: Tr.tr("The mascot drops by now and then")
        }

        NotchToggle {
            key: "mascotTracking"
            text: Tr.tr("Follow the cursor")
            subtext: Tr.tr("The mascot's eyes follow the mouse")
        }

        NotchToggle {
            key: "mascotReactions"
            text: Tr.tr("Reactions")
            subtext: Tr.tr("The mascot reacts to battery, music, Wi-Fi, pomodoro and tasks")
        }

        NotchStepper {
            key: "mascotDelay"
            label: Tr.tr("Mascot delay")
            subtext: Tr.tr("Minutes idle before the mascot appears")
            from: 1
            to: 60
        }

        NotchStepper {
            last: true
            key: "dozeDelay"
            label: Tr.tr("Doze delay")
            subtext: Tr.tr("Minutes idle before the mascot falls asleep")
            from: 1
            to: 120
        }

        SectionHeader {
            text: Tr.tr("Focus")
        }

        NotchStepper {
            first: true
            key: "pomodoroFocus"
            label: Tr.tr("Focus time")
            subtext: Tr.tr("Minutes")
            from: 1
            to: 120
        }

        NotchStepper {
            key: "pomodoroBreak"
            label: Tr.tr("Short break")
            subtext: Tr.tr("Minutes")
            from: 1
            to: 60
        }

        NotchStepper {
            last: true
            key: "snoozeMinutes"
            label: Tr.tr("Snooze")
            subtext: Tr.tr("Minutes")
            from: 1
            to: 60
        }
    }
}
