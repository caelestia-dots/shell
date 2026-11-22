pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.effects
import qs.components.hallownest
import qs.services
import qs.utils

StyledRect {
    id: root

    required property real rootHeight
    readonly property int cBoxSize: Tokens.font.body.medium.pointSize * 2
    // Undertale human souls, with Determination in the middle
    readonly property var souls: ["#42fcff", "#fca600", "#003cff", "#ff0000", "#d535d9", "#00c000", "#ffff00"]
    readonly property var soulPixels: [".###...###.", "#####.#####", "###########", "###########", "###########", ".#########.", "..#######..", "...#####...", "....###....", ".....#....."]

    implicitHeight: layout.implicitHeight + layout.anchors.topMargin + layout.anchors.margins
    radius: Tokens.rounding.medium
    color: Hallownest.card
    border.width: 1
    border.color: Hallownest.border

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraLarge
        anchors.topMargin: Tokens.padding.extraLarge
        anchors.bottomMargin: Tokens.padding.extraLarge

        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: prompt.implicitWidth + Tokens.padding.medium * 2
                implicitHeight: prompt.implicitHeight + Tokens.padding.small * 2

                color: Hallownest.soul
                radius: Tokens.rounding.medium

                MonoText {
                    id: prompt

                    anchors.centerIn: parent
                    text: ">"
                    color: Hallownest.void_
                }
            }

            MonoText {
                Layout.fillWidth: true
                text: "hallownest.sh"
                elide: Text.ElideRight
            }

            WrappedLoader {
                Layout.fillHeight: true
                Layout.preferredWidth: height
                Layout.preferredHeight: 0
                active: !iconLoader.active

                sourceComponent: SysInfo.isDefaultLogo ? maskLogo : distroIcon
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Tokens.spacing.extraLarge

            WrappedLoader {
                id: iconLoader

                Layout.fillHeight: true
                active: root.width > Tokens.sizes.lock.largeLogoWidth

                sourceComponent: SysInfo.isDefaultLogo ? maskLogo : distroIcon
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.padding.medium
                Layout.bottomMargin: iconLoader.active || colourRowLoader.active ? Tokens.padding.medium : 0
                spacing: Tokens.spacing.medium

                Repeater {
                    model: {
                        const items = [];
                        const hasBatt = UPower.displayDevice.isLaptopBattery;
                        const rHeight = root.rootHeight;

                        if (!hasBatt && rHeight > Tokens.sizes.lock.fetch4LinesHeight)
                            // TRANSLATORS: keep the label padded to 4 chars so the column stays aligned
                            items.push(Tr.tr("OS  : %1").arg(SysInfo.osPrettyName || SysInfo.osName));

                        if (rHeight > (hasBatt ? Tokens.sizes.lock.fetch4LinesHeight : Tokens.sizes.lock.fetch3LinesHeight))
                            // TRANSLATORS: keep the label padded to 4 chars so the column stays aligned
                            items.push(Tr.tr("WM  : %1").arg(SysInfo.wm));

                        if (!hasBatt || rHeight > Tokens.sizes.lock.fetch3LinesHeight)
                            // TRANSLATORS: keep the label padded to 4 chars so the column stays aligned
                            items.push(Tr.tr("USER: %1").arg(SysInfo.user));

                        // TRANSLATORS: keep the label padded to 4 chars so the column stays aligned
                        items.push(Tr.tr("UP  : %1").arg(SysInfo.uptime));

                        if (hasBatt) {
                            const charging = [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state);
                            const pct = Math.round(UPower.displayDevice.percentage * 100);
                            // TRANSLATORS: keep the label padded to 4 chars, (+) marks charging
                            items.push(charging ? Tr.tr("BATT: (+) %1%").arg(pct) : Tr.tr("BATT: %1%").arg(pct));
                        }

                        return items;
                    }

                    MonoText {
                        required property string modelData

                        Layout.fillWidth: true
                        text: modelData
                        elide: Text.ElideRight
                    }
                }
            }
        }

        WrappedLoader {
            id: colourRowLoader

            Layout.topMargin: iconLoader.active ? Tokens.spacing.small : 0
            Layout.alignment: Qt.AlignHCenter
            active: root.rootHeight > Tokens.sizes.lock.showColourBoxRowHeight

            sourceComponent: RowLayout {
                id: coloursRow

                spacing: Tokens.spacing.largeIncreased

                Repeater {
                    model: {
                        const count = CUtils.clamp(Math.floor((layout.width + coloursRow.spacing) / (root.cBoxSize + coloursRow.spacing)), 0, root.souls.length);
                        const start = Math.floor((root.souls.length - count) / 2);
                        return root.souls.slice(start, start + count);
                    }

                    Item {
                        id: soul

                        required property color modelData

                        implicitWidth: root.cBoxSize
                        implicitHeight: root.cBoxSize

                        PixelArt {
                            anchors.centerIn: parent
                            rows: root.soulPixels
                            pixelSize: root.cBoxSize / 11
                            color: soul.modelData
                            scale: soulHover.hovered ? 1.25 : 1

                            Behavior on scale {
                                Anim {
                                    type: Anim.FastSpatial
                                }
                            }
                        }

                        HoverHandler {
                            id: soulHover
                        }
                    }
                }
            }
        }
    }

    Component {
        id: maskLogo

        HealthMask {
            size: height
            glow: true
        }
    }

    Component {
        id: distroIcon

        ColouredIcon {
            source: SysInfo.osLogo
            implicitSize: height
            colour: Hallownest.soul
            layer.enabled: Config.lock.recolourLogo
        }
    }

    component WrappedLoader: Loader {
        asynchronous: true
        visible: active
    }

    component MonoText: StyledText {
        font: root.width > Tokens.sizes.lock.largeFontWidth ? Tokens.font.mono.medium : Tokens.font.mono.small
    }
}
