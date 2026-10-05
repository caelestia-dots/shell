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
    // Whether the folder on show has been scanned, see finishLoading
    property bool loaded
    property bool navigating
    // Leaving the old folder animates while its target is checked. Both have to be
    // done before the new folder is shown.
    property bool exitDone
    // "pending", "ok" or "failed"
    property string probeState
    // Waiting for a folder, once the old one has left the view
    readonly property bool loading: !loaded && (!navigating || exitDone)
    // Where each folder left this session was scrolled to, keyed by path, so going
    // back returns there: the first visible entry and how far into it the view was
    property var scrollMemory: ({})

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
    readonly property var extensionIcons: {
        const icons = {};
        const groups = {
            image: ["jpg", "jpeg", "png", "gif", "webp", "heic", "heif", "avif", "bmp", "tif", "tiff", "svg", "dng", "raw"],
            movie: ["mp4", "m4v", "mkv", "webm", "mov", "avi", "3gp", "3g2", "ts", "mpeg", "mpg", "wmv", "flv"],
            audio_file: ["mp3", "m4a", "aac", "flac", "ogg", "oga", "opus", "wav", "amr", "mid", "midi", "wma"],
            picture_as_pdf: ["pdf"],
            description: ["txt", "md", "log", "csv", "json", "xml", "html", "htm", "ini", "conf", "yaml", "yml", "srt", "vtt"],
            archive: ["zip", "rar", "7z", "tar", "gz", "tgz", "bz2", "xz", "zst", "apk", "xapk"]
        };
        for (const icon in groups)
            for (const extension of groups[icon])
                icons[extension] = icon;
        return icons;
    }

    readonly property bool atRoot: currentPath === rootPath
    readonly property bool downloadingHere: KdeConnect.downloading && KdeConnect.downloadDevice === deviceId
    // Each folder from the storage root down to the current one
    readonly property var crumbs: {
        const result = [
            {
                name: Tr.tr("Internal storage"),
                path: rootPath
            }
        ];
        const relative = currentPath.slice(rootPath.length).replace(/^\/+/, "");
        let path = rootPath;
        for (const part of relative ? relative.split("/") : []) {
            path += `/${part}`;
            result.push({
                name: part,
                path
            });
        }
        return result;
    }

    signal closeRequested

    function reset(): void {
        exitAnim.stop();
        enterAnim.stop();

        navigating = false;
        exitDone = false;
        probeState = "";
        animTranslate = 0;
        animOpacity = 1;

        clearSelection();
        downloadStatus = "";
        scrollMemory = {};

        currentPath = rootPath;
        loaded = false;
        modelPath = rootPath;
        // Setting the same path starts no scan, so there is nothing to wait for
        if (!folderModel.loading)
            finishLoading();
    }

    function stop(): void {
        exitAnim.stop();
        enterAnim.stop();

        navigating = false;
        pendingPath = "";
        exitDone = false;
        probeState = "";
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

        rememberScroll();

        animDirection = forward ? -1 : 1;
        pendingPath = path;
        navigating = true;
        loaded = false;
        exitDone = false;
        probeState = "pending";
        clearSelection();
        downloadStatus = "";

        // Leave right away while the folder is checked, see continueNavigation
        exitAnim.restart();
        KdeConnect.checkMount(deviceId, path);
    }

    function rememberScroll(): void {
        const next = Object.assign({}, scrollMemory);

        // Any scroll counts, also less than one entry, e.g. in a folder that almost
        // fits the view
        if (fileView.contentY > fileView.originY) {
            // indexAt takes content coordinates, so this is the entry at the top of the view
            const index = fileView.indexAt(fileView.width / 2, fileView.contentY + 1);
            const item = fileView.itemAtIndex(index);
            next[currentPath] = {
                index,
                offset: item ? fileView.contentY - item.y : 0
            };
        } else {
            delete next[currentPath];
        }

        scrollMemory = next;
    }

    // Runs when either the exit animation or the folder check finishes
    function continueNavigation(): void {
        if (!navigating || !exitDone || probeState === "pending")
            return;

        if (probeState === "ok") {
            showPendingPath();
            return;
        }

        // The folder vanished, so bring the current one back. A dead mount gets
        // unmounted instead, which closes the browser.
        pendingPath = "";
        loaded = true;
        enterAnim.restart();
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
            if (!folderModel.loading)
                finishLoading();
        });
    }

    // Runs once the model has finished scanning
    function finishLoading(): void {
        // Only a finished scan of the folder on show counts. While switching folders
        // the model is briefly on an empty path, and the folder being left may still
        // finish a scan during the exit animation.
        if (folderModel.loading || folderModel.path !== currentPath || (navigating && currentPath !== pendingPath))
            return;

        if (loaded)
            return;

        loaded = true;

        // Going back, return to where the folder was scrolled to. The model's loading
        // ends after the entries are in, so the list is complete here, and it is
        // still hidden until the enter animation.
        const memory = scrollMemory[currentPath];
        if (navigating && animDirection === 1 && memory && fileView.count > 0) {
            fileView.positionViewAtIndex(Math.min(memory.index, fileView.count - 1), ListView.Beginning);
            // Then the part of the entry that was scrolled past, without going beyond the end
            const end = fileView.originY + Math.max(0, fileView.contentHeight - fileView.height);
            fileView.contentY = Math.min(fileView.contentY + memory.offset, end);
        }

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

    // Size and date of a file, e.g. "2.4 MB · 12 Sep". Both come from the scan, so this
    // reads nothing from the phone. Folders get none, as their size needs a scan.
    function detailsFor(isDir: bool, size: real, modified: var): string {
        if (isDir)
            return "";

        const parts = [Units.formatBytes(size)];
        if (modified instanceof Date && !isNaN(modified.getTime())) {
            const thisYear = modified.getFullYear() === new Date().getFullYear();
            parts.push(modified.toLocaleDateString(Qt.locale(), thisYear ? "d MMM" : "d MMM yyyy"));
        }
        return parts.join(" · ");
    }

    // Picks the icon from the extension alone. Reading the mime type can open the
    // file, which on the phone's storage is a network request on the UI thread.
    function iconFor(isDir: bool, name: string): string {
        if (isDir)
            return "folder";

        // The last dot, so IMG_2024.01.05.jpg is a jpg. A dot at the start marks a
        // hidden file rather than an extension.
        const dot = name.lastIndexOf(".");
        if (dot <= 0)
            return "draft";

        const extension = name.slice(dot + 1).toLowerCase();
        // Only own keys, so a name like "x.constructor" cannot match Object's members
        return extensionIcons.hasOwnProperty(extension) ? extensionIcons[extension] : "draft";
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
            if (device !== root.deviceId || path !== root.pendingPath || !root.navigating || root.probeState !== "pending")
                return;

            root.probeState = reachable ? "ok" : "failed";
            root.continueNavigation();
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
        id: cancelDelay

        running: root.downloadingHere && !root.cancelDelayElapsed
        interval: 1500
        onTriggered: root.cancelDelayElapsed = true
    }

    ParallelAnimation {
        id: exitAnim

        onFinished: {
            root.exitDone = true;
            root.continueNavigation();
        }

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

                    // Clickable path like the file dialog's. Deep paths scroll sideways and
                    // stay scrolled to the end, so the current folder is always visible.
                    Flickable {
                        id: crumbsView

                        function scrollToEnd(): void {
                            contentX = Math.max(0, contentWidth - width);
                        }

                        Layout.fillWidth: true
                        implicitHeight: crumbsRow.implicitHeight
                        contentWidth: crumbsRow.implicitWidth
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: contentWidth > width
                        clip: true
                        opacity: root.animOpacity

                        onContentWidthChanged: scrollToEnd()
                        onWidthChanged: scrollToEnd()

                        transform: Translate {
                            x: root.animTranslate
                        }

                        RowLayout {
                            id: crumbsRow

                            spacing: 0

                            Repeater {
                                model: root.crumbs

                                RowLayout {
                                    id: crumb

                                    required property var modelData
                                    required property int index

                                    readonly property bool current: index === root.crumbs.length - 1

                                    spacing: 0

                                    StyledText {
                                        visible: crumb.index > 0
                                        text: "›"
                                        color: Colours.palette.m3onSurfaceVariant
                                        font: Tokens.font.body.small
                                    }

                                    Item {
                                        implicitWidth: crumbName.implicitWidth + Tokens.padding.small
                                        implicitHeight: crumbName.implicitHeight

                                        StateLayer {
                                            radius: Tokens.rounding.small
                                            disabled: crumb.current || root.navigating
                                            onClicked: root.navigateTo(crumb.modelData.path, false)
                                        }

                                        StyledText {
                                            id: crumbName

                                            anchors.centerIn: parent
                                            text: crumb.modelData.name
                                            color: crumb.current ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                                            font: Tokens.font.body.small
                                        }
                                    }
                                }
                            }
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
                opacity: root.loading ? 1 : 0
                active: opacity > 0

                sourceComponent: LoadingIndicator {
                    implicitSize: Math.round(Tokens.font.icon.large.pointSize * 1.3)
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

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

                transform: Translate {
                    x: root.animTranslate
                }

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: fileView
                }

                model: FileSystemModel {
                    id: folderModel

                    // sshfs never reports changes made on the phone, so watching only costs a
                    // request on the UI thread
                    watchChanges: false
                    path: root.open ? root.modelPath : ""
                    onPathChanged: fileView.currentIndex = -1
                    onLoadingChanged: {
                        if (!folderModel.loading)
                            root.finishLoading();
                    }
                }

                delegate: StyledRect {
                    id: entry

                    required property int index
                    required property FileSystemEntry modelData

                    // A delegate being torn down can briefly see its entry gone, so read
                    // modelData defensively
                    readonly property bool valid: modelData !== null
                    readonly property string entryPath: modelData?.path ?? ""
                    readonly property string entryName: modelData?.name ?? ""
                    readonly property bool entryIsDir: modelData?.isDir ?? false
                    readonly property bool selected: ListView.isCurrentItem
                    readonly property string icon: root.iconFor(entryIsDir, entryName)
                    readonly property string details: root.detailsFor(entryIsDir, modelData?.size ?? 0, modelData?.lastModified)

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

                        // The name is elided first, so these always stay readable
                        StyledText {
                            visible: text !== ""
                            text: entry.details
                            color: entry.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
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
