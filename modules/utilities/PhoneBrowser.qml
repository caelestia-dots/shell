pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

Item {
    id: root

    required property string deviceId
    required property string deviceName
    required property string rootPath
    required property bool open

    // The folder being shown, and the one the model is scanning
    property string currentPath
    property string modelPath
    property string pendingPath
    // The model gives no signal when a scan finds nothing, so a folder counts as
    // loaded once entries arrive or loadTimer runs out
    property bool loaded
    property bool navigating

    property string selectedPath
    property string selectedIcon
    // Result of the last download, shown until another file is picked
    property string downloadStatus
    property string downloadStatusIcon
    // Hides Cancel for downloads which finish quickly. The browser is recreated
    // whenever utilities reopens, so the delay also runs for an ongoing download.
    property bool cancelDelayElapsed

    // -1 slides the old folder out to the left, 1 to the right
    property int animDirection: -1
    property real animTranslate
    property real animOpacity: 1
    readonly property real animDistance: Tokens.padding.extraLarge

    readonly property bool atRoot: currentPath === rootPath
    readonly property bool downloadingHere: KdeConnect.downloading && KdeConnect.downloadDevice === deviceId
    readonly property string displayPath: {
        const relative = currentPath.slice(rootPath.length).replace(/^\/+/, "");
        return relative ? relative.split("/").join("  ›  ") : Tr.tr("Internal storage");
    }

    signal closeRequested

    function reset(): void {
        exitAnim.stop();
        enterAnim.stop();
        loadTimer.stop();

        navigating = false;
        animTranslate = 0;
        animOpacity = 1;

        clearSelection();
        downloadStatus = "";

        currentPath = rootPath;
        modelPath = rootPath;
        loaded = false;
        loadTimer.restart();
    }

    function stop(): void {
        exitAnim.stop();
        enterAnim.stop();
        loadTimer.stop();

        navigating = false;
        pendingPath = "";
        animTranslate = 0;
        animOpacity = 1;

        // Start empty next time instead of scanning the last folder first
        modelPath = "";
    }

    function insideRoot(path: string): bool {
        return path === rootPath || path.startsWith(rootPath + "/");
    }

    function clearSelection(): void {
        fileView.currentIndex = -1;
        selectedPath = "";
        selectedIcon = "";
    }

    function navigateTo(path: string, forward: bool): void {
        if (navigating || path === currentPath || !insideRoot(path))
            return;

        animDirection = forward ? -1 : 1;
        pendingPath = path;
        navigating = true;
        clearSelection();
        downloadStatus = "";

        // Leaving starts once the folder responds, see onMountChecked
        KdeConnect.checkMount(deviceId, path);
    }

    // Runs while the old folder is invisible
    function showPendingPath(): void {
        currentPath = pendingPath;
        loaded = false;
        animTranslate = animDistance * -animDirection;

        // Changing the path keeps the old entries until the new scan finishes, so
        // detach the model first and attach it to the new folder on the next tick
        modelPath = "";
        Qt.callLater(() => {
            if (!navigating || !open)
                return;

            modelPath = currentPath;
            loadTimer.restart();
        });
    }

    function finishLoading(): void {
        loadTimer.stop();
        if (loaded)
            return;

        loaded = true;
        if (navigating)
            enterAnim.restart();
    }

    function back(): void {
        if (navigating)
            return;

        if (atRoot) {
            closeRequested();
            return;
        }

        const parentPath = currentPath.slice(0, currentPath.lastIndexOf("/"));
        navigateTo(insideRoot(parentPath) ? parentPath : rootPath, false);
    }

    function iconFor(isDir: bool, mimeType: string): string {
        if (isDir)
            return "folder";
        if (mimeType.startsWith("image/"))
            return "image";
        if (mimeType.startsWith("video/"))
            return "movie";
        if (mimeType.startsWith("audio/"))
            return "audio_file";
        if (mimeType === "application/pdf")
            return "picture_as_pdf";
        if (mimeType.startsWith("text/"))
            return "description";
        if (/zip|compressed|archive/.test(mimeType))
            return "archive";
        return "draft";
    }

    function setDownloadStatus(status: string, icon: string): void {
        downloadStatus = status;
        downloadStatusIcon = icon;
    }

    function startDownload(): void {
        downloadStatus = "";
        KdeConnect.download(deviceId, selectedPath);
    }

    clip: true

    onOpenChanged: {
        if (!open)
            stop();
    }
    onDownloadingHereChanged: {
        if (!downloadingHere)
            cancelDelayElapsed = false;
    }

    Connections {
        function onMountChecked(device: string, path: string, reachable: bool): void {
            if (device !== root.deviceId || path !== root.pendingPath || !root.navigating || root.currentPath === path || exitAnim.running)
                return;

            if (reachable) {
                exitAnim.restart();
            } else {
                // A dead mount gets unmounted, which closes the browser. Otherwise
                // the folder just vanished, so stay where we are.
                root.navigating = false;
                root.pendingPath = "";
            }
        }

        function onDownloaded(device: string, destinationPath: string): void {
            if (device === root.deviceId)
                // TRANSLATORS: %1 = the path the file was saved to
                root.setDownloadStatus(Tr.tr("Saved to %1").arg(destinationPath), "download_done");
        }

        function onDownloadFailed(device: string, error: string): void {
            if (device === root.deviceId)
                root.setDownloadStatus(error, "error");
        }

        function onDownloadCancelled(device: string): void {
            if (device === root.deviceId)
                root.setDownloadStatus(Tr.tr("Download cancelled"), "cancel");
        }

        target: KdeConnect
    }

    Timer {
        id: loadTimer

        interval: 500
        onTriggered: root.finishLoading()
    }

    Timer {
        id: cancelDelay

        running: root.downloadingHere && !root.cancelDelayElapsed
        interval: 1500
        onTriggered: root.cancelDelayElapsed = true
    }

    ParallelAnimation {
        id: exitAnim

        onFinished: root.showPendingPath()

        Anim {
            target: root
            property: "animTranslate"
            to: root.animDistance * root.animDirection
            type: Anim.FastSpatial
        }

        Anim {
            target: root
            property: "animOpacity"
            to: 0
            type: Anim.FastEffects
        }
    }

    ParallelAnimation {
        id: enterAnim

        onFinished: {
            root.navigating = false;
            root.pendingPath = "";
        }

        Anim {
            target: root
            property: "animTranslate"
            to: 0
            type: Anim.DefaultSpatial
        }

        Anim {
            target: root
            property: "animOpacity"
            to: 1
            type: Anim.DefaultEffects
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.small

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: header.implicitHeight + Tokens.padding.small * 2

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer

            RowLayout {
                id: header

                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                spacing: Tokens.spacing.small

                IconButton {
                    type: IconButton.Text
                    icon: "arrow_back"
                    disabled: root.navigating
                    onClicked: root.back()
                }

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: phoneIcon.implicitHeight + Tokens.padding.small * 2

                    radius: Tokens.rounding.full
                    color: Colours.palette.m3secondaryContainer

                    MaterialIcon {
                        id: phoneIcon

                        anchors.centerIn: parent
                        text: "smartphone"
                        color: Colours.palette.m3onSecondaryContainer
                        fontStyle: Tokens.font.icon.medium
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: root.deviceName
                        font: Tokens.font.body.medium
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.displayPath
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        elide: Text.ElideMiddle
                        opacity: root.animOpacity

                        transform: Translate {
                            x: root.animTranslate
                        }
                    }
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer
            clip: true

            Loader {
                anchors.centerIn: parent
                asynchronous: true
                opacity: root.loaded && !root.navigating && fileView.count === 0 ? 1 : 0
                active: opacity > 0

                sourceComponent: ColumnLayout {
                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "folder_open"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.large
                    }

                    StyledText {
                        text: Tr.tr("This folder is empty")
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.small
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            StyledListView {
                id: fileView

                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                clip: true
                currentIndex: -1
                boundsBehavior: Flickable.StopAtBounds
                opacity: root.animOpacity

                onCountChanged: {
                    if (count > 0)
                        root.finishLoading();
                }

                transform: Translate {
                    x: root.animTranslate
                }

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: fileView
                }

                model: FileSystemModel {
                    path: root.open ? root.modelPath : ""
                    onPathChanged: fileView.currentIndex = -1
                }

                delegate: StyledRect {
                    id: entry

                    required property int index
                    required property FileSystemEntry modelData

                    // When the folder changes, the model deletes its entries before the
                    // delegates are removed, so modelData can briefly be null
                    readonly property bool valid: modelData !== null
                    readonly property string entryPath: modelData?.path ?? ""
                    readonly property string entryName: modelData?.name ?? ""
                    readonly property bool entryIsDir: modelData?.isDir ?? false
                    readonly property bool selected: ListView.isCurrentItem
                    readonly property string icon: root.iconFor(entryIsDir, modelData?.mimeType ?? "")

                    width: ListView.view.width
                    implicitHeight: entryLayout.implicitHeight + Tokens.padding.small * 2

                    radius: Tokens.rounding.medium
                    color: selected ? Colours.palette.m3secondaryContainer : "transparent"

                    StateLayer {
                        color: entry.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        disabled: root.navigating || !entry.valid

                        onClicked: {
                            if (entry.entryIsDir) {
                                root.navigateTo(entry.entryPath, true);
                                return;
                            }

                            fileView.currentIndex = entry.index;
                            root.selectedPath = entry.entryPath;
                            root.selectedIcon = entry.icon;
                            root.downloadStatus = "";
                        }

                        // Opens the file through the mounted storage
                        onDoubleClicked: {
                            if (entry.valid && !entry.entryIsDir)
                                Quickshell.execDetached(["xdg-open", entry.entryPath]);
                        }
                    }

                    RowLayout {
                        id: entryLayout

                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.small
                        anchors.rightMargin: Tokens.padding.small
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: entry.icon
                            color: entry.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: entry.entryName
                            color: entry.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            font: Tokens.font.body.small
                            elide: Text.ElideMiddle
                        }

                        MaterialIcon {
                            visible: entry.entryIsDir
                            text: "chevron_right"
                            color: entry.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }
                    }
                }
            }
        }

        // Clips the progress fill to the rounded corners
        StyledClippingRect {
            Layout.fillWidth: true
            visible: root.selectedPath !== "" || root.downloadingHere || root.downloadStatus !== ""
            implicitHeight: fileLayout.implicitHeight + Tokens.padding.medium * 2

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer

            StyledRect {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: parent.width * (root.downloadingHere ? KdeConnect.downloadProgress : 0)

                color: Colours.palette.m3primaryContainer
                opacity: root.downloadingHere ? 0.65 : 0
            }

            RowLayout {
                id: fileLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: fileIcon.implicitHeight + Tokens.padding.small * 2

                    radius: Tokens.rounding.full
                    color: Colours.palette.m3secondaryContainer

                    MaterialIcon {
                        id: fileIcon

                        anchors.centerIn: parent
                        text: {
                            if (root.downloadingHere)
                                return "download";
                            if (root.downloadStatus)
                                return root.downloadStatusIcon;
                            return root.selectedIcon || "draft";
                        }
                        color: Colours.palette.m3onSecondaryContainer
                        fontStyle: Tokens.font.icon.small
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: root.downloadingHere || root.downloadStatus ? KdeConnect.downloadName : root.selectedPath.split("/").pop()
                        font: Tokens.font.body.small
                        elide: Text.ElideMiddle
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        // TRANSLATORS: %1 = download progress percentage
                        text: root.downloadingHere ? Tr.tr("Downloading… %1%").arg(Math.round(KdeConnect.downloadProgress * 100)) : root.downloadStatus
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        elide: Text.ElideMiddle
                    }
                }

                TextButton {
                    visible: root.selectedPath !== "" && !root.downloadingHere
                    type: TextButton.Tonal
                    text: Tr.tr("Download")
                    disabled: KdeConnect.downloading || root.navigating
                    onClicked: root.startDownload()
                }

                TextButton {
                    visible: root.downloadingHere && root.cancelDelayElapsed
                    type: TextButton.Tonal
                    text: Tr.trCtx("Cancel", "button")
                    onClicked: KdeConnect.cancelDownload()
                }
            }
        }
    }
}
