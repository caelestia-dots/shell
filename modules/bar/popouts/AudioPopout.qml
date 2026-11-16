pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property PopoutState popouts
    // "output" or "input". Speaker icon opens "output", mic icon opens "input".
    property string mode: "output"

    readonly property bool isInput: mode === "input"
    readonly property int maxDevices: 5

    // Everything below is picked by mode, so the layout is written once for both
    readonly property var devices: isInput ? Audio.sources : Audio.sinks
    readonly property PwNode device: isInput ? Audio.source : Audio.sink
    readonly property bool muted: isInput ? Audio.sourceMuted : Audio.muted
    readonly property real volume: isInput ? Audio.sourceVolume : Audio.volume
    readonly property var streams: isInput ? Audio.inputStreams : Audio.outputStreams

    // Max 5 devices, always keeping the active one visible
    readonly property var visibleDevices: {
        const sorted = [...devices].sort((a, b) => (a.description || a.name || "").localeCompare(b.description || b.name || ""));
        if (sorted.length <= maxDevices)
            return sorted;

        const shown = sorted.slice(0, maxDevices);
        const activeIdx = sorted.findIndex(d => d.id === device?.id);
        if (activeIdx >= maxDevices)
            shown[maxDevices - 1] = sorted[activeIdx];
        return shown;
    }
    readonly property int hiddenCount: Math.max(0, devices.length - maxDevices)

    property int selectedStreamId: -1
    readonly property PwNode selectedStream: [...streams].find(s => s.id === selectedStreamId) ?? null

    function setVolume(v: real): void {
        if (isInput)
            Audio.setSourceVolume(v);
        else
            Audio.setVolume(v);
    }

    function setMuted(m: bool): void {
        Audio.setStreamMuted(device, m);
    }

    function streamIcon(stream: PwNode): string {
        const p = stream?.properties ?? {};
        const names = [p["application.icon-name"], p["application.process.binary"], p["application.name"]].filter(n => typeof n === "string" && n.length > 0);
        for (const n of names) {
            const entry = DesktopEntries.heuristicLookup(n);
            if (entry)
                return Quickshell.iconPath(entry.icon, "audio-x-generic");
        }
        return Quickshell.iconPath(names[0] ?? "", "audio-x-generic");
    }

    onModeChanged: selectedStreamId = -1

    implicitWidth: Tokens.sizes.bar.audioWidth
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.medium

        // ---- Header: Output / Input ----
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: root.isInput ? Tr.trCtx("Input", "audio input") : Tr.trCtx("Output", "audio output")
                font: Tokens.font.title.medium
            }
        }

        // ---- Devices ----
        SubHeader {
            text: Tr.tr("Devices")
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2

            Repeater {
                model: ScriptModel {
                    values: root.visibleDevices
                }

                DeviceRow {}
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.padding.small
                Layout.bottomMargin: Tokens.padding.small
                visible: root.devices.length === 0
                horizontalAlignment: Text.AlignHCenter
                text: root.isInput ? Tr.trCtx("No input devices", "no audio inputs") : Tr.trCtx("No output devices", "no audio outputs")
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
            }

            // Clue to change the rest of the devices in Nexus
            Item {
                Layout.fillWidth: true
                visible: root.hiddenCount > 0
                implicitHeight: moreLayout.implicitHeight + Tokens.padding.small * 2

                StateLayer {
                    radius: Tokens.rounding.small
                    onClicked: root.popouts.detachRequested("audio")
                }

                RowLayout {
                    id: moreLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    anchors.leftMargin: Tokens.padding.medium
                    anchors.rightMargin: Tokens.padding.medium
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "more_horiz"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.trN("+%n more device", "+%n more devices", root.hiddenCount)
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // ---- Volume ----
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small

            SubHeader {
                Layout.fillWidth: true
                text: Tr.tr("Volume")
            }

            StyledText {
                text: root.muted ? Tr.tr("Muted") : Strings.percentOne(root.volume)
                color: Colours.palette.m3outline
                font: Tokens.font.label.medium
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            IconButton {
                icon: root.isInput ? Icons.getMicVolumeIcon(root.volume, root.muted) : Icons.getVolumeIcon(root.volume, root.muted)
                type: IconButton.Tonal
                checked: root.muted
                onClicked: root.setMuted(!root.muted)
            }

            CustomMouseArea {
                Layout.fillWidth: true
                implicitHeight: Tokens.padding.medium * 3
                opacity: root.muted ? 0.5 : 1

                onWheel: event => {
                    const step = event.angleDelta.y > 0 ? 1 : event.angleDelta.y < 0 ? -1 : 0;
                    if (step !== 0)
                        root.setVolume(root.volume + step * GlobalConfig.services.audioIncrement);
                }

                StyledSlider {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    implicitHeight: parent.implicitHeight

                    value: root.volume
                    onInteraction: value => root.setVolume(value)
                }
            }
        }

        // ---- Applications ----
        SubHeader {
            Layout.topMargin: Tokens.spacing.small
            text: Tr.tr("Applications")
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.padding.small
            visible: root.streams.length === 0
            horizontalAlignment: Text.AlignHCenter
            text: root.isInput ? Tr.tr("No apps using the microphone") : Tr.tr("No apps playing audio")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
        }

        Flickable {
            id: appFlick

            Layout.fillWidth: true
            visible: root.streams.length > 0
            implicitHeight: appRow.implicitHeight + Tokens.padding.extraSmall * 2

            contentWidth: appRow.implicitWidth
            contentHeight: height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            // Mouse wheel scrolls sideways
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    const d = event.angleDelta.y || event.angleDelta.x;
                    appFlick.contentX = Math.max(0, Math.min(appFlick.contentWidth - appFlick.width, appFlick.contentX - d));
                }
            }

            Row {
                id: appRow

                y: Tokens.padding.extraSmall
                spacing: Tokens.spacing.medium

                Repeater {
                    model: ScriptModel {
                        values: [...root.streams]
                    }

                    AppBubble {}
                }
            }
        }

        // Slider for the clicked app only. Expands/collapses vertically.
        Item {
            id: appSlider

            // Keep the last app while collapsing so the content doesn't blank out
            property PwNode shown: null
            property real progress: root.selectedStream ? 1 : 0
            readonly property real p: Math.max(0, Math.min(1, progress))

            Layout.fillWidth: true
            // Cancel the layout gap while collapsed
            Layout.topMargin: -layout.spacing * (1 - p)
            implicitHeight: appSliderContent.implicitHeight * p
            opacity: p
            visible: p > 0
            clip: true

            Connections {
                function onSelectedStreamChanged(): void {
                    if (root.selectedStream)
                        appSlider.shown = root.selectedStream;
                }

                target: root
            }

            Behavior on progress {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }

            ColumnLayout {
                id: appSliderContent

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        Layout.fillWidth: true
                        text: Audio.getStreamName(appSlider.shown)
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: appSlider.shown?.audio?.muted ? Tr.tr("Muted") : Strings.percentOne(appSlider.shown?.audio?.volume ?? 0)
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.medium
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    IconButton {
                        icon: root.isInput ? Icons.getMicVolumeIcon(appSlider.shown?.audio?.volume ?? 0, appSlider.shown?.audio?.muted ?? false) : Icons.getVolumeIcon(appSlider.shown?.audio?.volume ?? 0, appSlider.shown?.audio?.muted ?? false)
                        type: IconButton.Tonal
                        checked: appSlider.shown?.audio?.muted ?? false
                        onClicked: Audio.setStreamMuted(appSlider.shown, !(appSlider.shown?.audio?.muted ?? false))
                    }

                    CustomMouseArea {
                        Layout.fillWidth: true
                        implicitHeight: Tokens.padding.medium * 3
                        opacity: appSlider.shown?.audio?.muted ? 0.5 : 1

                        onWheel: event => {
                            const step = event.angleDelta.y > 0 ? 1 : event.angleDelta.y < 0 ? -1 : 0;
                            if (step !== 0)
                                Audio.setStreamVolume(appSlider.shown, (appSlider.shown?.audio?.volume ?? 0) + step * GlobalConfig.services.audioIncrement);
                        }

                        StyledSlider {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            implicitHeight: parent.implicitHeight

                            value: appSlider.shown?.audio?.volume ?? 0
                            onInteraction: value => Audio.setStreamVolume(appSlider.shown, value)
                        }
                    }
                }
            }
        }

        // ---- Open settings ----
        IconTextButton {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            inactiveColour: Colours.palette.m3primaryContainer
            inactiveOnColour: Colours.palette.m3onPrimaryContainer
            verticalPadding: Tokens.padding.extraSmall
            text: Tr.tr("Open settings")
            icon: "settings"

            onClicked: root.popouts.detachRequested("audio")
        }
    }

    component SubHeader: StyledText {
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.label.medium
    }

    component DeviceRow: Item {
        id: dev

        required property PwNode modelData
        readonly property bool active: dev.modelData?.id === root.device?.id

        Layout.fillWidth: true
        implicitHeight: devLayout.implicitHeight + Tokens.padding.small * 2

        StateLayer {
            radius: Tokens.rounding.small
            color: dev.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
            onClicked: root.isInput ? Audio.setAudioSource(dev.modelData) : Audio.setAudioSink(dev.modelData)
        }

        RowLayout {
            id: devLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: root.isInput ? "mic" : "speaker"
                color: dev.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                fill: dev.active ? 1 : 0
            }

            StyledText {
                Layout.fillWidth: true
                text: dev.modelData?.description || dev.modelData?.name || Tr.trCtx("Unknown", "unknown audio device")
                color: dev.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            MaterialIcon {
                text: "check"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
                opacity: dev.active ? 1 : 0
            }
        }
    }

    component AppBubble: Item {
        id: app

        required property PwNode modelData
        readonly property bool selected: app.modelData?.id === root.selectedStreamId

        implicitWidth: 44
        implicitHeight: 44

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.full
            color: app.selected ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainer, 2)
        }

        IconImage {
            anchors.centerIn: parent
            asynchronous: true
            implicitSize: 26
            source: root.streamIcon(app.modelData)
            opacity: app.modelData?.audio?.muted ? 0.4 : 1
        }

        // Selection ring
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Colours.palette.m3primary
            opacity: app.selected ? 1 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        StateLayer {
            radius: Tokens.rounding.full
            // Click again to deselect
            onClicked: root.selectedStreamId = app.selected ? -1 : (app.modelData?.id ?? -1)
        }
    }
}
