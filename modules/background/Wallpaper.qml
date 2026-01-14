pragma ComponentBehavior: Bound

import qs.components
import qs.components.images
import qs.components.filedialog
import qs.services
import qs.config
import qs.utils
import QtQuick

Item {
    id: root
    anchors.fill: parent

    property string source: Wallpapers.current
    property bool initialized: false
    property int loadedCount: 0
    property bool itemsReady: false
    property bool initStarted: false
    property var sessionLock: null
    readonly property bool sessionLocked: sessionLock ? sessionLock.secure : false

    function applySessionLock(loader) {
        if (!loader || !loader.item)
            return;

        if (typeof loader.item.setSessionLocked === "function")
            loader.item.setSessionLocked(sessionLocked);
    }

    function isVideo(path) {
        path = path.toString();
        if (!path || path.trim() === "")
            return false;

        const videoExtensions = [".mp4", ".mkv", ".webm", ".avi", ".mov", ".flv", ".wmv", ".gif"];

        const lower = path.toLowerCase();
        for (let i = 0; i < videoExtensions.length; i++) {
            if (lower.endsWith(videoExtensions[i]))
                return true;
        }
        return false;
    }

    function waitForBothItems() {
        if (oneLoader.item && twoLoader.item) {
            itemsReady = true;
            initialize();
            return;
        }
        Qt.callLater(waitForBothItems);
    }

    function initialize() {
        if (initStarted || loadedCount < 2 || !itemsReady)
            return;

        initStarted = true;

        oneLoader.item.isCurrent = true;
        twoLoader.item.isCurrent = false;

        initialized = true;
        Qt.callLater(switchWallpaper);
    }

    function switchWallpaper() {
        if (!initialized || !root.source)
            return;

        let active;
        let inactive;

        if (oneLoader.item.isCurrent) {
            active = oneLoader;
            inactive = twoLoader;
        } else {
            active = twoLoader;
            inactive = oneLoader;
        }

        inactive.sourceComponent = isVideo(source) ? videoComponent : imageComponent;

        waitForItem(inactive, function () {
            inactive.item.update(source);

            inactive.item.ready.connect(function handler() {
                active.item.isCurrent = false;
                inactive.item.isCurrent = true;
                inactive.item.ready.disconnect(handler);
            });
        });
    }

    function waitForItem(loader, callback) {
        if (loader.item) {
            callback();
            return;
        }
        Qt.callLater(() => waitForItem(loader, callback));
    }

    onSessionLockedChanged: {
        applySessionLock(oneLoader);
        applySessionLock(twoLoader);
    }

    Loader {
        id: placeholderLoader
        anchors.fill: parent
        z: 10
        asynchronous: true
        active: !root.source

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Appearance.spacing.large

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.extraLarge * 5
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.extraLarge * 2
                        font.bold: true
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Appearance.padding.large * 2
                        implicitHeight: selectWallText.implicitHeight + Appearance.padding.small * 2

                        radius: Appearance.rounding.full
                        color: Colours.palette.m3primary

                        FileDialog {
                            id: dialog
                            title: qsTr("Select a wallpaper")
                            filterLabel: qsTr("Image files")
                            filters: Images.validImageExtensions
                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onPrimary
                            function onClicked(): void {
                                dialog.open();
                            }
                        }

                        StyledText {
                            id: selectWallText
                            anchors.centerIn: parent
                            text: qsTr("Set it now!")
                            color: Colours.palette.m3onPrimary
                            font.pointSize: Appearance.font.size.large
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: oneLoader
        anchors.fill: parent
        asynchronous: true
        sourceComponent: imageComponent

        onLoaded: {
            loadedCount++;
            if (loadedCount === 2)
                waitForBothItems();
        }

        onItemChanged: applySessionLock(oneLoader)
    }

    Loader {
        id: twoLoader
        anchors.fill: parent
        asynchronous: true
        sourceComponent: imageComponent
        onLoaded: {
            loadedCount++;
            if (loadedCount === 2)
                waitForBothItems();
        }

        onItemChanged: applySessionLock(twoLoader)
    }

    onSourceChanged: {
        if (initialized)
            switchWallpaper();
    }

    Component {
        id: imageComponent
        ImageWallpaper {}
    }

    Component {
        id: videoComponent
        VideoWallpaper {}
    }
}
