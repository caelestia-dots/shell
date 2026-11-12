import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Overlays")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("In the notch")
        }

        NotchToggle {
            first: true
            key: "osdVolume"
            text: Tr.tr("Volume")
        }

        NotchToggle {
            key: "osdMicrophone"
            text: Tr.tr("Microphone")
        }

        NotchToggle {
            key: "osdBrightness"
            text: Tr.tr("Brightness")
        }

        NotchToggle {
            key: "osdCapsLock"
            text: Tr.tr("Caps Lock")
        }

        NotchToggle {
            key: "osdKbLayout"
            text: Tr.tr("Keyboard layout")
        }

        NotchToggle {
            key: "osdCharger"
            text: Tr.tr("Charger")
        }

        NotchToggle {
            key: "osdBattery"
            text: Tr.tr("Low battery")
        }

        NotchToggle {
            key: "osdWifi"
            text: Tr.tr("Wi-Fi")
        }

        NotchToggle {
            key: "osdBluetooth"
            text: Tr.tr("Bluetooth")
        }

        NotchToggle {
            key: "notifsInNotch"
            text: Tr.tr("Notifications")
            subtext: Tr.tr("Shown as an NPC dialogue in the notch")
        }

        NotchToggle {
            key: "nextEvent"
            text: Tr.tr("Next class")
            subtext: Tr.tr("Reminder before the next calendar event")
        }

        NotchStepper {
            last: true
            key: "osdDuration"
            label: Tr.tr("Overlay duration")
            subtext: Tr.tr("Milliseconds")
            from: 500
            to: 6000
            stepSize: 100
        }

        SectionHeader {
            text: Tr.tr("Notifications")
        }

        NavRow {
            first: true
            last: true
            icon: "notifications"
            text: Tr.tr("Notifications and toasts")
            subtext: Tr.tr("Timeouts, grouping, toast events")
            onClicked: root.nState.openSubPage(1)
        }
    }
}
