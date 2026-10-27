pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import M3Shapes
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

ClipRect {
    id: root

    readonly property real fillLevel: Hydration.progress
    property real animFill: 0
    property real wavePhase: 0
    readonly property bool presetsOpen: drinkHover.containsMouse
    // Largest closest to the glass FAB
    readonly property var presetOrder: {
        const out = [];
        for (let i = Hydration.presets.length - 1; i >= 0; --i)
            out.push(Hydration.presets[i]);
        return out;
    }

    anchors.fill: parent
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer
    implicitHeight: 220

    onFillLevelChanged: animFill = fillLevel
    Component.onCompleted: animFill = fillLevel

    Behavior on animFill {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    FrameAnimation {
        running: root.visible
        onTriggered: {
            root.wavePhase = (root.wavePhase + frameTime * 1.6) % (Math.PI * 2);
            tankCanvas.requestPaint();
        }
    }

    Canvas {
        id: tankCanvas

        anchors.fill: parent
        z: 0

        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const h = height;
            if (w < 2 || h < 2)
                return;
            ctx.reset();

            const fill = Math.max(0.06, Math.min(1, root.animFill));
            const waterTop = h * (1 - fill);
            const primary = Colours.palette.m3primary;
            const container = Colours.palette.m3primaryContainer;
            const toCss = (c, a) => `rgba(${Math.round(c.r * 255)},${Math.round(c.g * 255)},${Math.round(c.b * 255)},${a})`;

            ctx.beginPath();
            ctx.moveTo(0, h);
            ctx.lineTo(0, waterTop);
            const amp = Math.min(14, h * 0.05);
            const phase = root.wavePhase;
            for (let x = 0; x <= w; x += 2) {
                const y = waterTop + Math.sin(x / w * Math.PI * 2 + phase) * amp + Math.sin(x / w * Math.PI * 4 - phase * 1.3) * amp * 0.35;
                ctx.lineTo(x, y);
            }
            ctx.lineTo(w, h);
            ctx.closePath();

            const grad = ctx.createLinearGradient(0, waterTop, 0, h);
            grad.addColorStop(0, toCss(primary, root.animFill < 0.01 ? 0.35 : 0.88));
            grad.addColorStop(1, toCss(container, root.animFill < 0.01 ? 0.55 : 0.98));
            ctx.fillStyle = grad;
            ctx.fill();

            ctx.beginPath();
            const crest = waterTop + amp * 0.2;
            ctx.moveTo(0, h);
            ctx.lineTo(0, crest);
            for (let x2 = 0; x2 <= w; x2 += 2) {
                const y2 = crest + Math.sin(x2 / w * Math.PI * 2 - phase * 0.8) * amp * 0.55;
                ctx.lineTo(x2, y2);
            }
            ctx.lineTo(w, h);
            ctx.closePath();
            ctx.fillStyle = "rgba(255,255,255,0.14)";
            ctx.fill();
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Item {
        id: statsWrap

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: stats.implicitWidth + 16
        implicitHeight: stats.implicitHeight + 16
        z: 1

        layer.enabled: true
        layer.effect: SoftShadow {
            shadowOpacity: 0.58
            shadowBlur: 0.85
            blurMax: 28
            shadowVerticalOffset: 1.5
        }

        ColumnLayout {
            id: stats

            readonly property bool overWater: root.animFill > 0.72
            readonly property color ink: overWater ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            readonly property color accent: overWater ? Colours.palette.m3onPrimary : Colours.palette.m3tertiary

            anchors.centerIn: parent
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: Hydration.goalReached ? "water_full" : "water_drop"
                color: stats.accent
                fontStyle: Tokens.font.icon.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: Tr.tr("%1 / %2 ml").arg(Hydration.drunkMl).arg(Hydration.dailyGoalMl)
                color: stats.ink
                font: Tokens.font.headline.small
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: `${Math.round(Hydration.progress * 100)}%`
                color: stats.accent
                font: Tokens.font.title.small
            }
        }
    }

    // Glass FAB bottom-right; hover reveals +/− presets
    MouseArea {
        id: drinkHover

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.medium
        implicitWidth: drinkCol.implicitWidth
        implicitHeight: drinkCol.implicitHeight
        hoverEnabled: true
        z: 2

        ColumnLayout {
            id: drinkCol

            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: Tokens.spacing.extraSmall

            StyledRect {
                Layout.alignment: Qt.AlignRight
                implicitWidth: presetsPanel.implicitWidth + Tokens.padding.small * 2
                implicitHeight: presetsPanel.implicitHeight + Tokens.padding.small * 2
                radius: Tokens.rounding.large
                color: Colours.palette.m3surfaceContainerHighest
                opacity: root.presetsOpen ? 1 : 0
                visible: opacity > 0.01
                enabled: root.presetsOpen

                layer.enabled: true
                layer.effect: SoftShadow {}

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                RowLayout {
                    id: presetsPanel

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall

                    ColumnLayout {
                        spacing: Tokens.spacing.extraSmall

                        Repeater {
                            model: root.presetOrder

                            PresetChip {
                                required property int modelData
                                label: `−${modelData}`
                                subtract: true
                                amount: modelData
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: Tokens.spacing.extraSmall

                        Repeater {
                            model: root.presetOrder

                            PresetChip {
                                required property int modelData
                                label: `+${modelData}`
                                subtract: false
                                amount: modelData
                            }
                        }
                    }
                }
            }

            // M3 Cookie4Sided — same family as the dash resource “Uso” chip
            MaterialShape {
                Layout.alignment: Qt.AlignRight
                implicitSize: 44
                shape: MaterialShape.Cookie4Sided
                color: Colours.palette.m3secondaryContainer

                layer.enabled: true
                layer.effect: SoftShadow {}

                StateLayer {
                    anchors.fill: parent
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "add"
                    color: Colours.palette.m3onSecondaryContainer
                    fontStyle: Tokens.font.icon.builders.medium.weight(Font.Bold).build()
                }
            }
        }
    }

    component PresetChip: StyledRect {
        id: chip

        required property string label
        required property bool subtract
        required property int amount

        implicitWidth: 64
        implicitHeight: 32
        radius: Tokens.rounding.full
        color: chip.subtract
            ? Qt.tint(Colours.palette.m3surfaceContainerHighest, Qt.rgba(Colours.palette.m3error.r, Colours.palette.m3error.g, Colours.palette.m3error.b, 0.22))
            : Colours.palette.m3secondaryContainer

        StateLayer {
            radius: parent.radius
            onClicked: {
                if (chip.subtract)
                    Hydration.removeMl(chip.amount);
                else
                    Hydration.addMl(chip.amount);
            }
        }

        StyledText {
            anchors.centerIn: parent
            text: chip.label
            font: Tokens.font.label.medium
            color: chip.subtract ? Colours.palette.m3error : Colours.palette.m3onSecondaryContainer
            opacity: chip.subtract ? 0.85 : 1
            layer.enabled: true
            layer.effect: SoftShadow {}
        }
    }

    component SoftShadow: MultiEffect {
        shadowEnabled: true
        blurMax: 24
        shadowColor: Colours.palette.m3shadow
        shadowOpacity: 0.4
        shadowBlur: 1.0
        shadowVerticalOffset: 1
        shadowHorizontalOffset: 0
        shadowScale: 1.0
    }
}
