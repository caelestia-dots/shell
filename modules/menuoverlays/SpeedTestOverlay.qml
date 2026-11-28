pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.services

// Ported from omarchy's Ui_SpeedTestOverlay: gauges sit on a dark translucent
// card. Two surfaces keep the blur scoped to the card only: a fullscreen
// catcher takes the keyboard and outside clicks (never blurred), while the
// card itself is its own layer surface, so the blur rule can only ever apply
// behind it.
Item {
    id: root

    required property bool running
    required property string leftLabel
    required property string rightLabel

    property string unit: "Mbps"
    property string title: ""
    property string layerNamespace: "caelestia-menu-speed-test"
    property string runAgainTooltip: "Measure again"
    property real leftValue: 0
    property real rightValue: 0
    property bool leftLive: false
    property bool rightLive: false
    property string error: ""
    property bool open: false

    // Stacking: how many overlays are open in total and this card's vertical
    // rank (0 = top). The coordinator in MenuOverlays supplies these, and also
    // a ready-made vertical-center fraction that keeps the cards apart.
    property int stackCount: 1
    property int stackRank: 0
    property real stackCenter: 0.5

    // Full-scale latch points for the dials, smallest first.
    property var scaleStops: [100, 250, 500, 1000, 2500, 5000, 10000]
    property real fullScale: scaleStops[0]

    // Card entrance: 0 -> 1 on open, so each card fades and pops into its
    // slot rather than sliding in from off-screen.
    property real pop: 0

    readonly property bool failed: error !== ""
    readonly property color onScrim: "white"
    readonly property color onScrimDim: Qt.rgba(1, 1, 1, 0.55)
    readonly property color onScrimUrgent: "#ff6b6b"
    readonly property color accent: Colours.palette.m3primary
    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    signal closeRequested
    signal runAgainRequested

    function resetScale() {
        fullScale = scaleStops[0];
    }

    function expandScale(value) {
        for (let i = 0; i < scaleStops.length; i++) {
            if (value <= scaleStops[i] * 0.92) {
                if (scaleStops[i] > fullScale)
                    fullScale = scaleStops[i];
                return;
            }
        }
        fullScale = scaleStops[scaleStops.length - 1];
    }

    onRunningChanged: if (running)
        resetScale()
    onLeftValueChanged: expandScale(leftValue)
    onRightValueChanged: expandScale(rightValue)

    onOpenChanged: {
        if (open) {
            pop = 0;
            Qt.callLater(function () {
                if (!root.open)
                    return;
                pop = 1;
                keyCatcher.forceActiveFocus();
                leftDial.ignite();
                rightDial.ignite();
            });
        }
    }

    // qmllint disable uncreatable-type
    PanelWindow {
        // qmllint enable uncreatable-type
        id: catcher

        visible: root.open
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: root.layerNamespace
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Item {
            id: keyCatcher

            anchors.fill: parent
            focus: true

            Keys.onEscapePressed: root.closeRequested()
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Q)
                    root.closeRequested();
            }
            Keys.onReturnPressed: if (!root.running)
                root.runAgainRequested()
            Keys.onEnterPressed: if (!root.running)
                root.runAgainRequested()

            MouseArea {
                anchors.fill: parent
                onClicked: root.closeRequested()
            }
        }
    }

    // qmllint disable uncreatable-type
    PanelWindow {
        // qmllint enable uncreatable-type
        id: cardWindow

        visible: root.open
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: root.layerNamespace + "-card"
        WlrLayershell.layer: WlrLayer.Overlay

        // Anchoring only the top and left edges keeps the surface at the
        // requested card size (anchoring opposite edges would stretch it to
        // fill the screen minus margins). The margins then place the card and
        // pack it toward the top/bottom of the center as other overlay cards
        // open or close.
        anchors {
            top: true
            left: true
        }

        implicitWidth: card.width
        implicitHeight: card.height

        // qmllint disable unresolved-type unqualified missing-property
        // Window's grouped `margins` value type sometimes fails to resolve
        // after Quickshell's opaque Margins type has been loaded by another
        // file; the properties exist and work at runtime.
        margins.left: Math.max(0, Math.round((screen.width - card.width) / 2))
        margins.top: Math.max(0, Math.round((screen.height - card.height) / 2 + (root.stackCenter - 0.5) * screen.height))

        Behavior on margins.top {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
        // qmllint enable unresolved-type unqualified missing-property

        Rectangle {
            id: card

            radius: 20
            color: Qt.rgba(0.15, 0.15, 0.17, 0.6)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            opacity: root.pop
            scale: root.pop

            width: content.implicitWidth + 48
            height: content.implicitHeight + 40

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutBack
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                id: content

                spacing: 16

                anchors {
                    fill: parent
                    topMargin: 20
                    bottomMargin: 20
                    leftMargin: 24
                    rightMargin: 24
                }

                Text {
                    visible: root.title !== ""
                    text: root.title.toUpperCase()
                    color: root.onScrimDim
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 2
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Row {
                    spacing: 48
                    Layout.alignment: Qt.AlignHCenter

                    SpeedDial {
                        id: leftDial

                        label: root.leftLabel
                        value: root.leftValue
                        live: root.leftLive
                    }

                    SpeedDial {
                        id: rightDial

                        label: root.rightLabel
                        value: root.rightValue
                        live: root.rightLive
                    }
                }

                Text {
                    visible: root.failed
                    text: root.error
                    color: root.onScrimUrgent
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    Layout.maximumWidth: 440
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    component SpeedDial: Item {
        id: dial

        required property string label
        required property real value
        required property bool live

        readonly property real diameter: 210
        readonly property real dialStart: 135
        readonly property real dialSweep: 270
        readonly property int tickCount: 46
        readonly property real arcWidth: 4
        readonly property real arcRadius: diameter / 2 - arcWidth
        readonly property color trackColor: Qt.rgba(1, 1, 1, 0.14)
        readonly property color minorTickColor: Qt.rgba(1, 1, 1, 0.12)
        readonly property color majorTickColor: Qt.rgba(1, 1, 1, 0.3)
        readonly property bool engaged: live || value > 0

        property real shown: 0
        readonly property real reading: ignition.running ? value : shown
        readonly property real fullScale: root.fullScale
        readonly property real fraction: fullScale > 0 ? Math.max(0, Math.min(1, shown / fullScale)) : 0
        readonly property bool arcVisible: fraction > 0.004

        function ignite() {
            ignition.restart();
        }

        width: diameter
        height: diameter
        opacity: engaged ? 1 : 0.5

        onValueChanged: {
            if (!ignition.running)
                shown = value;
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutCubic
            }
        }

        Behavior on shown {
            enabled: !ignition.running

            NumberAnimation {
                duration: 600
                easing.type: Easing.OutCubic
            }
        }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: dial.arcWidth
                strokeColor: dial.trackColor
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: dial.width / 2
                    centerY: dial.height / 2
                    radiusX: dial.arcRadius
                    radiusY: dial.arcRadius
                    startAngle: dial.dialStart
                    sweepAngle: dial.dialSweep
                }
            }

            ShapePath {
                strokeWidth: dial.arcWidth * 3
                strokeColor: dial.arcVisible ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18) : "transparent"
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: dial.width / 2
                    centerY: dial.height / 2
                    radiusX: dial.arcRadius
                    radiusY: dial.arcRadius
                    startAngle: dial.dialStart
                    sweepAngle: dial.dialSweep * dial.fraction
                }
            }

            ShapePath {
                strokeWidth: dial.arcWidth
                strokeColor: dial.arcVisible ? root.accent : "transparent"
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: dial.width / 2
                    centerY: dial.height / 2
                    radiusX: dial.arcRadius
                    radiusY: dial.arcRadius
                    startAngle: dial.dialStart
                    sweepAngle: dial.dialSweep * dial.fraction
                }
            }
        }

        Repeater {
            model: dial.tickCount

            Item {
                id: tickItem

                required property int index

                readonly property bool major: index % 5 === 0

                anchors.fill: parent
                rotation: dial.dialStart + (index / (dial.tickCount - 1)) * dial.dialSweep - 270

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: dial.arcWidth * 2 + (tickItem.major ? 0 : 2)
                    width: tickItem.major ? 2 : 1
                    height: tickItem.major ? 10 : 6
                    radius: width / 2
                    color: tickItem.major ? dial.majorTickColor : dial.minorTickColor
                }
            }
        }

        Item {
            anchors.fill: parent
            rotation: dial.dialStart + dial.fraction * dial.dialSweep - 270

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: dial.arcWidth * 2 + 10
                width: 3
                height: dial.diameter * 0.32
                radius: width / 2

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: root.accent
                    }

                    GradientStop {
                        position: 0.55
                        color: root.accent
                    }

                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.verticalCenter
            anchors.topMargin: 14
            spacing: 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: dial.reading < 10 ? dial.reading.toLocaleString(Qt.locale(), 'f', 1) : Math.round(dial.reading).toLocaleString(Qt.locale(), 'f', 0)
                color: root.onScrim
                font.family: root.fontFamily
                font.pixelSize: 32
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.unit
                color: root.onScrimDim
                font.family: root.fontFamily
                font.pixelSize: 12
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: dial.label
            // Accent when this dial's phase has finished (a reading landed and
            // it is no longer the live phase), dim while it is measuring or
            // has not run yet. Each dial is independent.
            color: (dial.value > 0 && !dial.live) ? root.accent : root.onScrimDim
            font.family: root.fontFamily
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 1.5
        }

        SequentialAnimation {
            id: ignition

            onFinished: dial.shown = dial.value

            NumberAnimation {
                target: dial
                property: "shown"
                to: dial.fullScale
                duration: 550
                easing.type: Easing.InOutCubic
            }

            NumberAnimation {
                target: dial
                property: "shown"
                to: 0
                duration: 650
                easing.type: Easing.OutCubic
            }
        }
    }
}
