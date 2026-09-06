pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services

Column {
    id: root

    // qmllint disable missing-property
    readonly property string batteryError: String(BatteryControl?.error ?? "")
    // qmllint enable missing-property
    readonly property bool hasBatteryError: batteryError.length > 0

    spacing: Tokens.spacing.medium
    width: Tokens.sizes.bar.batteryWidth

    ServiceRef {
        service: BatteryControl
    }

    StyledText {
        text: UPower.displayDevice.isLaptopBattery ? qsTr("Remaining: %1%").arg(Math.round(UPower.displayDevice.percentage * 100)) : qsTr("No battery detected")
    }

    StyledText {
        function formatSeconds(s: int, fallback: string): string {
            const day = Math.floor(s / 86400);
            const hr = Math.floor(s / 3600) % 24;
            const min = Math.floor(s / 60) % 60;

            let comps = [];
            if (day > 0)
                comps.push(qsTr("%1 days").arg(day));
            if (hr > 0)
                comps.push(qsTr("%1 hours").arg(hr));
            if (min > 0)
                comps.push(qsTr("%1 mins").arg(min));

            return comps.join(", ") || fallback;
        }

        text: UPower.displayDevice.isLaptopBattery ? qsTr("Time %1: %2").arg(UPower.onBattery ? qsTr("remaining") : qsTr("until charged")).arg(UPower.onBattery ? formatSeconds(UPower.displayDevice.timeToEmpty, qsTr("Calculating...")) : formatSeconds(UPower.displayDevice.timeToFull, qsTr("Fully charged!"))) : qsTr("Power profile: %1").arg(PowerProfile.toString(PowerProfiles.profile))
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
                        text: qsTr("Performance Degraded")
                        color: Colours.palette.m3onError
                        font: Tokens.font.mono.builders.medium.weight(Font.Medium).build()
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

                    text: qsTr("Reason: %1").arg(PerformanceDegradationReason.toString(PowerProfiles.degradationReason))
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

    StyledRect {
        id: batteryCard

        visible: BatteryControl.isSupported && !root.hasBatteryError
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: parent.width
        implicitHeight: cardLayout.implicitHeight + Tokens.padding.medium * 2
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.large
        ToolTip.visible: batteryHover.hovered && !cardLayout.enabled
        ToolTip.text: qsTr("Battery control busy")

        ColumnLayout {
            id: cardLayout

            enabled: !BatteryControl.busy
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "battery_saver"
                    fontStyle: Tokens.font.icon.medium
                    color: BatteryControl.enabled ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: BatteryControl.title
                        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                    }

                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: BatteryControl.subtitle
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.builders.small.build()
                    }
                }

                StyledSwitch {
                    visible: BatteryControl.isSupported && BatteryControl.isBinary
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    checked: BatteryControl.enabled
                    onToggled: BatteryControl.toggle()
                }
            }

            RowLayout {
                visible: BatteryControl.isSupported && BatteryControl.isTiers
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                Repeater {
                    model: BatteryControl.supportedTiers

                    TextButton {
                        required property int modelData

                        Layout.fillWidth: true
                        isToggle: true
                        type: TextButton.Tonal
                        text: `${modelData}%`
                        checked: BatteryControl.threshold === modelData
                        onClicked: BatteryControl.setThreshold(modelData)
                    }
                }
            }

            StyledSlider {
                visible: BatteryControl.isSupported && BatteryControl.isRange
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.extraSmall
                from: BatteryControl.minThreshold
                to: BatteryControl.maxThreshold
                stepSize: BatteryControl.stepSize
                value: BatteryControl.threshold
                onInteraction: v => {
                    const raw = v * (to - from) + from;
                    const step = Math.max(1, BatteryControl.stepSize);
                    const snapped = Math.round(raw / step) * step;
                    BatteryControl.setThreshold(Math.max(from, Math.min(to, snapped)));
                }
            }
        }

        HoverHandler {
            id: batteryHover
        }
    }

    StyledRect {
        id: batteryErrorCard

        visible: BatteryControl.isSupported && root.hasBatteryError
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: parent.width
        implicitHeight: errorLayout.implicitHeight + Tokens.padding.medium * 2
        color: Colours.palette.m3errorContainer
        radius: Tokens.rounding.large

        ColumnLayout {
            id: errorLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "error"
                    fontStyle: Tokens.font.icon.medium
                    color: Colours.palette.m3onErrorContainer
                }

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: qsTr("Battery error")
                    font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                    color: Colours.palette.m3onErrorContainer
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.batteryError
                color: Colours.palette.m3onErrorContainer
                font: Tokens.font.body.builders.small.build()
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            TextButton {
                Layout.alignment: Qt.AlignHCenter
                type: TextButton.Text
                text: qsTr("Retry")
                // qmllint disable missing-property
                onClicked: BatteryControl.retry()
                // qmllint enable missing-property
            }
        }
    }

    StyledRect {
        id: unsupportedCard

        visible: !BatteryControl.isSupported
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: parent.width
        implicitHeight: unsupportedLayout.implicitHeight + Tokens.padding.medium * 2
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.large
        ToolTip.visible: unsupportedHover.hovered
        ToolTip.text: qsTr("Charge control needs a supported battery driver")

        ColumnLayout {
            id: unsupportedLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "battery_unknown"
                    fontStyle: Tokens.font.icon.medium
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: qsTr("Battery control unsupported")
                    font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Charge limits are not available on this device.")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.small.build()
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }
        }

        HoverHandler {
            id: unsupportedHover
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
