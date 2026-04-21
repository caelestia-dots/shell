import QtQuick
import QtQuick.Shapes
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    property real playerProgress: {
        const active = Players.active;
        return active?.length ? (active.position % active.length) / active.length : 0;
    }

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Tokens.sizes.dashboard.mediaWidth

    Behavior on playerProgress {
        Anim {
            type: Anim.StandardLarge
        }
    }

    Timer {
        running: Players.active?.isPlaying ?? false
        interval: GlobalConfig.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    ServiceRef {
        service: Audio.beatTracker
    }

    Shape {
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
            strokeWidth: root.Tokens.sizes.dashboard.mediaProgressThickness
            capStyle: root.Tokens.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap

            PathAngleArc {
                centerX: cover.x + cover.width / 2
                centerY: cover.y + cover.height / 2
                radiusX: (cover.width + root.Tokens.sizes.dashboard.mediaProgressThickness) / 2 + root.Tokens.spacing.small
                radiusY: (cover.height + root.Tokens.sizes.dashboard.mediaProgressThickness) / 2 + root.Tokens.spacing.small
                startAngle: -90 - root.Tokens.sizes.dashboard.mediaProgressSweep / 2
                sweepAngle: root.Tokens.sizes.dashboard.mediaProgressSweep
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Colours.palette.m3primary
            strokeWidth: root.Tokens.sizes.dashboard.mediaProgressThickness
            capStyle: root.Tokens.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap

            PathAngleArc {
                centerX: cover.x + cover.width / 2
                centerY: cover.y + cover.height / 2
                radiusX: (cover.width + root.Tokens.sizes.dashboard.mediaProgressThickness) / 2 + root.Tokens.spacing.small
                radiusY: (cover.height + root.Tokens.sizes.dashboard.mediaProgressThickness) / 2 + root.Tokens.spacing.small
                startAngle: -90 - root.Tokens.sizes.dashboard.mediaProgressSweep / 2
                sweepAngle: root.Tokens.sizes.dashboard.mediaProgressSweep * root.playerProgress
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }
    }

    StyledClippingRect {
        id: cover

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large + Tokens.sizes.dashboard.mediaProgressThickness + Tokens.spacing.small

        implicitHeight: width
        color: Colours.tPalette.m3surfaceContainerHigh
        radius: Infinity

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

            source: Players.getArtUrl(Players.active)
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
        anchors.topMargin: Tokens.spacing.normal

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: (Players.active?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
        color: Colours.palette.m3primary
        font.pointSize: Tokens.font.size.normal

        width: parent.implicitWidth - Tokens.padding.large * 2
        elide: Text.ElideRight
    }

    StyledText {
        id: album

        anchors.top: title.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Tokens.spacing.small

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: (Players.active?.trackAlbum ?? qsTr("No media")) || qsTr("Unknown album")
        color: Colours.palette.m3outline
        font.pointSize: Tokens.font.size.small

        width: parent.implicitWidth - Tokens.padding.large * 2
        elide: Text.ElideRight
    }

    StyledText {
        id: artist

        anchors.top: album.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Tokens.spacing.small

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: (Players.active?.trackArtist ?? qsTr("No media")) || qsTr("Unknown artist")
        color: Colours.palette.m3secondary

        width: parent.implicitWidth - Tokens.padding.large * 2
        elide: Text.ElideRight
    }

    Row {
        id: controls

        anchors.top: artist.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Tokens.spacing.smaller

        spacing: Tokens.spacing.small

        PlayerControl {
            icon: "skip_previous"
            canUse: Players.active?.canGoPrevious ?? false
            onClicked: Players.active?.previous()
        }

        PlayerControl {
            icon: Players.active?.isPlaying ? "pause" : "play_arrow"
            canUse: Players.active?.canTogglePlaying ?? false
            onClicked: Players.active?.togglePlaying()
        }

        PlayerControl {
            icon: "skip_next"
            canUse: Players.active?.canGoNext ?? false
            onClicked: Players.active?.next()
        }
    }

    AnimatedImage {
        id: bongocat

        anchors.top: controls.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Tokens.spacing.small
        anchors.bottomMargin: Tokens.padding.large
        anchors.margins: Tokens.padding.large * 2

        playing: Players.active?.isPlaying ?? false
        speed: Audio.beatTracker.bpm / Config.general.mediaGifSpeedAdjustment // qmllint disable unresolved-type
        source: Paths.absolutePath(Config.paths.mediaGif)
        asynchronous: true
        fillMode: AnimatedImage.PreserveAspectFit
    }

    component PlayerControl: StyledRect {
        id: control

        required property string icon
        required property bool canUse

        signal clicked

        implicitWidth: Math.max(icon.implicitHeight, icon.implicitHeight) + Tokens.padding.small
        implicitHeight: implicitWidth

        StateLayer {
            disabled: !control.canUse
            radius: Tokens.rounding.full
            onClicked: control.clicked()
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            anchors.verticalCenterOffset: font.pointSize * 0.05

            animate: true
            text: control.icon
            color: control.canUse ? Colours.palette.m3onSurface : Colours.palette.m3outline
            font.pointSize: Tokens.font.size.large
        }
    }
}
