pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Caelestia.Services
import Quickshell
import QtQuick
import QtQuick.Effects

Item {
    id: root
    anchors.fill: parent

    required property ShellScreen screen
    required property Wallpaper wallpaper

    readonly property bool shouldBeActive: Config.background.visualiser.enabled && (!Config.background.visualiser.autoHide || Hypr.monitorFor(screen).activeWorkspace.toplevels.values.every(t => t.lastIpcObject.floating))

    property real offset: shouldBeActive ? 0 : screen.height * 0.2
    opacity: shouldBeActive ? 1 : 0

    Behavior on offset {
        Anim {}
    }
    Behavior on opacity {
        Anim {}
    }

    // Keep Audio service alive
    ServiceRef {
        id: cavaRef
        service: Audio.cava
    }

    // Bar gradient colors
    property color barColorTop: Qt.alpha(Colours.palette.m3primary, 1)
    property color barColorBottom: Qt.alpha(Colours.palette.m3inversePrimary, 0.8)

    // Rounded corner radius
    property real barRadius: Appearance.rounding.small * Config.background.visualiser.rounding

    // MultiEffect blur
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        maskSource: canvasWrapper
        maskEnabled: true
        blurEnabled: Config.background.visualiser.blur
        blur: 1
        blurMax: Math.min(16, Config.background.visualiser.blurMax)
        autoPaddingEnabled: false
    }

    Item {
        id: canvasWrapper
        anchors.fill: parent
        y: offset
        height: parent.height - offset * 2

        Canvas {
            id: canvas
            anchors.fill: parent
            property int barCount: Config.services.visualiserBars
            property real spacing: Appearance.spacing.small * Config.background.visualiser.spacing
            property real barWidth: (width * 0.4 / barCount) - spacing

            // Animated display values
            property var displayValues: Array(barCount * 2).fill(0)

            property real smoothing: Math.max(0.01, Math.min(1, 32 / Appearance.anim.durations.small))

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

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (!Audio.cava.values)
                    return;

                for (var i = 0; i < barCount; i++) {
                    // Left bar
                    var targetLeft = Math.max(0, Math.min(1, Audio.cava.values[i]));
                    displayValues[i] += (targetLeft - displayValues[i]) * smoothing;

                    var xLeft = i * (width * 0.4 / barCount);
                    var hLeft = displayValues[i] * height * 0.4;
                    var yLeft = height - hLeft;

                    var gradLeft = ctx.createLinearGradient(0, yLeft, 0, height);
                    gradLeft.addColorStop(0, barColorTop);
                    gradLeft.addColorStop(1, barColorBottom);
                    ctx.fillStyle = gradLeft;

                    drawRoundedRect(ctx, xLeft, yLeft, barWidth, hLeft, barRadius);
                    ctx.fill();

                    // Right bar
                    var targetRight = Math.max(0, Math.min(1, Audio.cava.values[barCount - i - 1]));
                    displayValues[barCount + i] += (targetRight - displayValues[barCount + i]) * smoothing;

                    var xRight = width * 0.6 + i * (width * 0.4 / barCount);
                    var hRight = displayValues[barCount + i] * height * 0.4;
                    var yRight = height - hRight;

                    var gradRight = ctx.createLinearGradient(0, yRight, 0, height);
                    gradRight.addColorStop(0, barColorTop);
                    gradRight.addColorStop(1, barColorBottom);
                    ctx.fillStyle = gradRight;

                    drawRoundedRect(ctx, xRight, yRight, barWidth, hRight, barRadius);
                    ctx.fill();
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
