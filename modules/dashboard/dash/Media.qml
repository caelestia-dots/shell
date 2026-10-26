pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.components.widgets
import qs.services
import qs.utils

Item {
    id: root

    property real playerProgress: {
        const active = Players.active;
        return active?.length ? (active.position % active.length) / active.length : 0;
    }

    readonly property real arcCoverGap: Tokens.spacing.extraSmall
    readonly property bool hasMediaGif: Config.paths.mediaGif.trim() !== ""
    readonly property real coverInset: Tokens.padding.medium + root.arcCoverGap + prog.thickness

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

    Column {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: Tokens.spacing.medium

        // With media gif, keep the block top-aligned so the gif can fill the bottom.
        states: State {
            when: root.hasMediaGif

            AnchorChanges {
                target: content
                anchors.verticalCenter: undefined
                anchors.top: root.top
            }
            PropertyChanges {
                content.anchors.topMargin: Tokens.padding.small
            }
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - root.coverInset * 2
            height: width

            CircularProgress {
                id: prog

                anchors.centerIn: cover
                implicitSize: cover.width + root.arcCoverGap + thickness * 2

                fgColour: Colours.palette.m3primary
                strokeWidth: Tokens.sizes.dashboard.mediaProgressThickness
                startAngle: -90 - sweepAngle / 2
                sweepAngle: Tokens.sizes.dashboard.mediaProgressSweep
                value: root.playerProgress

                wavy: true
                waveFrequency: 8
                waveDuration: 2000
                wavePaused: !Players.active?.isPlaying
            }

            CoverArt {
                id: cover

                anchors.fill: parent
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - Tokens.padding.extraLargeIncreased
            spacing: Tokens.spacing.small

            StyledText {
                id: title

                width: parent.width
                animate: true
                horizontalAlignment: Text.AlignHCenter
                text: (Players.active?.trackTitle ?? Tr.tr("No media")) || Tr.tr("Unknown title")
                color: Colours.palette.m3primary
                font: Tokens.font.title.small
                elide: Text.ElideRight
            }

            StyledText {
                id: album

                width: parent.width
                animate: true
                horizontalAlignment: Text.AlignHCenter
                text: (Players.active?.trackAlbum ?? Tr.tr("No media")) || Tr.tr("Unknown album")
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                id: artist

                width: parent.width
                animate: true
                horizontalAlignment: Text.AlignHCenter
                text: (Players.active?.trackArtist ?? Tr.tr("No media")) || Tr.tr("Unknown artist")
                color: Colours.palette.m3secondary
                elide: Text.ElideRight
            }
        }

        ButtonRow {
            id: controls

            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - Tokens.padding.large * 2
            spacing: Tokens.spacing.extraSmall

            IconButton {
                type: IconButton.Tonal
                icon: "skip_previous"
                isRound: true
                shapeMorph: true
                disabled: !Players.active?.canGoPrevious
                onClicked: Players.active?.previous()
            }

            IconButton {
                fillWidth: true
                icon: Players.active?.isPlaying ? "pause" : "play_arrow"
                isRound: true
                shapeMorph: true
                checked: Players.active?.isPlaying ?? false
                disabled: !Players.active?.canTogglePlaying
                onClicked: Players.active?.togglePlaying()
            }

            IconButton {
                type: IconButton.Tonal
                icon: "skip_next"
                isRound: true
                shapeMorph: true
                disabled: !Players.active?.canGoNext
                onClicked: Players.active?.next()
            }
        }
    }

    Loader {
        active: root.hasMediaGif
        anchors.top: content.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Tokens.spacing.small
        anchors.bottomMargin: Tokens.padding.large
        anchors.margins: Tokens.padding.extraLargeIncreased

        sourceComponent: AnimatedImage {
            anchors.fill: parent
            playing: Players.active?.isPlaying ?? false
            speed: Audio.beatTracker.bpm / Config.general.mediaGifSpeedAdjustment
            source: Paths.absolutePath(Config.paths.mediaGif)
            asynchronous: true
            fillMode: AnimatedImage.PreserveAspectFit
        }
    }
}
