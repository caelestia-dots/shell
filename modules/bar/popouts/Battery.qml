pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

ColumnLayout {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool charging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(device.state)

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

    spacing: Tokens.spacing.small
    width: Tokens.sizes.bar.batteryWidth

    Loader {
        Layout.fillWidth: true
        active: root.device.isLaptopBattery
        visible: active

        sourceComponent: BatteryCard {}
    }

    Loader {
        Layout.fillWidth: true
        active: !root.device.isLaptopBattery
        visible: active

        sourceComponent: StyledRect {
            implicitHeight: noBattLayout.implicitHeight + Tokens.padding.large * 2
            radius: Tokens.rounding.extraLarge
            color: Colours.tPalette.m3surfaceContainer

            RowLayout {
                id: noBattLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: noBattIcon.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3secondaryContainer

                    MaterialIcon {
                        id: noBattIcon

                        anchors.centerIn: parent
                        text: "power"
                        color: Colours.palette.m3onSecondaryContainer
                        fontStyle: Tokens.font.icon.medium
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("No battery detected")
                    font: Tokens.font.title.small
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    StyledRect {
        id: profiles

        readonly property real innerWidth: width - Tokens.padding.small * 2
        readonly property real inactiveWidth: saver.implicitHeight - Tokens.padding.extraSmall

        Layout.fillWidth: true
        implicitHeight: profileRow.implicitHeight + Tokens.padding.small * 2

        radius: Tokens.rounding.extraLarge
        color: Colours.tPalette.m3surfaceContainer

        Row {
            id: profileRow

            anchors.centerIn: parent
            spacing: Tokens.spacing.extraSmall / 2

            Profile {
                id: saver

                profile: PowerProfile.PowerSaver
                icon: "energy_savings_leaf"
                first: true
            }

            Profile {
                profile: PowerProfile.Balanced
                icon: "balance"
            }

            Profile {
                profile: PowerProfile.Performance
                icon: "rocket_launch"
                last: true
            }
        }
    }

    Loader {
        id: degraded

        readonly property bool shown: PowerProfiles.degradationReason !== PerformanceDegradationReason.None

        Layout.fillWidth: true
        Layout.preferredHeight: shown ? implicitHeight : 0
        Layout.topMargin: shown ? 0 : -root.spacing

        active: shown || opacity > 0
        opacity: shown ? 1 : 0
        clip: true

        sourceComponent: StyledRect {
            implicitHeight: degradedLayout.implicitHeight + Tokens.padding.medium * 2
            radius: Tokens.rounding.large
            color: Colours.palette.m3errorContainer

            RowLayout {
                id: degradedLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.large
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "warning"
                    color: Colours.palette.m3onErrorContainer
                    fontStyle: Tokens.font.icon.medium
                    fill: 1
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        // TRANSLATORS: charger or thermal warning: the battery cannot draw full power
                        text: Tr.tr("Performance degraded")
                        color: Colours.palette.m3onErrorContainer
                        font: Tokens.font.title.small
                        wrapMode: Text.WordWrap
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.perfDegradationToString(PowerProfiles.degradationReason)
                        color: Colours.palette.m3onErrorContainer
                        font: Tokens.font.body.small
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        Behavior on Layout.preferredHeight {
            Anim {}
        }

        Behavior on Layout.topMargin {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    component BatteryCard: StyledClippingRect {
        id: card

        // Starts empty so the fill sweeps in when the popout opens
        property real animPerc: 0

        Component.onCompleted: animPerc = Qt.binding(() => root.device.percentage)

        implicitHeight: contents.implicitHeight + Tokens.padding.large * 2 + Tokens.spacing.largeIncreased
        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3secondaryContainer

        BatteryContents {
            id: contents

            anchors.fill: parent
            anchors.margins: Tokens.padding.large

            accentColour: Colours.palette.m3primary
            textColour: Colours.palette.m3onSecondaryContainer
            subTextColour: Colours.palette.m3onSurfaceVariant
        }

        StyledClippingRect {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            implicitWidth: parent.width * card.animPerc

            color: Colours.palette.m3secondary
            radius: Tokens.rounding.extraSmall

            BatteryContents {
                x: Tokens.padding.large
                y: Tokens.padding.large
                width: card.width - Tokens.padding.large * 2
                height: card.height - Tokens.padding.large * 2

                accentColour: Colours.palette.m3primaryContainer
                textColour: Colours.palette.m3onSecondary
                subTextColour: Colours.palette.m3secondaryContainer
            }
        }

        Behavior on animPerc {
            Anim {
                type: Anim.SlowSpatial
            }
        }
    }

    component BatteryContents: ColumnLayout {
        id: contents

        required property color accentColour
        required property color textColour
        required property color subTextColour

        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: Icons.getBatteryIcon(root.device.percentage, root.charging)
                color: contents.accentColour
                fontStyle: Tokens.font.icon.medium
                fill: 1
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Battery")
                color: contents.textColour
                font: Tokens.font.title.small
                elide: Text.ElideRight
            }

            // Power draw while discharging, charge rate while charging
            StyledRect {
                id: powerChip

                readonly property real watts: Math.abs(root.device.changeRate)
                readonly property bool hasWatts: watts >= 0.05
                readonly property bool shown: hasWatts || root.charging

                implicitWidth: powerRow.implicitWidth + Tokens.padding.small * 2
                implicitHeight: powerRow.implicitHeight + Tokens.padding.extraSmall

                radius: Tokens.rounding.full
                color: Qt.alpha(contents.accentColour, 0.15)

                scale: shown ? 1 : 0
                opacity: shown ? 1 : 0

                Row {
                    id: powerRow

                    anchors.centerIn: parent
                    spacing: root.charging && powerChip.hasWatts ? Tokens.spacing.extraSmall / 2 : 0

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.charging
                        text: "bolt"
                        color: contents.accentColour
                        fontStyle: Tokens.font.icon.small
                        fill: 1
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: powerChip.hasWatts
                        // TRANSLATORS: power in watts, e.g. 9.4 W
                        text: Tr.tr("%1 W").arg(powerChip.watts.toLocaleString(Qt.locale(), "f", 1))
                        color: contents.accentColour
                        font: Tokens.font.label.large
                    }
                }

                Behavior on scale {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.FastEffects
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        StyledText {
            text: Strings.percentOne(root.device.percentage)
            color: contents.accentColour
            font: Tokens.font.headline.medium
        }

        StyledText {
            Layout.fillWidth: true
            text: {
                const dev = root.device;
                if (dev.state === UPowerDeviceState.FullyCharged || (root.charging && Math.round(dev.percentage * 100) === 100))
                    return Tr.tr("Fully charged!");

                if (root.charging) {
                    const time = root.formatSeconds(dev.timeToFull);
                    // TRANSLATORS: %1 = a duration, e.g. 1 hour, 20 mins
                    return time ? Tr.tr("%1 until full").arg(time) : Tr.tr("Calculating time until charged...");
                }

                const time = root.formatSeconds(dev.timeToEmpty);
                // TRANSLATORS: %1 = a duration, e.g. 3 hours, 25 mins
                return time ? Tr.tr("%1 left").arg(time) : Tr.tr("Calculating remaining battery life...");
            }
            color: contents.subTextColour
            font: Tokens.font.body.small
            elide: Text.ElideRight
            animate: true
        }
    }

    component Profile: StyledRect {
        id: segment

        required property int profile
        required property string icon
        property bool first
        property bool last

        readonly property bool active: PowerProfiles.profile === segment.profile
        readonly property real outerRadius: height / 2
        property real innerRadius: active ? height / 2 : Tokens.rounding.small

        implicitWidth: active ? profiles.innerWidth - profiles.inactiveWidth * 2 - profileRow.spacing * 2 : profiles.inactiveWidth
        implicitHeight: profileIcon.implicitHeight + Tokens.padding.small * 2

        color: active ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHighest
        topLeftRadius: first ? outerRadius : innerRadius
        bottomLeftRadius: first ? outerRadius : innerRadius
        topRightRadius: last ? outerRadius : innerRadius
        bottomRightRadius: last ? outerRadius : innerRadius
        clip: true

        StateLayer {
            color: segment.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            onClicked: PowerProfiles.profile = segment.profile
        }

        TextMetrics {
            id: labelMetrics

            text: root.powerProfileToString(segment.profile)
            font: Tokens.font.label.large
        }

        Row {
            anchors.centerIn: parent
            spacing: segment.active ? Tokens.spacing.extraSmall : 0

            MaterialIcon {
                id: profileIcon

                anchors.verticalCenter: parent.verticalCenter
                text: segment.icon
                color: segment.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                fill: segment.active ? 1 : 0

                Behavior on fill {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                width: segment.active ? Math.min(Math.ceil(labelMetrics.advanceWidth) + 1, segment.width - profileIcon.implicitWidth - Tokens.spacing.extraSmall - Tokens.padding.small * 2) : 0
                text: labelMetrics.text
                color: Colours.palette.m3onPrimary
                font: labelMetrics.font
                elide: Text.ElideRight
                opacity: segment.active ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            Behavior on spacing {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        Behavior on implicitWidth {
            Anim {
                type: Anim.FastSpatial
            }
        }

        Behavior on innerRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
