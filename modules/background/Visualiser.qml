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
    property color barColorBottom: Qt.alpha(Colours.palette.m3inversePrimary, 0.7)

    // Rounded corner radius
    property real barRadius: Appearance.rounding.small * Config.background.visualiser.rounding

    // This loader was supposed to be for blur but i genuinley cant figure out how to stop it from desyncing with the canvas
    // Loader {
    //     anchors.fill: parent
    //     active: root.opacity > 0 && Config.background.visualiser.blur
    //     sourceComponent: MultiEffect {
    //         source: root.wallpaper
    //         maskSource: canvas
    //         maskEnabled: true
    //         blurEnabled: true
    //         blur: 1
    //         blurMax: 32
    //         autoPaddingEnabled: false
    //     }
    // }

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

                var gradientTopY = height * 0.7;
                var gradientBottomY = height;
                var sharedGradient = ctx.createLinearGradient(0, gradientTopY, 0, gradientBottomY);
                sharedGradient.addColorStop(0, barColorTop);
                sharedGradient.addColorStop(1, barColorBottom);

                ctx.fillStyle = sharedGradient;

                for (var i = 0; i < barCount; i++) {
                    // Left bar
                    var targetLeft = Math.max(0, Math.min(1, Audio.cava.values[i]));
                    displayValues[i] += (targetLeft - displayValues[i]) * smoothing;

                    var xLeft = i * (width * 0.4 / barCount);
                    var hLeft = displayValues[i] * height * 0.4;
                    var yLeft = height - hLeft;

                    drawRoundedRect(ctx, xLeft, yLeft, barWidth, hLeft, barRadius);
                    ctx.fill();

                    // Right bar
                    var targetRight = Math.max(0, Math.min(1, Audio.cava.values[barCount - i - 1]));
                    displayValues[barCount + i] += (targetRight - displayValues[barCount + i]) * smoothing;

                    var xRight = width * 0.6 + i * (width * 0.4 / barCount);
                    var hRight = displayValues[barCount + i] * height * 0.4;
                    var yRight = height - hRight;

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
