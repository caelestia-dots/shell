pragma ComponentBehavior: Bound

import ".."
import QtQuick
import Caelestia.Models
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

GridView {
    id: root

    required property Session session

    property string searchText: ""
    property string sortMode: "name"
    property string selectedPath: ""

    signal sourceSelected(string path)
    readonly property string videoDir: `${Paths.wallsdir}/Videos`
    readonly property int minCellWidth: 200 + Tokens.spacing.normal
    readonly property int columnsCount: Math.max(1, Math.floor(width / minCellWidth))
    readonly property var allowedSuffixes: ["mp4", "mkv", "webm", "mov", "avi", "m4v"]
    readonly property var videoEntries: buildEntries()

    function modifiedStamp(entry) {
        const raw = entry.lastModifiedMs || entry.lastModified || entry.modified || entry.mtime || 0;
        const numeric = Number(raw);
        if (!isNaN(numeric) && numeric > 0)
            return numeric;
        const parsed = Date.parse(String(raw || ""));
        return isNaN(parsed) ? 0 : parsed;
    }

    function buildEntries() {
        const entries = [];
        const sourceEntries = sourceModel.entries || [];
        const needle = String(searchText || "").trim().toLowerCase();

        for (let i = 0; i < sourceEntries.length; i++) {
            const entry = sourceEntries[i];
            if (!entry || entry.isDir)
                continue;
            const suffix = String(entry.suffix || "").toLowerCase();
            if (!allowedSuffixes.includes(suffix))
                continue;
            if (needle.length > 0 && String(entry.name || "").toLowerCase().indexOf(needle) === -1)
                continue;
            entries.push(entry);
        }

        entries.sort((a, b) => {
            switch (sortMode) {
            case "recent":
                return modifiedStamp(b) - modifiedStamp(a);
            case "duration": {
                const aMeta = VideoWallpaper.metadataFor(a.path);
                const bMeta = VideoWallpaper.metadataFor(b.path);
                const delta = Number(bMeta ? bMeta.duration : 0) - Number(aMeta ? aMeta.duration : 0);
                if (delta !== 0)
                    return delta;
                break;
            }
            case "resolution": {
                const aMeta = VideoWallpaper.metadataFor(a.path);
                const bMeta = VideoWallpaper.metadataFor(b.path);
                const delta = Number(bMeta ? bMeta.resolutionPixels : 0) - Number(aMeta ? aMeta.resolutionPixels : 0);
                if (delta !== 0)
                    return delta;
                break;
            }
            default:
                break;
            }
            return String(a.name || "").localeCompare(String(b.name || ""), undefined, { sensitivity: "base" });
        });

        return entries;
    }

    function visiblePaths(limit) {
        const paths = [];
        const maxItems = Math.max(0, Number(limit || 0));
        const total = videoEntries.length;
        if (!total)
            return paths;

        const firstRow = Math.max(0, Math.floor(contentY / cellHeight));
        const lastRow = Math.max(firstRow, Math.ceil((contentY + height) / cellHeight));
        const firstIndex = Math.max(0, firstRow * columnsCount);
        const lastIndex = Math.min(total, (lastRow + 1) * columnsCount);
        for (let i = firstIndex; i < lastIndex; i++) {
            paths.push(videoEntries[i].path);
            if (maxItems > 0 && paths.length >= maxItems)
                break;
        }
        return paths;
    }

    function assignedOutputsForSource(path) {
        if (!path)
            return [];

        const names = Hypr.monitorNames();
        const matches = [];
        for (let i = 0; i < names.length; i++) {
            if (VideoWallpaper.sourceForOutput(names[i]) === path)
                matches.push(names[i]);
        }
        return matches;
    }

    function assignedOutputsLabel(path) {
        const outputs = assignedOutputsForSource(path);
        if (!outputs.length)
            return "";
        if (outputs.length === 1)
            return outputs[0];
        return qsTr("%1 monitors").arg(outputs.length);
    }

    function assignedOutputsTooltip(path) {
        const outputs = assignedOutputsForSource(path);
        if (!outputs.length)
            return "";
        return outputs.join("\n");
    }

    cellWidth: width / columnsCount
    cellHeight: 140 + Tokens.spacing.normal
    model: root.videoEntries
    clip: true

    FileSystemModel {
        id: sourceModel

        path: root.videoDir
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    onVideoEntriesChanged: {
        const paths = [];
        for (let i = 0; i < videoEntries.length && i < 12; i++)
            paths.push(videoEntries[i].path);
        VideoWallpaper.preloadMetadata(paths);
    }

    delegate: Item {
        id: delegateRoot

        required property var modelData
        required property int index

        readonly property bool isSelected: modelData && modelData.path === root.selectedPath
        readonly property bool isActive: modelData && VideoWallpaper.isSourceActive(modelData.path)
        readonly property var assignedOutputs: modelData ? root.assignedOutputsForSource(modelData.path) : []
        readonly property string assignedOutputsLabel: modelData ? root.assignedOutputsLabel(modelData.path) : ""
        readonly property string assignedOutputsTooltip: modelData ? root.assignedOutputsTooltip(modelData.path) : ""
        readonly property string thumbnailSource: modelData ? VideoWallpaper.thumbnailFor(modelData.path) : ""
        readonly property real itemMargin: Tokens.spacing.normal / 2
        readonly property real itemRadius: Tokens.rounding.normal

        width: root.cellWidth
        height: root.cellHeight

        StateLayer {
            onClicked: {
                root.sourceSelected(modelData.path);
            }

            anchors.fill: parent
            anchors.leftMargin: itemMargin
            anchors.rightMargin: itemMargin
            anchors.topMargin: itemMargin
            anchors.bottomMargin: itemMargin
            radius: itemRadius
        }

        StyledClippingRect {
            anchors.fill: parent
            anchors.leftMargin: itemMargin
            anchors.rightMargin: itemMargin
            anchors.topMargin: itemMargin
            anchors.bottomMargin: itemMargin
            color: Colours.tPalette.m3surfaceContainer
            radius: itemRadius
            antialiasing: true
            layer.enabled: true
            layer.smooth: true

            Item {
                anchors.fill: parent

                Image {
                    anchors.fill: parent
                    visible: thumbnailSource.length > 0
                    source: Qt.resolvedUrl(thumbnailSource)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: false
                    cache: false

                    onStatusChanged: {
                        if (status === Image.Error)
                            VideoWallpaper.ensureThumbnail(modelData.path);
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -Tokens.padding.large
                    visible: thumbnailSource.length === 0
                    text: "movie"
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.size.extraLarge * 3
                    fill: 0
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                implicitHeight: filenameText.implicitHeight + Tokens.padding.normal * 1.5
                radius: 0

                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(Colours.palette.m3surface.r, Colours.palette.m3surface.g, Colours.palette.m3surface.b, 0) }
                    GradientStop { position: 0.3; color: Qt.rgba(Colours.palette.m3surface.r, Colours.palette.m3surface.g, Colours.palette.m3surface.b, 0.7) }
                    GradientStop { position: 0.6; color: Qt.rgba(Colours.palette.m3surface.r, Colours.palette.m3surface.g, Colours.palette.m3surface.b, 0.9) }
                    GradientStop { position: 1.0; color: Qt.rgba(Colours.palette.m3surface.r, Colours.palette.m3surface.g, Colours.palette.m3surface.b, 0.95) }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: itemMargin
            anchors.rightMargin: itemMargin
            anchors.topMargin: itemMargin
            anchors.bottomMargin: itemMargin
            color: "transparent"
            radius: itemRadius + border.width
            border.width: isSelected ? 2 : 0
            border.color: Colours.palette.m3primary
            antialiasing: true
            smooth: true

            Behavior on border.width {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: Tokens.padding.small
                visible: isActive
                radius: Tokens.rounding.full
                color: Qt.rgba(Colours.palette.m3primary.r, Colours.palette.m3primary.g, Colours.palette.m3primary.b, 0.95)
                implicitWidth: activeLabel.implicitWidth + Tokens.padding.normal * 2
                implicitHeight: activeLabel.implicitHeight + Tokens.padding.small

                StyledText {
                    id: activeLabel

                    anchors.centerIn: parent
                    text: qsTr("Active")
                    color: Colours.palette.m3onPrimary
                    font.pointSize: Tokens.font.size.small
                    font.weight: 700
                }
            }

            Rectangle {
                id: assignedBadge

                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.small
                visible: assignedOutputs.length > 0
                radius: Tokens.rounding.full
                color: Qt.rgba(Colours.palette.m3secondaryContainer.r, Colours.palette.m3secondaryContainer.g, Colours.palette.m3secondaryContainer.b, 0.95)
                implicitWidth: assignedLabel.implicitWidth + Tokens.padding.normal * 2
                implicitHeight: assignedLabel.implicitHeight + Tokens.padding.small

                StyledText {
                    id: assignedLabel

                    anchors.centerIn: parent
                    text: assignedOutputsLabel
                    color: Colours.palette.m3onSecondaryContainer
                    font.pointSize: Tokens.font.size.small
                    font.weight: 700
                }

                MouseArea {
                    id: assignedBadgeHover

                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    cursorShape: Qt.PointingHandCursor
                    enabled: delegateRoot.assignedOutputs.length > 1
                }

                Tooltip {
                    target: assignedBadgeHover
                    text: delegateRoot.assignedOutputsTooltip
                    delay: 250
                }
            }

            MaterialIcon {
                id: currentIcon

                anchors.centerIn: parent
                visible: isSelected
                text: "check_circle"
                color: Colours.palette.m3primary
                font.pointSize: Tokens.font.size.extraLarge
                fill: 1
            }
        }

        StyledText {
            id: filenameText

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: Tokens.padding.normal + Tokens.spacing.normal / 2
            anchors.rightMargin: Tokens.padding.normal + Tokens.spacing.normal / 2
            anchors.bottomMargin: Tokens.padding.normal
            text: modelData.name
            font.pointSize: Tokens.font.size.smaller
            font.weight: 500
            color: isSelected ? Colours.palette.m3primary : Colours.palette.m3onSurface
            elide: Text.ElideMiddle
            maximumLineCount: 1
            horizontalAlignment: Text.AlignHCenter
        }

        MouseArea {
            id: filenameHover

            anchors.left: filenameText.left
            anchors.right: filenameText.right
            anchors.top: filenameText.top
            anchors.bottom: filenameText.bottom
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.PointingHandCursor
        }

        Tooltip {
            target: filenameHover
            text: String(delegateRoot.modelData?.name || "")
            delay: 350
        }

    }
}
