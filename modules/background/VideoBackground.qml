pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Quickshell
import qs.services

Item {
    id: root

    required property ShellScreen screen
    property bool startupRevealPending: true

    readonly property string monitorName: Hypr.monitorFor(screen)?.name ?? screen.name
    readonly property string assignedSource: VideoWallpaper.sourceForMonitor(monitorName, screen.name)
    readonly property bool shouldBeVisible: VideoWallpaper.visualActive
        && VideoWallpaper.shouldDisplayOn(monitorName, screen.name)
        && assignedSource !== ""
    readonly property url resolvedSource: {
        const src = assignedSource;
        if (!src)
            return "";
        if (src.startsWith("/") || src.startsWith("file:/"))
            return Qt.resolvedUrl(src.startsWith("/") ? `file://${src}` : src);
        return Qt.resolvedUrl(src);
    }

    anchors.fill: parent
    opacity: shouldBeVisible && !startupRevealPending ? 1 : 0
    visible: opacity > 0 || player.playbackState === MediaPlayer.PlayingState

    Behavior on opacity {
        NumberAnimation {
            duration: Math.max(0, VideoWallpaper.fadeDuration)
        }
    }

    MediaPlayer {
        id: player

        source: root.resolvedSource
        videoOutput: output
        playbackRate: VideoWallpaper.playbackRate
        loops: VideoWallpaper.loop ? MediaPlayer.Infinite : 1

        Component.onCompleted: syncPlayback()
    }

    VideoOutput {
        id: output

        anchors.fill: parent
        fillMode: VideoWallpaper.fitMode === "Fit" ? VideoOutput.PreserveAspectFit
            : VideoWallpaper.fitMode === "Stretch" ? VideoOutput.Stretch
            : VideoOutput.PreserveAspectCrop
    }

    function syncPlayback() {
        if (!root.resolvedSource) {
            player.stop();
            return;
        }

        if (!root.shouldBeVisible || VideoWallpaper.effectivePaused) {
            player.pause();
            return;
        }

        player.play();
    }

    Component.onCompleted: Qt.callLater(() => {
        root.startupRevealPending = false;
    })

    onAssignedSourceChanged: syncPlayback()

    onResolvedSourceChanged: syncPlayback()
    onShouldBeVisibleChanged: syncPlayback()

    Connections {
        target: VideoWallpaper

        function onPausedChanged() {
            root.syncPlayback();
        }

        function onRunningChanged() {
            root.syncPlayback();
        }

        function onSourceChanged() {
            root.syncPlayback();
        }

        function onActiveSourceChanged() {
            root.syncPlayback();
        }

        function onVisualActiveChanged() {
            root.syncPlayback();
        }

        function onMonitorSourceMapChanged() {
            root.syncPlayback();
        }

        function onPerformanceLimitedChanged() {
            root.syncPlayback();
        }

        function onOutputChanged() {
            root.syncPlayback();
        }

        function onPerformanceModeChanged() {
            root.syncPlayback();
        }

        function onPrimaryMonitorNameChanged() {
            root.syncPlayback();
        }
    }
}
