pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.services

RowLayout {
    id: root

    readonly property UPowerDevice dev: UPower.displayDevice
    readonly property UPowerDevice battery: UPower.devices.values.find(d => d.isLaptopBattery) ?? null
    readonly property real level: dev.percentage
    readonly property bool charging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(dev.state)
    readonly property bool low: level <= 0.2 && !charging
    readonly property color accent: charging ? Hallownest.lifeblood : low ? Hallownest.grimm : Hallownest.soul

    function formatSeconds(s: int): string {
        const hr = Math.floor(s / 3600);
        const min = Math.floor(s / 60) % 60;
        return hr > 0 ? Tr.tr("%1 h %2 min").arg(hr).arg(min) : Tr.tr("%1 min").arg(min);
    }

    function status(): string {
        if (!dev.isLaptopBattery)
            return Tr.tr("No battery detected");
        if (UPower.onBattery)
            return dev.timeToEmpty > 0 ? Tr.tr("%1 left").arg(formatSeconds(dev.timeToEmpty)) : Tr.tr("On battery");
        if (Math.round(level * 100) === 100)
            return Tr.tr("Fully charged");
        return dev.timeToFull > 0 ? Tr.tr("Full in %1").arg(formatSeconds(dev.timeToFull)) : Tr.tr("Charging");
    }

    spacing: Tokens.spacing.medium

    HkCard {
        Layout.preferredWidth: 210
        Layout.fillHeight: true
        implicitHeight: hero.implicitHeight + 32
        ornate: true

        ColumnLayout {
            id: hero

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 16
            spacing: 4

            SoulOrb {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 92
                implicitHeight: 92
                level: root.dev.isLaptopBattery ? root.level : 0
                colour: root.accent
                running: root.charging
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 4
                horizontalAlignment: Text.AlignHCenter
                text: root.dev.isLaptopBattery ? `${Math.round(root.level * 100)}%` : "—"
                color: root.accent
                font.family: Hallownest.mono
                font.pointSize: 13
                font.weight: Font.Bold
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.charging ? Tr.tr("Soul Restoring") : root.low ? Tr.tr("Soul Fading") : Tr.tr("Soul Vessel")
                color: root.charging ? Hallownest.lifeblood : root.low ? Hallownest.grimm : Hallownest.soul
                font.family: Hallownest.serif
                font.pointSize: 11
                font.weight: Font.Bold
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.status()
                color: Hallownest.subtext
                font.pointSize: 8
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.battery?.healthSupported ?? false
                horizontalAlignment: Text.AlignHCenter
                text: Tr.tr("Health %1%").arg(Math.round(root.battery?.healthPercentage ?? 0))
                color: (root.battery?.healthPercentage ?? 100) < 70 ? Hallownest.grimm : Hallownest.faint
                font.pointSize: 8
            }
        }
    }

    ListCard {
        title: Tr.tr("Power profile")

        Profile {
            profile: PowerProfile.PowerSaver
            icon: "energy_savings_leaf"
            text: Tr.trCtx("Power saver", "power profile")
            subtext: Tr.tr("Longer battery life, lower performance")
            accent: Hallownest.unn
        }

        Profile {
            profile: PowerProfile.Balanced
            icon: "balance"
            text: Tr.trCtx("Balanced", "power profile")
            subtext: Tr.tr("Performance and battery in harmony")
            accent: Hallownest.lifeblood
        }

        Profile {
            visible: PowerProfiles.hasPerformanceProfile
            profile: PowerProfile.Performance
            icon: "rocket_launch"
            text: Tr.trCtx("Performance", "power profile")
            subtext: Tr.tr("Full power, drains the battery faster")
            accent: Hallownest.infection
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
            implicitHeight: 36
            radius: 12
            color: Qt.alpha(Hallownest.grimm, 0.14)
            border.width: 1
            border.color: Qt.alpha(Hallownest.grimm, 0.5)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                MaterialIcon {
                    text: "warning"
                    color: Hallownest.grimm
                }

                StyledText {
                    Layout.fillWidth: true
                    text: PowerProfiles.degradationReason === PerformanceDegradationReason.HighTemperature ? Tr.tr("Performance degraded: the device is too hot") : PowerProfiles.degradationReason === PerformanceDegradationReason.LapDetected ? Tr.tr("Performance degraded: the device is on a lap") : Tr.tr("Performance degraded")
                    color: Hallownest.grimm
                    font.pointSize: 9
                    elide: Text.ElideRight
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.leftMargin: 6
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Follow the charger")
                    color: Hallownest.text
                    font.pointSize: 10
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Power saver on battery, balanced when plugged in")
                    color: Hallownest.faint
                    font.pointSize: 8
                    elide: Text.ElideRight
                }
            }

            HkSwitch {
                checked: NotchSettings.values.autoPowerProfile
                onToggled: c => NotchSettings.set("autoPowerProfile", c)
            }
        }
    }

    component Profile: DeviceRow {
        required property int profile

        active: PowerProfiles.profile === profile
        onClicked: PowerProfiles.profile = profile
    }
}
