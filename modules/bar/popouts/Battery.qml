pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

Column {
    id: root

    property string thresholdPath: ""
    property int chargeLimit: 80
    readonly property list<int> limitSteps: [80, 85, 90, 95, 100]
    readonly property int currentStepIndex: Math.max(0, limitSteps.indexOf(chargeLimit))

    function setChargeLimit(val: int): void {
        if (!root.thresholdPath || root.chargeLimit === val)
            return;
        root.chargeLimit = val;
        setLimitProc.targetLimit = val;
        setLimitProc.running = false;
        setLimitProc.running = true;
    }

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

    Process {
        id: readLimitProc

        running: true
        command: ["sh", "-c", "for f in /sys/class/power_supply/BAT*/charge_control_end_threshold; do if [ -f \"$f\" ]; then printf '%s:%s\\n' \"$f\" \"$(cat \"$f\" 2>/dev/null)\"; break; fi; done"]

        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim();
                const sep = raw.lastIndexOf(":");
                if (sep > 0) {
                    root.thresholdPath = raw.slice(0, sep);
                    const val = parseInt(raw.slice(sep + 1), 10);
                    if (!isNaN(val) && val >= 50 && val <= 100)
                        root.chargeLimit = val;
                }
            }
        }
    }

    Process {
        id: setLimitProc

        property int targetLimit: 80

        command: ["sh", "-c", "printf '%s' \"$1\" > \"$2\" 2>/dev/null || true", "sh", String(targetLimit), root.thresholdPath]
        onExited: {
            readLimitProc.running = false;
            readLimitProc.running = true;
        }
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
            if (Math.round(dev.percentage * 100) >= root.chargeLimit)
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

        anchors.horizontalCenter: parent.horizontalCenter

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

    Column {
        id: limitSection

        width: parent.width
        spacing: Tokens.spacing.extraSmall
        visible: UPower.displayDevice.isLaptopBattery && root.thresholdPath.length > 0

        Item {
            width: parent.width
            implicitHeight: limitLabel.implicitHeight + Tokens.padding.extraSmall

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.chargeLimit < 100 ? "battery_saver" : "battery_full"
                    fontStyle: Tokens.font.icon.small
                    color: Colours.palette.m3primary
                }

                StyledText {
                    id: limitLabel

                    anchors.verticalCenter: parent.verticalCenter
                    text: Tr.tr("Charge limit")
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            StyledRect {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: badgeText.implicitWidth + Tokens.padding.small * 2
                implicitHeight: badgeText.implicitHeight + 4
                radius: Tokens.rounding.full
                color: root.chargeLimit < 100 ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainer

                Behavior on color {
                    CAnim {}
                }

                StyledText {
                    id: badgeText

                    anchors.centerIn: parent
                    text: `${root.chargeLimit}%`
                    font: Tokens.font.label.small
                    color: root.chargeLimit < 100 ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                }
            }
        }

        StyledRect {
            id: sliderContainer

            width: parent.width
            implicitHeight: 50
            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.large

            Item {
                id: trackArea

                readonly property real stepRatio: root.currentStepIndex / Math.max(1, root.limitSteps.length - 1)
                readonly property real usableWidth: Math.max(1, width - thumb.width)

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.medium
                anchors.topMargin: Tokens.padding.small
                height: 22

                StyledRect {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: thumb.width / 2
                    anchors.rightMargin: thumb.width / 2
                    height: 6
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3surfaceContainerHighest
                }

                StyledRect {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: thumb.width / 2
                    width: trackArea.usableWidth * trackArea.stepRatio
                    height: 6
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3primary

                    Behavior on width {
                        Anim {}
                    }
                }

                Repeater {
                    model: root.limitSteps

                    StyledRect {
                        required property int index
                        required property int modelData

                        readonly property bool activeOrPassed: index <= root.currentStepIndex

                        x: (thumb.width / 2) + (index / Math.max(1, root.limitSteps.length - 1)) * trackArea.usableWidth - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 10
                        height: 10
                        radius: Tokens.rounding.full
                        color: activeOrPassed ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                        Behavior on color {
                            CAnim {}
                        }
                    }
                }

                StyledRect {
                    id: thumb

                    x: trackArea.stepRatio * trackArea.usableWidth
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3primary
                    border.width: 3
                    border.color: Colours.tPalette.m3surfaceContainer

                    Behavior on x {
                        Anim {}
                    }
                }

                MouseArea {
                    function selectAt(mouseX: real): void {
                        const rel = Math.max(0, Math.min(1, (mouseX - thumb.width / 2) / trackArea.usableWidth));
                        const idx = Math.round(rel * (root.limitSteps.length - 1));
                        const val = root.limitSteps[idx];
                        if (val !== undefined)
                            root.setChargeLimit(val);
                    }

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: mouse => selectAt(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed)
                            selectAt(mouse.x);
                    }
                }
            }

            Item {
                anchors.left: trackArea.left
                anchors.right: trackArea.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                height: 14

                Repeater {
                    model: root.limitSteps

                    StyledText {
                        required property int index
                        required property int modelData

                        readonly property bool isSelected: modelData === root.chargeLimit

                        x: (thumb.width / 2) + (index / Math.max(1, root.limitSteps.length - 1)) * trackArea.usableWidth - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${modelData}%`
                        font: Tokens.font.label.small
                        color: isSelected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant

                        Behavior on color {
                            CAnim {}
                        }
                    }
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
