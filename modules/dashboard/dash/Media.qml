pragma ComponentBehavior: Bound

import qs.components
import qs.components.misc
import qs.components.controls
import qs.services
import qs.config
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

Item {
    id: root

    property real playerProgress: {
        const active = Players.active;
        return active?.length ? active.position / active.length : 0;
    }

    function lengthStr(length: int): string {
        if (length < 0)
            return "-1:-1";

        const hours = Math.floor(length / 3600);
        const mins = Math.floor((length % 3600) / 60);
        const secs = Math.floor(length % 60).toString().padStart(2, "0");

        if (hours > 0)
            return `${hours}:${mins.toString().padStart(2, "0")}:${secs}`;
        return `${mins}:${secs}`;
    }

    implicitWidth: 280
    implicitHeight: 160

    Timer {
        running: Players.active?.isPlaying ?? false
        interval: Config.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    Ref {
        service: Cava
    }

    // Mini audio visualizer
    Shape {
        id: visualiser

        readonly property real centerX: width / 2
        readonly property real centerY: height / 2
        readonly property real innerX: cover.implicitWidth / 2 + Appearance.spacing.small
        readonly property real innerY: cover.implicitHeight / 2 + Appearance.spacing.small

        anchors.fill: cover
        anchors.margins: -20  // Smaller visualizer margin for mini version

        preferredRendererType: Shape.CurveRenderer
    }

    Repeater {
        id: visualiserBars
        model: 24  // Fewer bars for mini version

        ShapePath {
            id: visualiserBar

            readonly property int value: Math.max(1, Math.min(100, Cava.values[index] || 0))
            readonly property real angle: index * 2 * Math.PI / 24
            readonly property real magnitude: value / 100 * 20  // Smaller magnitude
            readonly property real cos: Math.cos(angle)
            readonly property real sin: Math.sin(angle)

            capStyle: ShapePath.RoundCap
            strokeWidth: 360 / 24 - Appearance.spacing.small / 4
            strokeColor: Colours.palette.m3primary

            startX: visualiser.centerX + (visualiser.innerX + strokeWidth / 2) * cos
            startY: visualiser.centerY + (visualiser.innerY + strokeWidth / 2) * sin

            PathLine {
                x: visualiser.centerX + (visualiser.innerX + visualiserBar.strokeWidth / 2 + visualiserBar.magnitude) * visualiserBar.cos
                y: visualiser.centerY + (visualiser.innerY + visualiserBar.strokeWidth / 2 + visualiserBar.magnitude) * visualiserBar.sin
            }

            Behavior on strokeColor {
                ColorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }

            Component.onCompleted: {
                visualiser.data.push(this)
            }
        }
    }

    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: parent.height * 0.1
        spacing: Appearance.spacing.normal

        // Album cover with visualizer
        Item {
            Layout.preferredWidth: 80
            Layout.preferredHeight: 80

            StyledClippingRect {
                id: cover

                anchors.centerIn: parent
                implicitWidth: 60
                implicitHeight: 60

                color: Colours.tPalette.m3surfaceContainerHigh
                radius: Infinity

                MaterialIcon {
                    anchors.centerIn: parent
                    grade: 200
                    text: "art_track"
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: 24
                }

                Image {
                    anchors.fill: parent
                    source: Players.active?.trackArtUrl ?? ""
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: width
                    sourceSize.height: height
                }
            }
        }

        // Song details and controls
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.smaller

            // Song info
            StyledText {
                Layout.fillWidth: true
                Layout.maximumWidth: 150
                text: (Players.active?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
                color: Players.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                Layout.maximumWidth: 150
                text: (Players.active?.trackArtist ?? qsTr("No artist")) || qsTr("Unknown artist")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.smaller
                elide: Text.ElideRight
            }

            // Controls
            RowLayout {
                Layout.alignment: Qt.AlignLeft
                spacing: Appearance.spacing.smaller

                PlayerControl {
                    icon: "skip_previous"
                    canUse: Players.active?.canGoPrevious ?? false

                    function onClicked(): void {
                        Players.active?.previous();
                    }
                }

                PlayerControl {
                    icon: Players.active?.isPlaying ? "pause" : "play_arrow"
                    canUse: Players.active?.canTogglePlaying ?? false
                    primary: true

                    function onClicked(): void {
                        Players.active?.togglePlaying();
                    }
                }

                PlayerControl {
                    icon: "skip_next"
                    canUse: Players.active?.canGoNext ?? false

                    function onClicked(): void {
                        Players.active?.next();
                    }
                }
            }

            // Progress slider
            StyledSlider {
                Layout.fillWidth: true
                Layout.maximumWidth: 120
                enabled: !!Players.active
                implicitHeight: Appearance.padding.small

                value: root.playerProgress
                onMoved: {
                    const active = Players.active;
                    if (active?.canSeek && active?.positionSupported)
                        active.position = value * active.length;
                }
            }

            // Time display
            StyledText {
                Layout.alignment: Qt.AlignLeft
                text: `${root.lengthStr(Players.active?.position ?? -1)} / ${root.lengthStr(Players.active?.length ?? -1)}`
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.smaller
            }
        }
    }

    component PlayerControl: StyledRect {
        id: control

        required property string icon
        required property bool canUse
        property bool primary: false

        function onClicked(): void {
        }

        implicitWidth: 28
        implicitHeight: 28
        radius: Appearance.rounding.full
        color: primary && Players.active?.isPlaying ? 
               Colours.palette.m3primary : 
               Colours.tPalette.m3surfaceContainer

        StateLayer {
            disabled: !control.canUse
            color: primary && Players.active?.isPlaying ? 
                   Colours.palette.m3onPrimary : 
                   Colours.palette.m3onSurface

            function onClicked(): void {
                control.onClicked();
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: control.icon
            color: primary && Players.active?.isPlaying ? 
                   Colours.palette.m3onPrimary : 
                   (control.canUse ? Colours.palette.m3onSurface : Colours.palette.m3outline)
            font.pointSize: Appearance.font.size.small
        }
    }
}