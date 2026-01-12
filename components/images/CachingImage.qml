import qs.utils
import Caelestia.Internal
import Quickshell
import QtQuick

Item {
    id: root

    property alias path: manager.path

    property url source: ""
    property size sourceSize: Qt.size(0, 0)

    property int fillMode: Image.PreserveAspectCrop
    property bool smooth: true
    property bool asynchronous: true

    property bool playbackEnabled: true
    property bool pauseWhenHidden: true
    property bool preferAnimated: true

    readonly property bool animated: manager.animated
    readonly property Item contentItem: loader.status === Loader.Ready ? loader.item : null
    readonly property int status: contentItem ? contentItem.status : Image.Null

    implicitWidth: 0
    implicitHeight: 0

    function restart(): void {
        if (!animated || !contentItem || !("currentFrame" in contentItem))
            return;

        contentItem.currentFrame = 0;
    }

    function updateAnimatedPause(): void {
        if (!animated || !contentItem || !("paused" in contentItem))
            return;

        const shouldPause = !playbackEnabled || (pauseWhenHidden && !visible);
        if (contentItem.paused !== shouldPause)
            contentItem.paused = shouldPause;
    }

    onPlaybackEnabledChanged: updateAnimatedPause()
    onPauseWhenHiddenChanged: updateAnimatedPause()
    onVisibleChanged: updateAnimatedPause()
    onAnimatedChanged: updateAnimatedPause()

    Connections {
        target: QsWindow.window

        function onDevicePixelRatioChanged(): void {
            if (!manager.animated || !root.preferAnimated)
                manager.updateSource();
        }
    }

    Image {
        id: animatedPlaceholder

        anchors.fill: parent
        asynchronous: root.asynchronous
        cache: false
        fillMode: root.fillMode
        smooth: root.smooth
        visible: manager.animated && root.preferAnimated && root.source && (!root.contentItem || root.contentItem.status !== Image.Ready)
        source: root.source
        sourceSize: root.sourceSize
    }

    Loader {
        id: loader

        anchors.fill: parent
        active: !!root.path
        asynchronous: true

        sourceComponent: manager.animated && root.preferAnimated ? animatedComponent : staticComponent

        onStatusChanged: {
            if (status === Loader.Ready)
                root.updateAnimatedPause();
        }
    }

    Component {
        id: staticComponent

        Image {
            anchors.fill: parent
            asynchronous: root.asynchronous
            fillMode: root.fillMode
            smooth: root.smooth
            source: root.source
            sourceSize: root.sourceSize
        }
    }

    Component {
        id: animatedComponent

        AnimatedImage {
            anchors.fill: parent
            cache: false
            fillMode: root.fillMode
            smooth: root.smooth
            source: root.source
            sourceSize: root.sourceSize
        }
    }

    CachingImageManager {
        id: manager

        item: root
        cacheDir: Qt.resolvedUrl(Paths.imagecache)
        preferAnimated: root.preferAnimated
    }
}
