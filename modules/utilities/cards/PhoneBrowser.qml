pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.services

FloatingWindow {
    id: root

    property string deviceId: ""
    property string deviceName: ""
    property string rootPath: ""

    property string currentPath: ""
    property string selectedPath: ""
    property bool selectedIsDir: false

    property string activeDownloadName: ""
    property string downloadStatus: ""
    property bool showDownloadCancel: false

    readonly property bool downloadingHere:
        KdeConnect.receiving
        && KdeConnect.receivingDevice === root.deviceId

    title: `${deviceName} — Phone Files`

    visible: false

    implicitWidth: 840
    implicitHeight: 560

    color: "transparent"

    readonly property bool atRoot:
        currentPath === rootPath

    readonly property string displayPath: {
        if (!currentPath || currentPath === rootPath)
            return "/";

        const relative =
            currentPath.slice(rootPath.length);

        return relative.length > 0
            ? relative
            : "/";
    }

    function openForDevice(
        deviceId: string,
        deviceName: string,
        rootPath: string
    ): void {
        root.deviceId = deviceId;
        root.deviceName = deviceName;
        root.rootPath = rootPath;

        root.currentPath = rootPath;
        root.selectedPath = "";
        root.selectedIsDir = false;

        root.downloadStatus = "";

        root.visible = true;
    }

    function insideRoot(path: string): bool {
        return path === root.rootPath
            || path.startsWith(
                root.rootPath + "/"
            );
    }

    function openDirectory(path: string): void {
        if (!root.insideRoot(path))
            return;

        root.selectedPath = "";
        root.selectedIsDir = false;
        root.downloadStatus = "";

        root.currentPath = path;
    }

    function goBack(): void {
        if (root.atRoot)
            return;

        const index =
            root.currentPath.lastIndexOf("/");

        if (index <= 0) {
            root.currentPath =
                root.rootPath;

            root.selectedPath = "";
            root.selectedIsDir = false;
            root.downloadStatus = "";

            return;
        }

        const parentPath =
            root.currentPath.slice(0, index);

        root.currentPath =
            root.insideRoot(parentPath)
                ? parentPath
                : root.rootPath;

        root.selectedPath = "";
        root.selectedIsDir = false;
        root.downloadStatus = "";
    }

    function iconFor(
        isDir: bool,
        mimeType: string
    ): string {
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

        if (mimeType.includes("zip")
                || mimeType.includes("compressed")
                || mimeType.includes("archive")) {
            return "archive";
        }

        return "draft";
    }

    Connections {
        target: KdeConnect

        function onDownloaded(
            device,
            destinationPath
        ) {
            if (device !== root.deviceId)
                return;

            downloadCancelTimer.stop();

            root.showDownloadCancel = false;
            root.activeDownloadName = "";

            root.downloadStatus =
                qsTr("Saved to %1")
                    .arg(destinationPath);
        }

        function onDownloadFailed(
            device,
            error
        ) {
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

            root.downloadStatus =
                qsTr("Download cancelled");
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

    StyledRect {
        anchors.fill: parent

        radius: Tokens.rounding.large
        color:
            Colours.tPalette.m3surfaceContainer

        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins:
                Tokens.padding.large

            spacing: Tokens.spacing.medium

            //
            // Header
            //
            RowLayout {
                Layout.fillWidth: true

                spacing: Tokens.spacing.medium

                StyledRect {
                    implicitWidth: 40
                    implicitHeight: 40

                    radius:
                        Tokens.rounding.full

                    color:
                        backHover.hovered
                            && !root.atRoot
                        ? Colours.palette.m3secondaryContainer
                        : "transparent"

                    opacity:
                        root.atRoot
                            ? 0.4
                            : 1

                    MaterialIcon {
                        anchors.centerIn: parent

                        text: "arrow_back"

                        color:
                            Colours.palette.m3onSurface

                        fontStyle:
                            Tokens.font.icon.small
                    }

                    HoverHandler {
                        id: backHover
                    }

                    TapHandler {
                        enabled: !root.atRoot

                        onTapped:
                            root.goBack()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true

                        text: root.deviceName

                        color:
                            Colours.palette.m3onSurface

                        font:
                            Tokens.font.body.medium

                        elide:
                            Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true

                        text: root.displayPath

                        color:
                            Colours.palette.m3onSurfaceVariant

                        font:
                            Tokens.font.body.small

                        elide:
                            Text.ElideMiddle
                    }
                }

                StyledRect {
                    implicitWidth: 40
                    implicitHeight: 40

                    radius:
                        Tokens.rounding.full

                    color:
                        closeHover.hovered
                        ? Colours.palette.m3secondaryContainer
                        : "transparent"

                    MaterialIcon {
                        anchors.centerIn: parent

                        text: "close"

                        color:
                            Colours.palette.m3onSurface

                        fontStyle:
                            Tokens.font.icon.small
                    }

                    HoverHandler {
                        id: closeHover
                    }

                    TapHandler {
                        onTapped:
                            root.visible = false
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1

                color:
                    Colours.palette.m3outlineVariant
            }

            //
            // Files
            //
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                StyledText {
                    anchors.centerIn: parent

                    visible:
                        fileView.count === 0

                    text:
                        qsTr("This folder is empty")

                    color:
                        Colours.palette.m3outline

                    font:
                        Tokens.font.body.medium
                }

                GridView {
                    id: fileView

                    anchors.fill: parent

                    clip: true
                    focus: true

                    currentIndex: -1

                    cellWidth: 140
                    cellHeight: 120

                    model: FileSystemModel {
                        path: root.currentPath

                        onPathChanged:
                            fileView.currentIndex = -1
                    }

                    delegate: StyledRect {
                        id: entry

                        required property int index
                        required property FileSystemEntry modelData

                        readonly property bool valid:
                            entry.modelData !== null

                        readonly property string entryPath:
                            entry.valid
                                ? entry.modelData.path
                                : ""

                        readonly property string entryName:
                            entry.valid
                                ? entry.modelData.name
                                : ""

                        readonly property bool entryIsDir:
                            entry.valid
                                ? entry.modelData.isDir
                                : false

                        readonly property string entryMimeType:
                            entry.valid
                                ? entry.modelData.mimeType
                                : ""

                        width:
                            fileView.cellWidth
                            - Tokens.spacing.small

                        height:
                            fileView.cellHeight
                            - Tokens.spacing.small

                        radius:
                            Tokens.rounding.medium

                        clip: true

                        color:
                            entry.GridView.isCurrentItem
                            ? Colours.palette.m3secondaryContainer
                            : "transparent"

                        ColumnLayout {
                            anchors.fill: parent

                            anchors.margins:
                                Tokens.padding.medium

                            spacing:
                                Tokens.spacing.small

                            MaterialIcon {
                                Layout.alignment:
                                    Qt.AlignHCenter

                                text:
                                    root.iconFor(
                                        entry.entryIsDir,
                                        entry.entryMimeType
                                    )

                                color:
                                    entry.entryIsDir
                                    ? Colours.palette.m3primary
                                    : Colours.palette.m3onSurfaceVariant

                                fontStyle:
                                    Tokens.font.icon.large
                            }

                            StyledText {
                                Layout.fillWidth: true

                                text:
                                    entry.entryName

                                horizontalAlignment:
                                    Text.AlignHCenter

                                color:
                                    Colours.palette.m3onSurface

                                font:
                                    Tokens.font.body.small

                                elide:
                                    Text.ElideRight
                            }
                        }

                        StateLayer {
                            enabled: entry.valid

                            onClicked: {
                                if (!entry.valid)
                                    return;

                                fileView.currentIndex =
                                    entry.index;

                                root.selectedPath =
                                    entry.entryPath;

                                root.selectedIsDir =
                                    entry.entryIsDir;

                                root.downloadStatus = "";
                            }

                            onDoubleClicked: {
                                if (!entry.valid)
                                    return;

                                if (entry.entryIsDir) {
                                    root.openDirectory(
                                        entry.entryPath
                                    );

                                    return;
                                }

                                Quickshell.execDetached([
                                    "xdg-open",
                                    entry.entryPath
                                ]);
                            }
                        }
                    }
                }
            }

            //
            // Selected item / transfer
            //
            StyledRect {
                Layout.fillWidth: true

                visible:
                    root.selectedPath !== ""
                    || root.downloadingHere
                    || root.downloadStatus !== ""

                implicitHeight:
                    selectedLayout.implicitHeight
                    + Tokens.padding.medium * 2

                radius:
                    Tokens.rounding.medium

                color:
                    Colours.tPalette.m3surfaceContainerHigh

                clip: true

                //
                // Actual phone -> PC transfer progress.
                //
                StyledRect {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left

                    width:
                        root.downloadingHere
                        ? parent.width
                            * KdeConnect.progress
                        : 0

                    radius:
                        parent.radius

                    color:
                        Colours.palette.m3primaryContainer

                    opacity:
                        root.downloadingHere
                            ? 0.65
                            : 0
                }

                RowLayout {
                    id: selectedLayout

                    anchors.fill: parent

                    anchors.margins:
                        Tokens.padding.medium

                    spacing:
                        Tokens.spacing.medium

                    MaterialIcon {
                        text:
                            root.downloadingHere
                                ? "download"
                                : root.selectedIsDir
                                    ? "folder"
                                    : "description"

                        color:
                            Colours.palette.m3onSurfaceVariant

                        fontStyle:
                            Tokens.font.icon.small
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true

                            text: {
                                if (root.downloadingHere
                                        && root.activeDownloadName) {
                                    return root.activeDownloadName;
                                }

                                if (root.selectedPath) {
                                    return root.selectedPath
                                        .split("/")
                                        .pop();
                                }

                                return qsTr("Phone file");
                            }

                            color:
                                Colours.palette.m3onSurface

                            font:
                                Tokens.font.body.small

                            elide:
                                Text.ElideMiddle
                        }

                        StyledText {
                            Layout.fillWidth: true

                            visible:
                                root.downloadingHere
                                || root.downloadStatus !== ""

                            text: {
                                if (root.downloadingHere) {
                                    return qsTr(
                                        "Downloading… %1%"
                                    ).arg(
                                        Math.round(
                                            KdeConnect.progress
                                                * 100
                                        )
                                    );
                                }

                                return root.downloadStatus;
                            }

                            color:
                                Colours.palette.m3onSurfaceVariant

                            font:
                                Tokens.font.body.small

                            elide:
                                Text.ElideMiddle
                        }
                    }

                    //
                    // Download to PC
                    //
                    StyledRect {
                        visible:
                            root.selectedPath !== ""
                            && !root.selectedIsDir
                            && !root.downloadingHere

                        implicitWidth:
                            downloadText.implicitWidth
                            + Tokens.padding.medium * 2

                        implicitHeight:
                            downloadText.implicitHeight
                            + Tokens.padding.medium

                        radius:
                            Tokens.rounding.full

                        color:
                            Colours.palette.m3secondaryContainer

                        opacity:
                            KdeConnect.transferring
                                ? 0.5
                                : 1

                        StyledText {
                            id: downloadText

                            anchors.centerIn: parent

                            text:
                                qsTr("Download to PC")

                            color:
                                Colours.palette.m3onSecondaryContainer

                            font:
                                Tokens.font.body.small
                        }

                        StateLayer {
                            enabled:
                                !KdeConnect.transferring

                            onClicked: {
                                root.activeDownloadName =
                                    root.selectedPath
                                        .split("/")
                                        .pop();

                                root.downloadStatus = "";
                                root.showDownloadCancel = false;

                                //
                                // Start this first so a synchronous
                                // failure can stop it again.
                                //
                                downloadCancelTimer.restart();

                                KdeConnect.download(
                                    root.deviceId,
                                    root.selectedPath
                                );
                            }
                        }
                    }

                    //
                    // Cancel download after 1.5 seconds.
                    //
                    StyledRect {
                        visible:
                            root.downloadingHere
                            && root.showDownloadCancel

                        implicitWidth:
                            cancelText.implicitWidth
                            + Tokens.padding.medium * 2

                        implicitHeight:
                            cancelText.implicitHeight
                            + Tokens.padding.medium

                        radius:
                            Tokens.rounding.full

                        color:
                            Colours.palette.m3secondaryContainer

                        StyledText {
                            id: cancelText

                            anchors.centerIn: parent

                            text: qsTr("Cancel")

                            color:
                                Colours.palette.m3onSecondaryContainer

                            font:
                                Tokens.font.body.small
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
}
