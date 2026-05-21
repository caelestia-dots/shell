import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.services

Item {
    id: root

    property string path
    property var screen
    property bool isFirstInstance: false

    property alias playing: mediaPlayer.playing
    property alias playbackState: mediaPlayer.playbackState

    AudioOutput {
        id: audioOutput
    }

    MediaPlayer {
        id: mediaPlayer

        source: path || ""
        videoOutput: videoOutput
        loops: MediaPlayer.Infinite
        autoPlay: true
        audioOutput: audioOutput
    }

    VideoOutput {
        id: videoOutput

        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop

        Component.onDestruction: {
            mediaPlayer.stop();
        }
    }

    function checkPauseState() {
        if (!root.screen) return;

        if (GlobalConfig.background.videoWallpaperPaused) {
            if (mediaPlayer.playing) mediaPlayer.pause();
            return;
        }

        const pauseOnAllDisplays = GlobalConfig.background.videoWallpaperPauseOnAllDisplays;
        const pauseOnFullscreen = GlobalConfig.background.videoWallpaperPauseOnFullscreen;
        const pauseOnTiled = GlobalConfig.background.videoWallpaperPauseOnTiled;

        let shouldPause = false;

        if (pauseOnAllDisplays) {
            let anyFullscreen = false;
            let anyTiled = false;
            for (const monitor of Hypr.monitors.values) {
                const toplevels = monitor?.activeWorkspace?.toplevels?.values || [];
                if (pauseOnFullscreen && toplevels.some(t => t?.lastIpcObject?.fullscreen > 1))
                    anyFullscreen = true;
                if (pauseOnTiled && toplevels.some(t => !t?.lastIpcObject?.floating && !t?.lastIpcObject?.fullscreen))
                    anyTiled = true;
            }
            shouldPause = anyFullscreen || anyTiled;
        } else {
            const monitor = Hypr.monitorFor(root.screen);
            if (!monitor) return;

            const toplevels = monitor.activeWorkspace?.toplevels?.values || [];

            if (pauseOnFullscreen && toplevels.some(t => t?.lastIpcObject?.fullscreen > 1))
                shouldPause = true;
            if (pauseOnTiled && toplevels.some(t => !t?.lastIpcObject?.floating && !t?.lastIpcObject?.fullscreen))
                shouldPause = true;
        }

        if (shouldPause && mediaPlayer.playing) {
            mediaPlayer.pause();
        } else if (!shouldPause && !mediaPlayer.playing && root.path) {
            mediaPlayer.play();
        }
    }

    function checkMuteState() {
        const muteOnMedia = GlobalConfig.background.videoWallpaperMuteOnMedia;
        const soundEnabled = GlobalConfig.background.videoWallpaperSoundEnabled;
        const isPlaying = Players.active?.isPlaying ?? false;
        
        audioOutput.muted = !root.isFirstInstance || !soundEnabled || (muteOnMedia && isPlaying);
    }

    Timer {
        id: mediaCheckTimer
        interval: 500
        running: GlobalConfig.background.videoWallpaperMuteOnMedia
        repeat: true
        onTriggered: checkMuteState()
    }

    Timer {
        id: checkTimer
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            checkPauseState();
            checkMuteState();
        }
    }

    Connections {
        target: GlobalConfig.background
        function onVideoWallpaperPausedChanged() { checkPauseState(); }
        function onVideoWallpaperPauseOnAllDisplaysChanged() { checkPauseState(); }
        function onVideoWallpaperPauseOnFullscreenChanged() { checkPauseState(); }
        function onVideoWallpaperPauseOnTiledChanged() { checkPauseState(); }
        function onVideoWallpaperMuteOnMediaChanged() { checkMuteState(); }
        function onVideoWallpaperSoundEnabledChanged() { checkMuteState(); }
    }

    Component.onCompleted: {
        isFirstInstance = (VideoWallpaperPlayer.firstInstance === null);
        VideoWallpaperPlayer.firstInstance = root;
        Qt.callLater(checkPauseState);
        Qt.callLater(checkMuteState);
    }

    Component.onDestruction: {
        if (VideoWallpaperPlayer.firstInstance === root) {
            VideoWallpaperPlayer.firstInstance = null;
        }
    }

    onPathChanged: {
        mediaPlayer.source = path || "";
        if (path) mediaPlayer.play();
    }
}