pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

// Gauge overlay card for live network and disk speed measurements.
// Adapted from Omarchy's SpeedTestOverlay (MIT License) and themed to Caelestia.
// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: root

    required property bool running
    required property string leftLabel
    required property string rightLabel
    property string unit: "Mbps"
    property string title: ""
    property string layerNamespace: "caelestia-menu-speed-test"
    property string runAgainTooltip: Tr.tr("Measure again")
    property real leftValue: 0
    property real rightValue: 0
    property bool leftLive: false
    property bool rightLive: false
    property string error: ""
    property bool open: false

    property int stackCount: 1
    property int stackRank: 0
    property real stackCenter: 0.5

    property var scaleStops: [100, 250, 500, 1000, 2500, 5000, 10000]
    property real fullScale: scaleStops[0]
    property real pop: 0

    readonly property bool failed: error !== ""
    readonly property color onCard: Colours.palette.m3onSurface
    readonly property color onCardDim: Colours.palette.m3onSurfaceVariant
    readonly property color onCardUrgent: Colours.palette.m3error
    readonly property color accent: Colours.palette.m3primary

    signal closeRequested
    signal runAgainRequested

    function resetScale(): void {
        fullScale = scaleStops[0];
    }

    function expandScale(value: real): void {
        for (let i = 0; i < scaleStops.length; i++) {
            if (value <= scaleStops[i] * 0.92) {
                if (scaleStops[i] > fullScale)
                    fullScale = scaleStops[i];
                return;
            }
        }
        fullScale = scaleStops[scaleStops.length - 1];
    }

    visible: open
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

    onRunningChanged: {
        if (running)
            resetScale();
    }
    onLeftValueChanged: expandScale(leftValue)
    onRightValueChanged: expandScale(rightValue)
    onOpenChanged: {
        if (open) {
            pop = 0;
            Qt.callLater(() => {
                if (!root.open)
                    return;
                pop = 1;
                keyCatcher.forceActiveFocus();
                leftDial.ignite();
                rightDial.ignite();
            });
        }
    }

    Behavior on fullScale {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutCubic
        }
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
        Keys.onReturnPressed: {
            if (!root.running)
                root.runAgainRequested();
        }
        Keys.onEnterPressed: {
            if (!root.running)
                root.runAgainRequested();
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }

        StyledRect {
            id: card

            radius: Tokens.rounding.extraLarge
            color: Colours.tPalette.m3surfaceContainer
            border.color: Colours.palette.m3outlineVariant
            border.width: 1

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: (root.stackCenter - 0.5) * parent.height

            opacity: root.pop
            scale: root.pop * Math.min(1, (keyCatcher.width - 32) / Math.max(1, width), (keyCatcher.height - 32) / Math.max(1, height))

            width: content.implicitWidth + 48
            height: content.implicitHeight + 40

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutBack
                }
            }

            Behavior on anchors.verticalCenterOffset {
                Anim {}
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                id: content

                spacing: Tokens.spacing.large

                anchors {
                    fill: parent
                    topMargin: 20
                    bottomMargin: 20
                    leftMargin: 24
                    rightMargin: 24
                }

                StyledText {
                    visible: root.title !== ""
                    text: root.title.toUpperCase()
                    color: root.onCardDim
                    font: Tokens.font.mono.builders.small.weight(Font.Bold).letterSpacing(2).build()
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

                StyledText {
                    visible: root.failed
                    text: root.error
                    color: root.onCardUrgent
                    font: Tokens.font.body.small
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
        readonly property color trackColor: Qt.alpha(Colours.palette.m3onSurface, 0.14)
        readonly property color minorTickColor: Qt.alpha(Colours.palette.m3onSurface, 0.12)
        readonly property color majorTickColor: Qt.alpha(Colours.palette.m3onSurface, 0.3)
        readonly property bool engaged: live || value > 0

        property real shown: 0
        readonly property real reading: ignition.running ? value : shown
        readonly property real fullScale: root.fullScale
        readonly property real fraction: fullScale > 0 ? Math.max(0, Math.min(1, shown / fullScale)) : 0
        readonly property bool arcVisible: fraction > 0.004

        function ignite(): void {
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
                strokeColor: dial.arcVisible ? Qt.alpha(root.accent, 0.18) : "transparent"
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

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: dial.reading < 10 ? dial.reading.toLocaleString(Qt.locale(), 'f', 1) : Math.round(dial.reading).toLocaleString(Qt.locale(), 'f', 0)
                color: root.onCard
                font: Tokens.font.mono.builders.large.scale(2.2).weight(Font.Bold).build()
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.unit
                color: root.onCardDim
                font: Tokens.font.mono.small
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: dial.label
            color: (dial.value > 0 && !dial.live) ? root.accent : root.onCardDim
            font: Tokens.font.mono.builders.small.weight(Font.Bold).letterSpacing(1.5).build()
        }
    }
}
