pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Caelestia.Blobs
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
    readonly property bool presetsOpen: fabHover.hovered || panelHover.hovered || closeGrace.running
    readonly property real drinkPad: Tokens.padding.medium
    readonly property real drinkSize: 44
    // Small overlap so blobs fuse; panel grows up from the FAB, flush with its right edge
    readonly property real drinkNeck: Tokens.spacing.small
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

    // ~60fps while Dash is visible
    Timer {
        interval: 16
        running: root.visible
        repeat: true
        onTriggered: {
            root.wavePhase = (root.wavePhase + 0.016 * 1.6) % (Math.PI * 2);
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

    // FAB bottom-right; hover blooms presets out of the button (same BlobGroup trick as lyrics info)
    Item {
        id: drinkSlot

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.medium
        width: root.drinkSize
        height: root.drinkSize
        z: 2

        Timer {
            id: closeGrace

            // Bridge the gap between FAB and panel while the cursor travels the neck
            interval: 280
        }

        function armCloseGrace(): void {
            if (fabHover.hovered || panelHover.hovered)
                closeGrace.stop();
            else
                closeGrace.restart();
        }

        BlobGroup {
            id: drinkBlobs

            color: Colours.palette.m3surfaceContainerHighest
            smoothing: Tokens.rounding.medium
            cornerFill: false

            Behavior on color {
                CAnim {}
            }
        }

        BlobRect {
            id: fabBlob

            anchors.fill: parent
            anchors.margins: root.presetsOpen || fabHover.hovered ? -Tokens.padding.extraSmall : 0
            group: drinkBlobs
            radius: root.presetsOpen ? Tokens.rounding.large : Tokens.rounding.extraLarge

            Behavior on anchors.margins {
                Anim {}
            }

            Behavior on radius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        BlobRect {
            id: panelBlob

            anchors.right: parent.right
            anchors.bottom: parent.bottom
            implicitWidth: parent.width
            implicitHeight: parent.height
            group: drinkBlobs
            radius: Tokens.rounding.large
            deformScale: 0.00001

            states: State {
                name: "open"
                when: root.presetsOpen

                PropertyChanges {
                    // Grow upward from the FAB, right edges aligned (neck at top of the +)
                    panelBlob.anchors.rightMargin: 0
                    panelBlob.anchors.bottomMargin: drinkSlot.height - root.drinkNeck
                    panelBlob.implicitWidth: Math.max(presetsPanel.implicitWidth + root.drinkPad * 2, drinkSlot.width)
                    panelBlob.implicitHeight: Math.max(presetsPanel.implicitHeight + root.drinkPad * 2, drinkSlot.height)
                    presetsContent.opacity: 1
                }
            }

            transitions: Transition {
                Anim {
                    properties: "rightMargin,implicitWidth"
                }
                Anim {
                    properties: "bottomMargin,implicitHeight"
                    easing: Tokens.anim.expressiveFastSpatial
                }
                Anim {
                    property: "opacity"
                    type: Anim.DefaultEffects
                }
            }

            Behavior on implicitWidth {
                Anim {}
            }

            Behavior on implicitHeight {
                Anim {}
            }

            Item {
                id: presetsContent

                anchors.fill: parent
                clip: true
                opacity: 0
                enabled: root.presetsOpen

                HoverHandler {
                    id: panelHover

                    onHoveredChanged: drinkSlot.armCloseGrace()
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
        }

        Item {
            anchors.fill: parent
            z: 1

            HoverHandler {
                id: fabHover

                onHoveredChanged: drinkSlot.armCloseGrace()
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: "add"
                color: Colours.palette.m3onSurface
                fontStyle: Tokens.font.icon.builders.medium.weight(Font.Bold).build()
            }
        }
    }

    component PresetChip: StyledRect {
        id: chip

        required property string label
        required property bool subtract
        required property int amount

        implicitWidth: 56
        implicitHeight: 28
        radius: Tokens.rounding.full
        color: chip.subtract
            ? Qt.tint(Colours.palette.m3surfaceContainerHighest, Qt.rgba(Colours.palette.m3error.r, Colours.palette.m3error.g, Colours.palette.m3error.b, 0.28))
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
