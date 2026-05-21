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
        
        const monitor = Hypr.monitorFor(root.screen);
        if (!monitor) return;
        
        const toplevels = monitor.activeWorkspace?.toplevels?.values || [];
        const pauseOnFullscreen = GlobalConfig.background.videoWallpaperPauseOnFullscreen;
        const pauseOnTiled = GlobalConfig.background.videoWallpaperPauseOnTiled;
        
        let shouldPause = false;
        
        if (pauseOnFullscreen) {
            const hasFullscreen = toplevels.some(t => t.lastIpcObject?.fullscreen > 1);
            if (hasFullscreen) shouldPause = true;
        }
        
        if (pauseOnTiled) {
            const hasTiled = toplevels.some(t => !t.lastIpcObject?.floating && !t.lastIpcObject?.fullscreen);
            if (hasTiled) shouldPause = true;
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
        const isPlaying = Players.active?.playbackStatus === 1;
        
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
        onTriggered: checkPauseState()
    }

    Connections {
        target: GlobalConfig.background
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