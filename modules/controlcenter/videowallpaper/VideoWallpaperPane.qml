pragma ComponentBehavior: Bound

import ".."
import "../components"
import "../../files" as FilesModule
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property Session session

    property string selectedOutput: VideoWallpaper.output
    property string selectedPath: VideoWallpaper.sourceForOutput(VideoWallpaper.output)
    property bool pendingSelection: false
    property string searchText: ""
    readonly property string videoDir: `${Paths.wallsdir}/Videos`
    readonly property var selectedMetadata: VideoWallpaper.metadataFor(selectedPath)
    readonly property bool hasSelection: !!selectedPath
    readonly property bool selectedIsActive: hasSelection && VideoWallpaper.isSourceActive(selectedPath)
    readonly property string selectedName: VideoWallpaper.fileNameFor(selectedPath)
    readonly property var monitorAssignments: {
        const names = Hypr.monitorNames();
        const items = [];
        for (let i = 0; i < names.length; i++) {
            const name = names[i];
            const assignedPath = VideoWallpaper.sourceForOutput(name);
            items.push({
                monitor: name,
                path: assignedPath,
                name: assignedPath ? VideoWallpaper.fileNameFor(assignedPath) : qsTr("No video")
            });
        }
        return items;
    }
    readonly property var outputOptions: {
        const options = [{
                label: "ALL",
                state: root.selectedOutput === "ALL",
                onToggled: function () { root.applyOutput("ALL"); }
            }];
        const monitors = Hypr.monitorNames();
        for (let i = 0; i < monitors.length; i++) {
            const name = monitors[i];
            options.push({
                label: name,
                state: root.selectedOutput === name,
                onToggled: function () { root.applyOutput(name); }
            });
        }
        return options;
    }

    function applyOutput(value) {
        root.selectedOutput = value;
        if (!root.pendingSelection) {
            root.selectedPath = VideoWallpaper.sourceForOutput(value);
        }
    }

    function formatBytes(value) {
        const size = Number(value || 0);
        if (size <= 0)
            return "-";
        const units = ["B", "KB", "MB", "GB", "TB"];
        let index = 0;
        let amount = size;
        while (amount >= 1024 && index < units.length - 1) {
            amount /= 1024;
            index++;
        }
        return `${amount >= 10 || index === 0 ? Math.round(amount) : amount.toFixed(1)} ${units[index]}`;
    }

    function formatDuration(value) {
        const totalSeconds = Math.max(0, Math.round(Number(value || 0)));
        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const seconds = totalSeconds % 60;
        if (hours > 0)
            return `${String(hours).padStart(2, "0")}:${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
        return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
    }

    function parentDirectory(path) {
        const text = String(path || "");
        if (!text)
            return root.videoDir;
        const normalized = text.endsWith("/") ? text.slice(0, -1) : text;
        const lastSlash = normalized.lastIndexOf("/");
        if (lastSlash <= 0)
            return "/";
        return normalized.slice(0, lastSlash);
    }

    function openVideoFolder() {
        FilesModule.WindowFactory.create(null, {
            initialPath: root.videoDir
        });
    }

    function openSelectedInExplorer() {
        if (!root.selectedPath)
            return;
        FilesModule.WindowFactory.create(null, {
            initialPath: parentDirectory(root.selectedPath),
            initialSelectionPath: root.selectedPath
        });
    }

    function outputAssignmentLabel(item) {
        if (!item)
            return "-";
        if (!item.path)
            return qsTr("No video");
        return item.name;
    }

    anchors.fill: parent

    onSelectedPathChanged: {
        if (selectedPath) {
            VideoWallpaper.ensureThumbnail(selectedPath);
            VideoWallpaper.ensureMetadata(selectedPath);
        }
    }

    Connections {
        target: VideoWallpaper

        function onSourceChanged() {
            if (root.selectedOutput === "ALL" && !root.pendingSelection)
                root.selectedPath = VideoWallpaper.sourceForOutput("ALL");
        }

        function onOutputChanged() {
            if (!root.pendingSelection) {
                root.selectedOutput = VideoWallpaper.output;
                root.selectedPath = VideoWallpaper.sourceForOutput(VideoWallpaper.output);
            }
        }

        function onMonitorSourceMapChanged() {
            if (root.selectedOutput !== "ALL" && !root.pendingSelection)
                root.selectedPath = VideoWallpaper.sourceForOutput(root.selectedOutput);
        }

        function onMetadataCacheChanged() {}
    }

    SplitPaneLayout {
        anchors.fill: parent

        leftContent: Component {
            StyledFlickable {
                id: leftFlickable

                flickableDirection: Flickable.VerticalFlick
                contentHeight: leftContent.height

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: leftFlickable
                }

                ColumnLayout {
                    id: leftContent

                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Tokens.spacing.normal

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.smaller

                        StyledText {
                            text: qsTr("Video Wallpaper")
                            font.pointSize: Tokens.font.size.large
                            font.weight: 500
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }

                    StyledClippingRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 220
                        radius: Tokens.rounding.normal
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                        clip: true

                        Item {
                            anchors.fill: parent

                            Image {
                                anchors.fill: parent
                                visible: root.hasSelection
                                source: root.hasSelection ? Qt.resolvedUrl(VideoWallpaper.thumbnailFor(root.selectedPath)) : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: false
                                cache: false

                                onStatusChanged: {
                                    if (status === Image.Error && root.selectedPath)
                                        VideoWallpaper.ensureThumbnail(root.selectedPath);
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(Colours.palette.m3surface.r, Colours.palette.m3surface.g, Colours.palette.m3surface.b, root.hasSelection ? 0.18 : 0.45)
                            }

                            MaterialIcon {
                                anchors.centerIn: parent
                                visible: !root.hasSelection
                                text: "movie"
                                color: Colours.palette.m3onSurfaceVariant
                                font.pointSize: Tokens.font.size.extraLarge * 3
                                fill: 0
                            }

                            Column {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: Tokens.padding.large
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: root.hasSelection ? root.selectedName : qsTr("No video selected")
                                    font.pointSize: Tokens.font.size.large
                                    font.weight: 700
                                    color: Colours.palette.m3onSurface
                                    elide: Text.ElideMiddle
                                }

                                StyledText {
                                    visible: root.hasSelection
                                    text: root.selectedIsActive
                                        ? qsTr("Active on %1").arg(VideoWallpaper.activeOutputsTextForSource(root.selectedPath))
                                        : qsTr("Selected for %1").arg(root.selectedOutput)
                                    color: root.selectedIsActive ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                    font.pointSize: Tokens.font.size.small
                                    font.weight: 600
                                }
                            }
                        }
                    }

                    CollapsibleSection {
                        Layout.fillWidth: true
                        title: qsTr("Selection")
                        expanded: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: root.hasSelection ? root.selectedName : qsTr("No video selected")
                                    font.pointSize: Tokens.font.size.small
                                    font.weight: 600
                                    color: Colours.palette.m3onSurfaceVariant
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }

                                StyledRect {
                                    radius: Tokens.rounding.full
                                    color: VideoWallpaper.running ? Colours.palette.m3primary : Colours.palette.m3surfaceVariant
                                    implicitWidth: backendLabel.implicitWidth + Tokens.padding.large * 2
                                    implicitHeight: backendLabel.implicitHeight + Tokens.padding.smaller * 2

                                    StyledText {
                                        id: backendLabel

                                        anchors.centerIn: parent
                                        text: VideoWallpaper.backendStatus
                                        color: VideoWallpaper.running ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                                        font.pointSize: Tokens.font.size.small
                                        font.weight: 600
                                    }
                                }
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                columnSpacing: Tokens.spacing.small
                                rowSpacing: Tokens.spacing.small

                                component MetricCard: StyledRect {
                                    required property string label
                                    required property string value

                                    Layout.fillWidth: true
                                    radius: Tokens.rounding.normal
                                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)
                                    implicitHeight: metricColumn.implicitHeight + Tokens.padding.normal * 2

                                    ColumnLayout {
                                        id: metricColumn

                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.normal
                                        spacing: Tokens.spacing.smaller / 2

                                        StyledText {
                                            text: parent.parent.label
                                            color: Colours.palette.m3onSurfaceVariant
                                            font.pointSize: Tokens.font.size.small
                                        }

                                        StyledText {
                                            text: parent.parent.value
                                            color: Colours.palette.m3onSurface
                                            font.pointSize: Tokens.font.size.normal
                                            font.weight: 600
                                            elide: Text.ElideMiddle
                                        }
                                    }
                                }

                                MetricCard {
                                    label: qsTr("Target")
                                    value: root.selectedOutput
                                }

                                MetricCard {
                                    label: qsTr("Duration")
                                    value: root.selectedMetadata ? root.formatDuration(root.selectedMetadata.duration) : (root.hasSelection ? qsTr("Loading…") : "-")
                                }

                                MetricCard {
                                    label: qsTr("Resolution")
                                    value: root.selectedMetadata && root.selectedMetadata.width > 0 ? `${root.selectedMetadata.width}×${root.selectedMetadata.height}` : (root.hasSelection ? qsTr("Loading…") : "-")
                                }

                                MetricCard {
                                    label: qsTr("FPS")
                                    value: root.selectedMetadata && root.selectedMetadata.fps > 0 ? Number(root.selectedMetadata.fps).toFixed(2) : "-"
                                }

                                MetricCard {
                                    label: qsTr("Codec")
                                    value: root.selectedMetadata && root.selectedMetadata.codec ? root.selectedMetadata.codec : "-"
                                }

                                MetricCard {
                                    label: qsTr("Size")
                                    value: root.selectedMetadata ? root.formatBytes(root.selectedMetadata.size) : (root.hasSelection ? qsTr("Loading…") : "-")
                                }
                            }
                        }
                    }

                    CollapsibleSection {
                        Layout.fillWidth: true
                        title: qsTr("Actions")
                        expanded: true

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            TextButton {
                                text: qsTr("Apply")
                                enabled: root.hasSelection
                                onClicked: {
                                    VideoWallpaper.applySelection(root.selectedOutput, root.selectedPath);
                                    root.pendingSelection = false;
                                }
                            }

                            TextButton {
                                text: VideoWallpaper.paused ? qsTr("Resume") : qsTr("Pause")
                                enabled: VideoWallpaper.running
                                onClicked: VideoWallpaper.togglePause()
                            }

                            TextButton {
                                text: qsTr("Stop")
                                enabled: VideoWallpaper.running
                                onClicked: VideoWallpaper.stop()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small
                        }
                    }

                    CollapsibleSection {
                        Layout.fillWidth: true
                        title: qsTr("Output")
                        expanded: true

                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: outputLayout.implicitHeight + Tokens.padding.large * 2
                            radius: Tokens.rounding.normal
                            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                            clip: true

                            RowLayout {
                                id: outputLayout

                                anchors.fill: parent
                                anchors.margins: Tokens.padding.large
                                spacing: Tokens.spacing.small

                                Repeater {
                                    model: root.outputOptions

                                    delegate: TextButton {
                                        required property var modelData

                                        Layout.fillWidth: true
                                        text: modelData.label
                                        checked: root.selectedOutput === modelData.label
                                        toggle: false
                                        type: TextButton.Tonal
                                        radius: stateLayer.pressed ? Tokens.rounding.small / 2 : internalChecked ? Tokens.rounding.small : Tokens.rounding.normal
                                        inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
                                        Layout.preferredWidth: implicitWidth + (stateLayer.pressed ? Tokens.padding.large : internalChecked ? Tokens.padding.smaller : 0)

                                        onClicked: modelData.onToggled(true)

                                        Behavior on Layout.preferredWidth {
                                            Anim {
                                                duration: Tokens.anim.durations.expressiveFastSpatial
                                                easing: Tokens.anim.expressiveFastSpatial
                                            }
                                        }

                                        Behavior on radius {
                                            Anim {
                                                duration: Tokens.anim.durations.expressiveFastSpatial
                                                easing: Tokens.anim.expressiveFastSpatial
                                            }
                                        }
                                    }
                                }
                            }
                        }

                    }

                    CollapsibleSection {
                        Layout.fillWidth: true
                        title: qsTr("Playback")
                        expanded: true

                        SplitButtonRow {
                            id: fitModeSelector

                            function syncActiveItem(): void {
                                active = VideoWallpaper.fitMode === "Fit" ? fitModeFitItem : VideoWallpaper.fitMode === "Stretch" ? fitModeStretchItem : fitModeCropItem;
                            }

                            label: qsTr("Fit mode")
                            menuItems: [fitModeCropItem, fitModeFitItem, fitModeStretchItem]

                            Component.onCompleted: syncActiveItem()

                            Connections {
                                target: VideoWallpaper

                                function onFitModeChanged(): void {
                                    fitModeSelector.syncActiveItem();
                                }
                            }

                            MenuItem {
                                id: fitModeCropItem

                                text: qsTr("Crop")
                                icon: "crop"
                                activeText: qsTr("Crop")
                                onClicked: VideoWallpaper.fitMode = "Crop"
                            }

                            MenuItem {
                                id: fitModeFitItem

                                text: qsTr("Fit")
                                icon: "fit_screen"
                                activeText: qsTr("Fit")
                                onClicked: VideoWallpaper.fitMode = "Fit"
                            }

                            MenuItem {
                                id: fitModeStretchItem

                                text: qsTr("Stretch")
                                icon: "open_in_full"
                                activeText: qsTr("Stretch")
                                onClicked: VideoWallpaper.fitMode = "Stretch"
                            }
                        }

                        SwitchRow {
                            label: qsTr("Loop")
                            checked: VideoWallpaper.loop
                            onToggled: checked => VideoWallpaper.loop = checked
                        }

                        SwitchRow {
                            label: qsTr("Start automatically")
                            checked: VideoWallpaper.autoStart
                            onToggled: checked => VideoWallpaper.autoStart = checked
                        }

                        SliderInput {
                            Layout.fillWidth: true
                            label: qsTr("Playback rate")
                            value: VideoWallpaper.playbackRate
                            from: 0.25
                            to: 2.0
                            stepSize: 0.05
                            suffix: "×"
                            decimals: 2
                            validator: DoubleValidator {
                                bottom: 0.25
                                top: 2.0
                                decimals: 2
                            }
                            formatValueFunction: val => Number(val).toFixed(2)
                            parseValueFunction: text => Number(text)
                            onValueModified: newValue => VideoWallpaper.playbackRate = newValue
                        }

                        SliderInput {
                            Layout.fillWidth: true
                            label: qsTr("Fade duration")
                            value: VideoWallpaper.fadeDuration
                            from: 0
                            to: 2000
                            stepSize: 50
                            suffix: "ms"
                            validator: IntValidator {
                                bottom: 0
                                top: 2000
                            }
                            formatValueFunction: val => Math.round(val).toString()
                            parseValueFunction: text => parseInt(text)
                            onValueModified: newValue => VideoWallpaper.fadeDuration = newValue
                        }
                    }
                }
            }
        }

        rightContent: Component {
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.normal

                    RowLayout {
                        Layout.fillWidth: true

                        StyledTextField {
                            Layout.fillWidth: true
                            placeholderText: qsTr("Search videos")
                            text: root.searchText
                            onTextChanged: root.searchText = text
                        }
                    }

                    VideoWallpaperGrid {
                        id: videoGrid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        session: root.session
                        searchText: root.searchText
                        selectedPath: root.selectedPath
                        onSourceSelected: path => {
                            root.selectedPath = path;
                            root.pendingSelection = true;
                        }
                    }
                }
            }
        }
    }
}
