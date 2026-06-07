import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

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

    spacing: Tokens.spacing.extraSmall

    Timer {
        running: Players.active?.isPlaying ?? false
        interval: GlobalConfig.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    StyledText {
        Layout.fillWidth: true
        text: Players.active?.trackTitle ?? ""
        font: Tokens.font.title.large
        elide: Text.ElideRight
        animate: true
    }

    StyledText {
        Layout.fillWidth: true
        text: Players.active?.trackArtist || qsTr("Unknown artist")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.title.medium
        elide: Text.ElideRight
        animate: true
    }

    StyledText {
        Layout.fillWidth: true
        text: Players.active?.trackAlbum || qsTr("Unknown album")
        color: Colours.palette.m3secondary
        font: Tokens.font.title.medium
        elide: Text.ElideRight
        animate: true
    }

    RowLayout {
        Layout.topMargin: Tokens.spacing.extraLargeIncreased
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        TextMetrics {
            id: timeMetrics

            text: Players.active ? root.lengthStr(Math.max(Players.active.position, Players.active.length)).replace(/[1-9]/g, "0") : "00:00"
            font: Tokens.font.label.medium
        }

        StyledText {
            Layout.preferredWidth: timeMetrics.width
            text: root.lengthStr(Players.active?.position ?? -1)
            color: Colours.palette.m3onSurfaceVariant
            font: timeMetrics.font
            horizontalAlignment: Text.AlignHCenter
        }

        StyledSlider {
            Layout.fillWidth: true
            value: Players.active ? Players.active.position / (Players.active.length || 1) : 0
            enabled: Players.active?.canSeek ?? false
            wavy: true
            animateWave: Players.active?.isPlaying ?? false
            waveFrequency: 5
            waveDuration: 2000
            onInteraction: value => {
                const active = Players.active;
                if (active?.canSeek && active?.positionSupported)
                    active.position = value * active.length;
            }
        }

        StyledText {
            Layout.preferredWidth: timeMetrics.width
            text: root.lengthStr(Players.active?.length ?? -1)
            color: Colours.palette.m3onSurfaceVariant
            font: timeMetrics.font
            horizontalAlignment: Text.AlignHCenter
        }
    }

    ButtonRow {
        Layout.topMargin: Tokens.spacing.largeIncreased
        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall

        IconButton {
            type: IconButton.Tonal
            icon: "shuffle"
            isRound: true
            shapeMorph: true
            checked: Players.active?.shuffle ?? false
            font: Tokens.font.icon.builders.medium.weight(Font.Medium).build()
            disabled: !Players.active?.shuffleSupported
            onClicked: Players.active.shuffle = !Players.active?.shuffle
            implicitWidth: Math.round(implicitHeight * 0.9)
        }

        IconButton {
            id: previousBtn

            type: IconButton.Tonal
            icon: "skip_previous"
            isRound: true
            shapeMorph: true
            font: Tokens.font.icon.large
            disabled: !Players.active?.canGoPrevious
            onClicked: Players.active?.previous()
        }

        IconButton {
            id: playPauseBtn

            icon: Players.active?.isPlaying ? "pause" : "play_arrow"
            isRound: true
            shapeMorph: true
            fillWidth: true
            checked: Players.active?.isPlaying ?? false
            font: Tokens.font.icon.large
            disabled: !Players.active?.canTogglePlaying
            onClicked: Players.active?.togglePlaying()
        }

        IconButton {
            id: nextBtn

            type: IconButton.Tonal
            icon: "skip_next"
            isRound: true
            shapeMorph: true
            font: Tokens.font.icon.large
            disabled: !Players.active?.canGoNext
            onClicked: Players.active?.next()
        }

        IconButton {
            type: IconButton.Tonal
            icon: Players.active?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
            isRound: true
            shapeMorph: true
            checked: Players.active?.loopState === MprisLoopState.Track || Players.active?.loopState === MprisLoopState.Playlist
            font: Tokens.font.icon.builders.medium.weight(Font.Medium).build()
            disabled: !Players.active?.loopSupported
            onClicked: {
                const state = Players.active.loopState;
                if (state === MprisLoopState.None)
                    Players.active.loopState = MprisLoopState.Track;
                else if (state === MprisLoopState.Track)
                    Players.active.loopState = MprisLoopState.Playlist;
                else
                    Players.active.loopState = MprisLoopState.None;
            }
            implicitWidth: Math.round(implicitHeight * 0.9)
        }
    }
}
