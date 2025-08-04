import qs.components
import qs.services
import qs.config
import qs.utils
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property real playerProgress: {
        const active = Players.active;
        return active?.length ? active.position / active.length : 0;
    }

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Config.dashboard.sizes.mediaWidth

    Behavior on playerProgress {
        NumberAnimation {
            duration: Appearance.anim.durations.large
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }

    Timer {
        running: Players.active?.isPlaying ?? false
        interval: Config.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    Shape {
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Colours.palette.m3surfaceContainerHigh
            strokeWidth: Config.dashboard.sizes.mediaProgressThickness
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: cover.x + cover.width / 2
                centerY: cover.y + cover.height / 2
                radiusX: (cover.width + Config.dashboard.sizes.mediaProgressThickness) / 2 + Appearance.spacing.small
                radiusY: (cover.height + Config.dashboard.sizes.mediaProgressThickness) / 2 + Appearance.spacing.small
                startAngle: -90 - Config.dashboard.sizes.mediaProgressSweep / 2
                sweepAngle: Config.dashboard.sizes.mediaProgressSweep
            }

            Behavior on strokeColor {
                ColorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Colours.palette.m3primary
            strokeWidth: Config.dashboard.sizes.mediaProgressThickness
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: cover.x + cover.width / 2
                centerY: cover.y + cover.height / 2
                radiusX: (cover.width + Config.dashboard.sizes.mediaProgressThickness) / 2 + Appearance.spacing.small
                radiusY: (cover.height + Config.dashboard.sizes.mediaProgressThickness) / 2 + Appearance.spacing.small
                startAngle: -90 - Config.dashboard.sizes.mediaProgressSweep / 2
                sweepAngle: Config.dashboard.sizes.mediaProgressSweep * root.playerProgress
            }

            Behavior on strokeColor {
                ColorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }
    }

    StyledClippingRect {
        id: cover

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Appearance.padding.large + Config.dashboard.sizes.mediaProgressThickness + Appearance.spacing.small

        implicitHeight: width
        color: Colours.palette.m3surfaceContainerHigh
        radius: Appearance.rounding.full

        MaterialIcon {
            anchors.centerIn: parent

            grade: 200
            text: "art_track"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: (parent.width * 0.4) || 1
        }

        Image {
            id: image

            anchors.fill: parent

            source: Players.active?.trackArtUrl ?? ""
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: width
            sourceSize.height: height
        }
    }

    StyledText {
        id: title

        anchors.top: cover.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Appearance.spacing.normal

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: (Players.active?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
        color: Colours.palette.m3primary
        font.pointSize: Appearance.font.size.normal

        width: parent.implicitWidth - Appearance.padding.large * 2
        elide: Text.ElideRight
    }

    StyledText {
        id: album

        anchors.top: title.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Appearance.spacing.small

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: (Players.active?.trackAlbum ?? qsTr("No media")) || qsTr("Unknown album")
        color: Colours.palette.m3outline
        font.pointSize: Appearance.font.size.small

        width: parent.implicitWidth - Appearance.padding.large * 2
        elide: Text.ElideRight
    }

    StyledText {
        id: artist

        anchors.top: album.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Appearance.spacing.small

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: (Players.active?.trackArtist ?? qsTr("No media")) || qsTr("Unknown artist")
        color: Colours.palette.m3secondary

        width: parent.implicitWidth - Appearance.padding.large * 2
        elide: Text.ElideRight
    }

    Row {
        id: controls

        anchors.top: artist.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Appearance.spacing.smaller

        spacing: Appearance.spacing.small

        Control {
            icon: "skip_previous"
            canUse: Players.active?.canGoPrevious ?? false

            function onClicked(): void {
                Players.active?.previous();
            }
        }

        Control {
            icon: Players.active?.isPlaying ? "pause" : "play_arrow"
            canUse: Players.active?.canTogglePlaying ?? false

            function onClicked(): void {
                Players.active?.togglePlaying();
            }
        }

        Control {
            icon: "skip_next"
            canUse: Players.active?.canGoNext ?? false

            function onClicked(): void {
                Players.active?.next();
            }
        }
    }

    AnimatedImage {
        id: bongocat

        anchors.top: controls.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Appearance.spacing.small
        anchors.bottomMargin: Appearance.padding.large
        anchors.margins: Appearance.padding.large * 2

        playing: Players.active?.isPlaying ?? false
        speed: BeatDetector.bpm / 300
        source: Paths.expandTilde(Config.paths.mediaGif)
        asynchronous: true
        fillMode: AnimatedImage.PreserveAspectFit
    }

    component Control: StyledRect {
        id: control

        required property string icon
        required property bool canUse
        function onClicked(): void {
        }

        implicitWidth: Math.max(icon.implicitHeight, icon.implicitHeight) + Appearance.padding.small
        implicitHeight: implicitWidth

        StateLayer {
            disabled: !control.canUse
            radius: Appearance.rounding.full

            function onClicked(): void {
                control.onClicked();
            }
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            anchors.verticalCenterOffset: font.pointSize * 0.05

            animate: true
            text: control.icon
            color: control.canUse ? Colours.palette.m3onSurface : Colours.palette.m3outline
            font.pointSize: Appearance.font.size.large
        }
    }
}
