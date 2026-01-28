pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Caelestia.Services
import Quickshell
import QtQuick
import QtQuick.Effects
import Quickshell.Widgets

Item {
    id: root
    anchors.fill: parent

    required property ShellScreen screen
    required property Wallpaper wallpaper

    readonly property bool shouldBeActive: Config.background.visualiser.enabled && (!Config.background.visualiser.autoHide || (Hypr.monitorFor(screen)?.activeWorkspace?.toplevels?.values.every(t => t.lastIpcObject?.floating) ?? true))
    property real offset: shouldBeActive ? 0 : screen.height * 0.2
    opacity: shouldBeActive ? 1 : 0

    Behavior on offset {
        Anim {}
    }
    Behavior on opacity {
        Anim {}
    }

    ServiceRef {
        id: cavaRef
        service: Audio.cava
    }

    ShaderEffectSource {
        id: wallpaperSource
        sourceItem: root.wallpaper
        live: true
    }

    property color barColorTop: Qt.alpha(Colours.palette.m3primary, 1)
    property color barColorBottom: Qt.alpha(Colours.palette.m3inversePrimary, 0.7)

    property real barRadius: Appearance.rounding.small * Config.background.visualiser.rounding

    Loader {
        anchors.fill: parent
        y: offset
        height: parent.height - offset * 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Visibilities.bars.get(root.screen).exclusiveZone + Appearance.spacing.small * Config.background.visualiser.spacing
        anchors.margins: Config.border.thickness
        active: root.opacity > 0 && Config.background.visualiser.blur
        sourceComponent: MultiEffect {
            source: wallpaperSource
            maskSource: canvas
            maskEnabled: true
            maskSpreadAtMax: 0
            maskSpreadAtMin: 0
            maskThresholdMin: 0.67 // eliminates blur spreading out of bounds
            blurEnabled: true
            blur: 1
            blurMax: 32
            autoPaddingEnabled: false
            shadowEnabled: false
        }
    }

    Item {
        id: canvasWrapper
        anchors.fill: parent
        y: offset
        height: parent.height - offset * 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Visibilities.bars.get(root.screen).exclusiveZone + Appearance.spacing.small * Config.background.visualiser.spacing
        anchors.margins: Config.border.thickness

        Canvas {
            id: canvas
            anchors.fill: parent
            property int barCount: Config.services.visualiserBars
            property real spacing: Appearance.spacing.small * Config.background.visualiser.spacing
            property real barWidth: (width * 0.4 / barCount) - spacing

            property var displayValues: Array(barCount * 2).fill(0)

            property real smoothing: 1 - (0.95 * Config.background.visualiser.smoothing)

            property int spatialRadius: Config.background.visualiser.curvature

            property var spatialValues: Array(barCount * 2).fill(0)

            function drawRoundedRect(ctx, x, y, w, h, r) {
                r = Math.min(r, w / 2, h / 2);
                ctx.beginPath();
                ctx.moveTo(x + r, y);
                ctx.lineTo(x + w - r, y);
                ctx.quadraticCurveTo(x + w, y, x + w, y + r);
                ctx.lineTo(x + w, y + h);
                ctx.lineTo(x, y + h);
                ctx.lineTo(x, y + r);
                ctx.quadraticCurveTo(x, y, x + r, y);
                ctx.closePath();
            }

            function spatialSmooth(index, values, radius) {
                var sum = 0;
                var weightSum = 0;

                for (var o = -radius; o <= radius; o++) {
                    var idx = index + o;
                    if (idx < 0 || idx >= values.length)
                        continue;

                    var w = Math.exp(-(o * o) / (2 * radius * radius));
                    sum += values[idx] * w;
                    weightSum += w;
                }
                return weightSum > 0 ? sum / weightSum : values[index];
            }

            renderStrategy: Canvas.Cooperative
            layer.enabled: true

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (!Audio.cava.values)
                    return;

                var gradientTopY = height * 0.7;
                var gradientBottomY = height;
                var sharedGradient = ctx.createLinearGradient(0, gradientTopY, 0, gradientBottomY);
                sharedGradient.addColorStop(0, barColorTop);
                sharedGradient.addColorStop(1, barColorBottom);

                ctx.fillStyle = sharedGradient;

                for (var i = 0; i < barCount; i++) {
                    var targetLeft = Math.max(0, Math.min(1, Audio.cava.values[i]));
                    displayValues[i] += (targetLeft - displayValues[i]) * smoothing;

                    var targetRight = Math.max(0, Math.min(1, Audio.cava.values[barCount - i - 1]));
                    displayValues[barCount + i] += (targetRight - displayValues[barCount + i]) * smoothing;
                }

                for (var i = 0; i < barCount * 2; i++) {
                    spatialValues[i] = spatialSmooth(i, displayValues, spatialRadius);
                }

                for (var i = 0; i < barCount; i++) {

                    // Left
                    var vLeft = spatialValues[i];
                    var xLeft = i * (width * 0.4 / barCount);
                    var hLeft = vLeft * height * 0.4;
                    var yLeft = height - hLeft;

                    if (hLeft > 0) {
                        drawRoundedRect(ctx, xLeft, yLeft, barWidth, hLeft, barRadius);
                        ctx.fill();
                    }

                    // Right
                    var vRight = spatialValues[barCount + i];
                    var xRight = width * 0.6 + i * (width * 0.4 / barCount);
                    var hRight = vRight * height * 0.4;
                    var yRight = height - hRight;

                    if (hRight > 0) {
                        drawRoundedRect(ctx, xRight, yRight, barWidth, hRight, barRadius);
                        ctx.fill();
                    }
                }
            }

            Timer {
                interval: 16
                running: true
                repeat: true
                onTriggered: canvas.requestPaint()
            }
        }
    }
}
