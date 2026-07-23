pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Caelestia
import Caelestia.Config
import Caelestia.Services

Singleton {
    id: root

    property string previousSinkName: ""
    property string previousSourceName: ""

    property list<PwNode> sinks: []
    property list<PwNode> sources: []
    property list<PwNode> streams: []

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    // Call volume — controls output volume of calling/communication apps
    // (Discord, Teams, Zoom, etc.) independently of system volume.
    // Edit this list to customize which apps are considered "call" apps.
    // Matches against application.name, application.process.binary, and
    // node name (case-insensitive substring match).
    readonly property var callAppsPatterns: ["discord", "teams-for-linux", "teams", "zoom", "slack", "telegram-desktop", "signal-desktop", "skypeforlinux", "element", "jitsi-meet", "mumble", "webex", "vesktop", "equicord"]

    property real callVolume: 1.0

    readonly property alias cava: cava
    readonly property alias beatTracker: beatTracker

    function getCallStreams() {
        if (!root.streams)
            return [];
        const patterns = callAppsPatterns || [];
        return root.streams.filter(s => {
            if (!s || !s.properties)
                return false;
            // Only target output/playback streams, not microphone capture
            const mediaClass = (s.properties["media.class"] || "");
            if (!mediaClass.startsWith("Stream/Output"))
                return false;
            const appName = (s.properties["application.name"] || "").toLowerCase();
            const binary = (s.properties["application.process.binary"] || "").toLowerCase();
            const nodeName = (s.name || "").toLowerCase();
            return patterns.some(pattern => appName.includes(pattern) || binary.includes(pattern) || nodeName.includes(pattern));
        });
    }

    function setCallVolume(newVolume: real): void {
        root.callVolume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        const streams = getCallStreams();
        if (!streams)
            return;
        for (const s of streams) {
            if (s?.ready && s?.audio) {
                s.audio.muted = false;
                s.audio.volume = root.callVolume;
            }
        }
    }

    function incrementCallVolume(amount: real): void {
        setCallVolume(root.callVolume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementCallVolume(amount: real): void {
        setCallVolume(root.callVolume - (amount || GlobalConfig.services.audioIncrement));
    }

    // Auto-apply call volume when new call streams appear
    function applyCallVolumeToNewStreams(): void {
        if (root.callVolume >= 1.0)
            return;
        const streams = getCallStreams();
        if (!streams)
            return;
        for (const s of streams) {
            if (s?.ready && s?.audio && Math.abs(s.audio.volume - root.callVolume) > 0.01) {
                s.audio.volume = root.callVolume;
            }
        }
    }

    function setVolume(newVolume: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function incrementVolume(amount: real): void {
        setVolume(volume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementVolume(amount: real): void {
        setVolume(volume - (amount || GlobalConfig.services.audioIncrement));
    }

    function setSourceVolume(newVolume: real): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function incrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume - (amount || GlobalConfig.services.audioIncrement));
    }

    function setAudioSink(newSink: PwNode): void {
        Pipewire.preferredDefaultAudioSink = newSink;
    }

    function setAudioSource(newSource: PwNode): void {
        Pipewire.preferredDefaultAudioSource = newSource;
    }

    function cycleNextAudioOutput(): void {
        if (sinks.length === 0)
            return;

        const currentIndex = sinks.findIndex(s => s === sink);
        const nextIndex = (currentIndex + 1) % sinks.length;
        setAudioSink(sinks[nextIndex]);
    }

    function setStreamVolume(stream: PwNode, newVolume: real): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = false;
            stream.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function setStreamMuted(stream: PwNode, muted: bool): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = muted;
        }
    }

    function getStreamVolume(stream: PwNode): real {
        return stream?.audio?.volume ?? 0;
    }

    function getStreamMuted(stream: PwNode): bool {
        return !!stream?.audio?.muted;
    }

    function getStreamName(stream: PwNode): string {
        if (!stream)
            return qsTr("Unknown");
        // Try application name first, then description, then name
        return stream.properties["application.name"] || stream.description || stream.name || qsTr("Unknown Application");
    }

    function refreshNodes(): void {
        const newSinks = [];
        const newSources = [];
        const newStreams = [];

        for (const node of Pipewire.nodes.values) {
            if (!node.isStream) {
                if (node.isSink)
                    newSinks.push(node);
                else if (node.audio)
                    newSources.push(node);
            } else if (node.audio) {
                newStreams.push(node);
            }
        }

        root.sinks = newSinks;
        root.sources = newSources;
        root.streams = newStreams;
        root.applyCallVolumeToNewStreams();
    }

    onSinkChanged: {
        if (!sink?.ready)
            return;

        const newSinkName = sink.description || sink.name || qsTr("Unknown Device");

        if (previousSinkName && previousSinkName !== newSinkName && GlobalConfig.utilities.toasts.audioOutputChanged)
            Toaster.toast(qsTr("Audio output changed"), qsTr("Now using: %1").arg(newSinkName), "volume_up");

        previousSinkName = newSinkName;
    }

    onSourceChanged: {
        if (!source?.ready)
            return;

        const newSourceName = source.description || source.name || qsTr("Unknown Device");

        if (previousSourceName && previousSourceName !== newSourceName && GlobalConfig.utilities.toasts.audioInputChanged)
            Toaster.toast(qsTr("Audio input changed"), qsTr("Now using: %1").arg(newSourceName), "mic");

        previousSourceName = newSourceName;
    }

    // Populate immediately: Pipewire.nodes may already be filled by the time this
    // lazily-loaded singleton is created, so onValuesChanged would never fire.
    Component.onCompleted: {
        refreshNodes();
        previousSinkName = sink?.description || sink?.name || qsTr("Unknown Device");
        previousSourceName = source?.description || source?.name || qsTr("Unknown Device");
    }

    Connections {
        function onValuesChanged(): void {
            root.refreshNodes();
        }

        target: Pipewire.nodes
    }

    // Always track the current defaults so volume/mute bind even if the lists
    // momentarily lag behind the default node.
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.sinks, ...root.sources, ...root.streams].filter(n => n)
    }

    CavaProvider {
        id: cava

        bars: GlobalConfig.services.visualiserBars
    }

    BeatTracker {
        id: beatTracker
    }

    IpcHandler {
        function cycleOutput(): void {
            root.cycleNextAudioOutput();
        }

        target: "audio"
    }
}
