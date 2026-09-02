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
    property string selectedPath: ""
    property bool selectedIsDir: false

    property string activeDownloadName: ""
    property string downloadStatus: ""
    property bool showDownloadCancel: false

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

    function resetBrowser(): void {
        root.currentPath = root.rootPath;
        root.selectedPath = "";
        root.selectedIsDir = false;
        root.downloadStatus = "";

        fileView.currentIndex = -1;

        //
        // A download may still be running even though the
        // browser page was temporarily left.
        //
        if (root.downloadingHere) {
            //
            // If the original 1.5s timer is still running,
            // preserve the delay.
            //
            // If there is no timer anymore, the transfer
            // has already been running long enough, so
            // Cancel should be available immediately.
            //
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

    function openDirectory(path: string): void {
        if (!root.insideRoot(path))
            return;

        root.selectedPath = "";
        root.selectedIsDir = false;
        root.downloadStatus = "";

        root.currentPath = path;
    }

    function back(): void {
        //
        // Root folder -> back to Utilities.
        //
        if (root.atRoot) {
            root.wrapper.closeBrowser();
            return;
        }

        const index = root.currentPath.lastIndexOf("/");

        if (index <= 0) {
            root.currentPath = root.rootPath;

            root.selectedPath = "";
            root.selectedIsDir = false;
            root.downloadStatus = "";

            return;
        }

        const parentPath = root.currentPath.slice(0, index);

        root.currentPath = root.insideRoot(parentPath) ? parentPath : root.rootPath;

        root.selectedPath = "";
        root.selectedIsDir = false;
        root.downloadStatus = "";
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

    Connections {
        target: root.wrapper

        function onBrowserOpened() {
            root.resetBrowser();
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

    ColumnLayout {
        anchors.fill: parent

        spacing: Tokens.spacing.medium

        //
        // ============================================
        // Device / navigation card
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
                // Back button.
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
                        onTapped: root.back()
                    }
                }

                //
                // Same circular icon language used by
                // Utilities cards.
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

                    StyledText {
                        Layout.fillWidth: true

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
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Tokens.rounding.large

            color: Colours.tPalette.m3surfaceContainer

            clip: true

            StyledText {
                anchors.centerIn: parent

                visible: fileView.count === 0

                text: qsTr("This folder is empty")

                color: Colours.palette.m3onSurfaceVariant

                font: Tokens.font.body.small
            }

            GridView {
                id: fileView

                anchors.fill: parent

                anchors.margins: Tokens.padding.small

                clip: true
                focus: true

                currentIndex: -1

                cellWidth: width / root.columnCount

                cellHeight: 92

                boundsBehavior: Flickable.StopAtBounds

                model: FileSystemModel {
                    path: root.currentPath

                    onPathChanged: fileView.currentIndex = -1
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
                        id: entryCard

                        anchors.fill: parent

                        anchors.margins: 3

                        radius: Tokens.rounding.medium

                        color: entry.GridView.isCurrentItem ? Colours.palette.m3secondaryContainer : entryHover.hovered ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

                        ColumnLayout {
                            anchors.centerIn: parent

                            width: parent.width - Tokens.padding.small * 2

                            spacing: Tokens.spacing.small

                            //
                            // Utilities-style round icon surface.
                            //
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
                            enabled: entry.valid

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
            // Real progress fill.
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

                //
                // Utilities-style icon.
                //
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
                // Download action pill.
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
                        enabled: !KdeConnect.transferring

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
                // Cancel action.
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
