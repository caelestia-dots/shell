pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property var wrapper

    property string currentPath: ""
    property string modelPath: ""
    property string pendingPath: ""

    property string selectedPath: ""
    property bool selectedIsDir: false

    property string activeDownloadName: ""
    property string downloadStatus: ""
    property bool showDownloadCancel: false

    //
    // Folder navigation state.
    //
    property bool navigating: false
    property bool waitingForModel: false

    //
    // Calendar-style animation.
    //
    // -1 -> forward:
    // old content moves left, new content enters from right.
    //
    // 1 -> backward:
    // old content moves right, new content enters from left.
    //
    property int animDirection: -1
    property real animTranslate: 0
    property real animOpacity: 1

    readonly property real animDistance: Tokens.padding.extraLarge

    property bool showEmptyState: false

    readonly property string deviceId: wrapper.browserDeviceId

    readonly property string deviceName: wrapper.browserDeviceName

    readonly property string rootPath: wrapper.browserRootPath

    readonly property bool atRoot: currentPath === rootPath

    readonly property bool downloadingHere: KdeConnect.receiving && KdeConnect.receivingDevice === root.deviceId

    readonly property int columnCount: 3

    readonly property string displayPath: {
        if (!currentPath || currentPath === rootPath) {
            return qsTr("Internal storage");
        }

        let relative = currentPath.slice(rootPath.length);

        if (relative.startsWith("/"))
            relative = relative.slice(1);

        if (!relative)
            return qsTr("Internal storage");

        return relative.split("/").join("  ›  ");
    }

    clip: true

    //
    // ==================================================
    // Empty-state handling
    // ==================================================
    //

    function scheduleEmptyStateCheck(): void {
        emptyStateTimer.stop();

        root.showEmptyState = false;

        if (!root.wrapper.browserOpen)
            return;

        if (root.navigating || root.waitingForModel) {
            return;
        }

        if (!root.currentPath)
            return;

        if (fileView.count > 0)
            return;

        emptyStateTimer.restart();
    }

    Timer {
        id: emptyStateTimer

        //
        // Prevent a temporary count === 0 from flashing
        // "This folder is empty".
        //
        interval: 750
        repeat: false

        onTriggered: {
            root.showEmptyState = root.wrapper.browserOpen && !root.navigating && !root.waitingForModel && root.currentPath !== "" && fileView.count === 0;
        }
    }

    //
    // Used while switching to a new FileSystemModel path.
    //
    // If items arrive, onCountChanged completes the navigation
    // immediately.
    //
    // If count remains zero, this timer decides that the
    // directory is genuinely empty.
    //
    Timer {
        id: modelReadyTimer

        interval: 500
        repeat: false

        onTriggered: {
            if (!root.waitingForModel)
                return;

            root.showEmptyState = fileView.count === 0;

            root.showPendingPath();
        }
    }

    //
    // ==================================================
    // Browser lifecycle
    // ==================================================
    //

    function resetBrowser(): void {
        exitAnimation.stop();
        enterAnimation.stop();

        emptyStateTimer.stop();
        modelReadyTimer.stop();
        downloadCancelTimer.stop();

        root.navigating = false;
        root.waitingForModel = false;

        root.pendingPath = "";

        root.animTranslate = 0;
        root.animOpacity = 1;

        root.showEmptyState = false;

        root.currentPath = root.rootPath;

        root.modelPath = root.rootPath;

        root.selectedPath = "";
        root.selectedIsDir = false;
        root.downloadStatus = "";

        fileView.currentIndex = -1;

        //
        // Check whether the initial/root directory is empty.
        //
        root.scheduleEmptyStateCheck();

        //
        // A download may still be running after temporarily
        // leaving the browser.
        //
        if (root.downloadingHere) {
            if (!downloadCancelTimer.running)
                root.showDownloadCancel = true;

            return;
        }

        root.activeDownloadName = "";
        root.showDownloadCancel = false;
    }

    function insideRoot(path: string): bool {
        return path === root.rootPath || path.startsWith(root.rootPath + "/");
    }

    function clearSelection(): void {
        fileView.currentIndex = -1;

        root.selectedPath = "";
        root.selectedIsDir = false;
        root.downloadStatus = "";
    }

    //
    // ==================================================
    // Folder navigation
    // ==================================================
    //

    function navigateTo(path: string, forward: bool): void {
        if (root.navigating)
            return;

        if (!root.insideRoot(path))
            return;

        if (path === root.currentPath)
            return;

        root.animDirection = forward ? -1 : 1;

        root.pendingPath = path;

        root.navigating = true;
        root.waitingForModel = false;

        emptyStateTimer.stop();
        modelReadyTimer.stop();

        root.showEmptyState = false;

        root.clearSelection();

        //
        // First animate the old directory out.
        //
        exitAnimation.restart();
    }

    function preparePendingPath(): void {
        if (!root.navigating || !root.pendingPath) {
            return;
        }

        root.waitingForModel = true;

        //
        // currentPath changes while the contents are invisible.
        // This updates the header/breadcrumb without exposing
        // the path change.
        //
        root.currentPath = root.pendingPath;

        //
        // New content will enter from the opposite direction.
        //
        root.animTranslate = root.animDistance * -root.animDirection;

        root.animOpacity = 0;

        //
        // IMPORTANT:
        //
        // Detach the FileSystemModel from the previous directory
        // first. This forces the old delegates to disappear.
        //
        root.modelPath = "";

        //
        // Let QML process modelPath = "" before attaching the
        // model to the next SFTP/FUSE directory.
        //
        Qt.callLater(() => {
            if (!root.waitingForModel || !root.wrapper.browserOpen) {
                return;
            }

            //
            // Start the empty-folder timeout BEFORE assigning
            // the path. If count > 0 arrives immediately,
            // onCountChanged will stop this timer.
            //
            modelReadyTimer.restart();

            root.modelPath = root.pendingPath;
        });
    }

    function showPendingPath(): void {
        if (!root.waitingForModel)
            return;

        modelReadyTimer.stop();

        root.waitingForModel = false;
        root.pendingPath = "";

        //
        // The new directory is ready.
        // Bring it in using Calendar's Default animation.
        //
        enterAnimation.restart();
    }

    function finishEnterAnimation(): void {
        root.animTranslate = 0;
        root.animOpacity = 1;

        root.navigating = false;

        if (fileView.count > 0) {
            emptyStateTimer.stop();
            root.showEmptyState = false;
        } else if (!root.showEmptyState) {
            root.scheduleEmptyStateCheck();
        }
    }

    function openDirectory(path: string): void {
        root.navigateTo(path, true);
    }

    function back(): void {
        if (root.navigating)
            return;

        //
        // At storage root Back returns to Utilities.
        //
        if (root.atRoot) {
            root.wrapper.closeBrowser();
            return;
        }

        const index = root.currentPath.lastIndexOf("/");

        if (index <= 0) {
            root.navigateTo(root.rootPath, false);

            return;
        }

        const parentPath = root.currentPath.slice(0, index);

        root.navigateTo(root.insideRoot(parentPath) ? parentPath : root.rootPath, false);
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

        if (mimeType.includes("zip") || mimeType.includes("compressed") || mimeType.includes("archive")) {
            return "archive";
        }

        return "draft";
    }

    //
    // ==================================================
    // Calendar-style animations
    // ==================================================
    //
    // Same idea as Dashboard Calendar:
    //
    // FastSpatial + FastEffects
    //         ↓
    // change/load content
    //         ↓
    // DefaultSpatial + DefaultEffects
    //

    ParallelAnimation {
        id: exitAnimation

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

        onFinished: root.preparePendingPath()
    }

    ParallelAnimation {
        id: enterAnimation

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

        onFinished: root.finishEnterAnimation()
    }

    //
    // ==================================================
    // Connections
    // ==================================================
    //

    Connections {
        target: root.wrapper

        function onBrowserOpened() {
            root.resetBrowser();
        }

        function onBrowserOpenChanged() {
            if (root.wrapper.browserOpen)
                return;

            //
            // Stop an unfinished folder transition if Utilities
            // gets closed while a model is loading.
            //
            exitAnimation.stop();
            enterAnimation.stop();

            modelReadyTimer.stop();
            emptyStateTimer.stop();

            root.navigating = false;
            root.waitingForModel = false;
            root.pendingPath = "";

            root.animTranslate = 0;
            root.animOpacity = 1;

            root.showEmptyState = false;
        }
    }

    Connections {
        target: KdeConnect

        function onDownloaded(device, destinationPath) {
            if (device !== root.deviceId)
                return;

            downloadCancelTimer.stop();

            root.showDownloadCancel = false;
            root.activeDownloadName = "";

            root.downloadStatus = qsTr("Saved to %1").arg(destinationPath);
        }

        function onDownloadFailed(device, error) {
            if (device !== root.deviceId)
                return;

            downloadCancelTimer.stop();

            root.showDownloadCancel = false;
            root.activeDownloadName = "";

            root.downloadStatus = error;
        }

        function onDownloadCancelled(device) {
            if (device !== root.deviceId)
                return;

            downloadCancelTimer.stop();

            root.showDownloadCancel = false;
            root.activeDownloadName = "";

            root.downloadStatus = qsTr("Download cancelled");
        }
    }

    Timer {
        id: downloadCancelTimer

        interval: 1500
        repeat: false

        onTriggered: {
            if (root.downloadingHere)
                root.showDownloadCancel = true;
        }
    }

    //
    // ==================================================
    // Browser UI
    // ==================================================
    //

    ColumnLayout {
        id: browserPage

        anchors.fill: parent

        spacing: Tokens.spacing.medium

        //
        // ============================================
        // Header card
        // ============================================
        //
        StyledRect {
            Layout.fillWidth: true

            implicitHeight: headerLayout.implicitHeight + Tokens.padding.medium * 2

            radius: Tokens.rounding.large

            color: Colours.tPalette.m3surfaceContainer

            RowLayout {
                id: headerLayout

                anchors.fill: parent

                anchors.margins: Tokens.padding.medium

                spacing: Tokens.spacing.medium

                //
                // Back
                //
                StyledRect {
                    implicitWidth: 36
                    implicitHeight: 36

                    radius: Tokens.rounding.full

                    color: backHover.hovered ? Colours.palette.m3secondaryContainer : "transparent"

                    MaterialIcon {
                        anchors.centerIn: parent

                        text: "arrow_back"

                        color: Colours.palette.m3onSurface

                        fontStyle: Tokens.font.icon.small
                    }

                    HoverHandler {
                        id: backHover
                    }

                    TapHandler {
                        enabled: !root.navigating

                        onTapped: root.back()
                    }
                }

                //
                // Phone icon remains stationary.
                //
                StyledRect {
                    implicitWidth: 46
                    implicitHeight: 46

                    radius: Tokens.rounding.full

                    color: Colours.palette.m3secondaryContainer

                    MaterialIcon {
                        anchors.centerIn: parent

                        text: "smartphone"

                        color: Colours.palette.m3onSecondaryContainer

                        fontStyle: Tokens.font.icon.large
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true

                        text: root.deviceName

                        color: Colours.palette.m3onSurface

                        font: Tokens.font.body.medium

                        elide: Text.ElideRight
                    }

                    //
                    // Breadcrumb follows the same animation as
                    // the file contents.
                    //
                    StyledText {
                        Layout.fillWidth: true

                        opacity: root.animOpacity

                        transform: Translate {
                            x: root.animTranslate
                        }

                        text: root.displayPath

                        color: Colours.palette.m3onSurfaceVariant

                        font: Tokens.font.body.small

                        elide: Text.ElideMiddle
                    }
                }
            }
        }

        //
        // ============================================
        // Storage card
        // ============================================
        //
        StyledRect {
            id: storageCard

            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Tokens.rounding.large

            color: Colours.tPalette.m3surfaceContainer

            clip: true

            Item {
                id: fileContent

                anchors.fill: parent

                anchors.margins: Tokens.padding.small

                opacity: root.animOpacity

                transform: Translate {
                    x: root.animTranslate
                }

                //
                // Empty directory.
                //
                StyledText {
                    z: 1

                    anchors.centerIn: parent

                    visible: root.showEmptyState

                    text: qsTr("This folder is empty")

                    color: Colours.palette.m3onSurfaceVariant

                    font: Tokens.font.body.small
                }

                GridView {
                    id: fileView

                    anchors.fill: parent

                    clip: true
                    focus: true

                    currentIndex: -1

                    cellWidth: width / root.columnCount

                    cellHeight: 92

                    boundsBehavior: Flickable.StopAtBounds

                    onCountChanged: {
                        //
                        // We are waiting for the new directory.
                        //
                        if (root.waitingForModel) {
                            if (count > 0) {
                                root.showEmptyState = false;

                                root.showPendingPath();
                            }

                            return;
                        }

                        //
                        // Normal directory state.
                        //
                        if (count > 0) {
                            emptyStateTimer.stop();

                            root.showEmptyState = false;

                            return;
                        }

                        if (!root.navigating)
                            root.scheduleEmptyStateCheck();
                    }

                    //
                    // Do NOT bind directly to currentPath.
                    //
                    // modelPath lets us explicitly detach from
                    // the old directory before loading the next
                    // KDE Connect FUSE directory.
                    //
                    model: FileSystemModel {
                        path: root.wrapper.browserOpen ? root.modelPath : ""

                        onPathChanged: {
                            fileView.currentIndex = -1;
                        }
                    }

                    delegate: Item {
                        id: entry

                        required property int index
                        required property FileSystemEntry modelData

                        readonly property bool valid: entry.modelData !== null

                        readonly property string entryPath: entry.valid ? entry.modelData.path : ""

                        readonly property string entryName: entry.valid ? entry.modelData.name : ""

                        readonly property bool entryIsDir: entry.valid ? entry.modelData.isDir : false

                        readonly property string entryMimeType: entry.valid ? entry.modelData.mimeType : ""

                        width: fileView.cellWidth

                        height: fileView.cellHeight

                        StyledRect {
                            anchors.fill: parent

                            anchors.margins: 3

                            radius: Tokens.rounding.medium

                            color: entry.GridView.isCurrentItem ? Colours.palette.m3secondaryContainer : entryHover.hovered ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

                            ColumnLayout {
                                anchors.centerIn: parent

                                width: parent.width - Tokens.padding.small * 2

                                spacing: Tokens.spacing.small

                                StyledRect {
                                    Layout.alignment: Qt.AlignHCenter

                                    implicitWidth: 40
                                    implicitHeight: 40

                                    radius: Tokens.rounding.full

                                    color: entry.GridView.isCurrentItem ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

                                    MaterialIcon {
                                        anchors.centerIn: parent

                                        text: root.iconFor(entry.entryIsDir, entry.entryMimeType)

                                        color: entry.GridView.isCurrentItem ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer

                                        fontStyle: Tokens.font.icon.small
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true

                                    text: entry.entryName

                                    horizontalAlignment: Text.AlignHCenter

                                    color: entry.GridView.isCurrentItem ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface

                                    font: Tokens.font.body.small

                                    elide: Text.ElideRight

                                    maximumLineCount: 1
                                }
                            }

                            HoverHandler {
                                id: entryHover
                            }

                            StateLayer {
                                enabled: entry.valid && !root.navigating

                                onClicked: {
                                    if (!entry.valid)
                                        return;

                                    fileView.currentIndex = entry.index;

                                    root.selectedPath = entry.entryPath;

                                    root.selectedIsDir = entry.entryIsDir;

                                    root.downloadStatus = "";
                                }

                                onDoubleClicked: {
                                    if (!entry.valid)
                                        return;

                                    if (entry.entryIsDir) {
                                        root.openDirectory(entry.entryPath);

                                        return;
                                    }

                                    Quickshell.execDetached(["xdg-open", entry.entryPath]);
                                }
                            }
                        }
                    }
                }
            }
        }

        //
        // ============================================
        // Selected file / transfer card
        // ============================================
        //
        StyledRect {
            Layout.fillWidth: true

            visible: root.selectedPath !== "" || root.downloadingHere || root.downloadStatus !== ""

            implicitHeight: selectedLayout.implicitHeight + Tokens.padding.medium * 2

            radius: Tokens.rounding.large

            color: Colours.tPalette.m3surfaceContainer

            clip: true

            //
            // Real download progress.
            //
            StyledRect {
                anchors.top: parent.top

                anchors.bottom: parent.bottom

                anchors.left: parent.left

                width: root.downloadingHere ? parent.width * KdeConnect.progress : 0

                radius: parent.radius

                color: Colours.palette.m3primaryContainer

                opacity: root.downloadingHere ? 0.65 : 0
            }

            RowLayout {
                id: selectedLayout

                anchors.fill: parent

                anchors.margins: Tokens.padding.medium

                spacing: Tokens.spacing.medium

                StyledRect {
                    implicitWidth: 40
                    implicitHeight: 40

                    radius: Tokens.rounding.full

                    color: Colours.palette.m3secondaryContainer

                    MaterialIcon {
                        anchors.centerIn: parent

                        text: root.downloadingHere ? "download" : root.selectedIsDir ? "folder" : "description"

                        color: Colours.palette.m3onSecondaryContainer

                        fontStyle: Tokens.font.icon.small
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true

                        text: {
                            if (root.downloadingHere && root.activeDownloadName) {
                                return root.activeDownloadName;
                            }

                            if (root.selectedPath) {
                                return root.selectedPath.split("/").pop();
                            }

                            return qsTr("Phone file");
                        }

                        color: Colours.palette.m3onSurface

                        font: Tokens.font.body.small

                        elide: Text.ElideMiddle
                    }

                    StyledText {
                        Layout.fillWidth: true

                        visible: root.downloadingHere || root.downloadStatus !== ""

                        text: {
                            if (root.downloadingHere) {
                                return qsTr("Downloading… %1%").arg(Math.round(KdeConnect.progress * 100));
                            }

                            return root.downloadStatus;
                        }

                        color: Colours.palette.m3onSurfaceVariant

                        font: Tokens.font.body.small

                        elide: Text.ElideMiddle
                    }
                }

                //
                // Download
                //
                StyledRect {
                    visible: root.selectedPath !== "" && !root.selectedIsDir && !root.downloadingHere

                    implicitWidth: downloadText.implicitWidth + Tokens.padding.medium * 2

                    implicitHeight: 32

                    radius: Tokens.rounding.full

                    color: Colours.palette.m3secondaryContainer

                    opacity: KdeConnect.transferring ? 0.5 : 1

                    StyledText {
                        id: downloadText

                        anchors.centerIn: parent

                        text: qsTr("Download")

                        color: Colours.palette.m3onSecondaryContainer

                        font: Tokens.font.body.small
                    }

                    StateLayer {
                        enabled: !KdeConnect.transferring && !root.navigating

                        onClicked: {
                            root.activeDownloadName = root.selectedPath.split("/").pop();

                            root.downloadStatus = "";
                            root.showDownloadCancel = false;

                            downloadCancelTimer.restart();

                            KdeConnect.download(root.deviceId, root.selectedPath);
                        }
                    }
                }

                //
                // Cancel
                //
                StyledRect {
                    visible: root.downloadingHere && root.showDownloadCancel

                    implicitWidth: cancelText.implicitWidth + Tokens.padding.medium * 2

                    implicitHeight: 32

                    radius: Tokens.rounding.full

                    color: Colours.palette.m3secondaryContainer

                    StyledText {
                        id: cancelText

                        anchors.centerIn: parent

                        text: qsTr("Cancel")

                        color: Colours.palette.m3onSecondaryContainer

                        font: Tokens.font.body.small
                    }

                    StateLayer {
                        onClicked: {
                            root.showDownloadCancel = false;

                            KdeConnect.cancel();
                        }
                    }
                }
            }
        }
    }
}
