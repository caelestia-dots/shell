pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

Column {
    id: root

    function formatSeconds(s: int): string {
        const day = Math.floor(s / 86400);
        const hr = Math.floor(s / 3600) % 24;
        const min = Math.floor(s / 60) % 60;

        let comps = [];
        if (day > 0)
            comps.push(Tr.trN("%n day", "%n days", day));
        if (hr > 0)
            comps.push(Tr.trN("%n hour", "%n hours", hr));
        if (min > 0)
            comps.push(Tr.trN("%n min", "%n mins", min));

        return comps.join(Tr.trCtx(", ", "duration component separator"));
    }

    function powerProfileToString(p: int): string {
        switch (p) {
        case PowerProfile.Balanced:
            return Tr.trCtx("Balanced", "power profile");
        case PowerProfile.Performance:
            return Tr.trCtx("Performance", "power profile");
        case PowerProfile.PowerSaver:
            return Tr.trCtx("Power saver", "power profile");
        default:
            return Tr.trCtx("Unknown", "power profile");
        }
    }

    function perfDegradationToString(p: int): string {
        switch (p) {
        case PerformanceDegradationReason.HighTemperature:
            return Tr.tr("The device is too hot");
        case PerformanceDegradationReason.LapDetected:
            return Tr.tr("The device is on a lap");
        default:
            return Tr.tr("Unknown reason");
        }
    }

    spacing: Tokens.spacing.medium
    width: Tokens.sizes.bar.batteryWidth

    property string conservationPath: ""
    property bool conservationMode: false
    readonly property bool conservationAvailable: conservationPath !== ""

    FileView {
        path: "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
        printErrors: false
        onLoaded: {
            root.conservationPath = path;
            root.conservationMode = text().trim() === "1";
        }
    }

    FileView {
        path: "/sys/class/power_supply/BAT0/charge_control_end_threshold"
        printErrors: false
        onLoaded: {
            if (!root.conservationPath) {
                root.conservationPath = path;
                const val = parseInt(text().trim());
                root.conservationMode = val > 0 && val <= 80;
            }
        }
    }

    FileView {
        path: "/sys/devices/platform/asus-nb-wmi/charge_control_end_threshold"
        printErrors: false
        onLoaded: {
            if (!root.conservationPath) {
                root.conservationPath = path;
                const val = parseInt(text().trim());
                root.conservationMode = val > 0 && val <= 80;
            }
        }
    }

    FileView {
        id: conservationWatcher

        path: root.conservationPath
        printErrors: false
        onLoaded: {
            const val = text().trim();
            if (path.includes("conservation_mode")) {
                root.conservationMode = val === "1";
            } else {
                const n = parseInt(val);
                root.conservationMode = n > 0 && n <= 80;
            }
        }
    }

    Timer {
        id: refreshTimer

        interval: 250
        repeat: false
        onTriggered: conservationWatcher.reload()
    }

    StyledText {
        text: UPower.displayDevice.isLaptopBattery ? Tr.trCtx("Remaining: %1%", "battery remaining").arg(Math.round(UPower.displayDevice.percentage * 100)) : Tr.tr("No battery detected")
    }

    StyledText {
        text: {
            const dev = UPower.displayDevice;
            if (!dev.isLaptopBattery)
                return Tr.tr("Power profile: %1").arg(root.powerProfileToString(PowerProfiles.profile));

            if (UPower.onBattery) {
                const time = root.formatSeconds(dev.timeToEmpty);
                if (time)
                    return Tr.tr("Time remaining: %1").arg(time);
                return Tr.tr("Calculating remaining battery life...");
            }

            if (dev.timeToFull > 0)
                return Tr.tr("Time until charged: %1").arg(root.formatSeconds(dev.timeToFull));
            if (Math.round(dev.percentage * 100) === 100)
                return Tr.tr("Fully charged!");
            return Tr.tr("Calculating time until charged...");
        }
    }

    Loader {
        asynchronous: true
        anchors.horizontalCenter: parent.horizontalCenter

        active: PowerProfiles.degradationReason !== PerformanceDegradationReason.None

        height: active ? ((item as Item)?.implicitHeight ?? 0) : 0

        sourceComponent: StyledRect {
            implicitWidth: child.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: child.implicitHeight + Tokens.padding.large

            color: Colours.palette.m3error
            radius: Tokens.rounding.large

            Column {
                id: child

                anchors.centerIn: parent

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -font.pointSize / 10

                        text: "warning"
                        color: Colours.palette.m3onError
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        // TRANSLATORS: charger or thermal warning: the battery cannot draw full power
                        text: Tr.tr("Performance degraded")
                        color: Colours.palette.m3onError
                        font: Tokens.font.title.small
                    }

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -font.pointSize / 10

                        text: "warning"
                        color: Colours.palette.m3onError
                    }
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: root.perfDegradationToString(PowerProfiles.degradationReason)
                    color: Colours.palette.m3onError
                }
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Tokens.spacing.small

        StyledRect {
            id: profiles

            property string current: {
                const p = PowerProfiles.profile;
                if (p === PowerProfile.PowerSaver)
                    return saver.icon;
                if (p === PowerProfile.Performance)
                    return perf.icon;
                return balance.icon;
            }

            implicitWidth: saver.implicitHeight + balance.implicitHeight + perf.implicitHeight + Tokens.padding.medium * 2 + Tokens.spacing.largeIncreased * 2
            implicitHeight: Math.max(saver.implicitHeight, balance.implicitHeight, perf.implicitHeight) + Tokens.padding.small

            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.full

            StyledRect {
                id: indicator

                color: Colours.palette.m3primary
                radius: Tokens.rounding.full
                state: profiles.current

                states: [
                    State {
                        name: saver.icon

                        Fill {
                            item: saver
                        }
                    },
                    State {
                        name: balance.icon

                        Fill {
                            item: balance
                        }
                    },
                    State {
                        name: perf.icon

                        Fill {
                            item: perf
                        }
                    }
                ]

                transitions: Transition {
                    AnchorAnim {}
                }
            }

            Profile {
                id: saver

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Tokens.padding.extraSmall

                profile: PowerProfile.PowerSaver
                icon: "energy_savings_leaf"
            }

            Profile {
                id: balance

                anchors.centerIn: parent

                profile: PowerProfile.Balanced
                icon: "balance"
            }

            Profile {
                id: perf

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Tokens.padding.extraSmall

                profile: PowerProfile.Performance
                icon: "rocket_launch"
            }
        }

        StyledRect {
            id: conservationBtn

            visible: root.conservationAvailable
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: profiles.implicitHeight - 4
            implicitHeight: profiles.implicitHeight - 4

            radius: Tokens.rounding.full
            color: root.conservationMode ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainer

            Behavior on color {
                CAnim {}
            }

            MaterialIcon {
                id: consIcon

                anchors.centerIn: parent
                text: "battery_saver"
                fontStyle: Tokens.font.icon.large
                color: root.conservationMode ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                fill: root.conservationMode ? 1 : 0

                Behavior on color {
                    CAnim {}
                }

                Behavior on fill {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            StateLayer {
                radius: Tokens.rounding.full
                color: root.conservationMode ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                onClicked: {
                    if (root.conservationPath.includes("conservation_mode")) {
                        const next = root.conservationMode ? "0" : "1";
                        Quickshell.execDetached(["sh", "-c", `echo ${next} > "${root.conservationPath}"`]);
                    } else {
                        const next = root.conservationMode ? "100" : "80";
                        Quickshell.execDetached(["sh", "-c", `echo ${next} > "${root.conservationPath}"`]);
                    }
                    refreshTimer.restart();
                }
            }
        }
    }

    component Fill: AnchorChanges {
        required property Item item

        target: indicator
        anchors.left: item.left
        anchors.right: item.right
        anchors.top: item.top
        anchors.bottom: item.bottom
    }

    component Profile: Item {
        required property string icon
        required property int profile

        implicitWidth: icon.implicitHeight + Tokens.padding.small
        implicitHeight: icon.implicitHeight + Tokens.padding.small

        StateLayer {
            radius: Tokens.rounding.full
            color: profiles.current === parent.icon ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            onClicked: PowerProfiles.profile = parent.profile
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent

            text: parent.icon
            fontStyle: Tokens.font.icon.large
            color: profiles.current === text ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
            fill: profiles.current === text ? 1 : 0

            Behavior on fill {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }
}
