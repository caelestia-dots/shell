pragma Singleton

import qs.config
import Caelestia.Services
import Caelestia
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    property string previousSinkName: ""
    property string previousSourceName: ""

    readonly property var nodes: Pipewire.nodes.values.reduce((acc, node) => {
        if (!node.isStream) {
            if (node.isSink)
                acc.sinks.push(node);
            else if (node.audio)
                acc.sources.push(node);
        }
        return acc;
    }, {
        sources: [],
        sinks: []
    })

    readonly property list<PwNode> sinks: nodes.sinks
    readonly property list<PwNode> sources: nodes.sources

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    readonly property alias cava: cava
    readonly property alias beatTracker: beatTracker

    function setVolume(newVolume: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, newVolume));
        }
    }

    function incrementVolume(amount: real): void {
        setVolume(volume + (amount || Config.services.audioIncrement));
    }

    function decrementVolume(amount: real): void {
        setVolume(volume - (amount || Config.services.audioIncrement));
    }

    function setSourceVolume(newVolume: real): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(1, newVolume));
        }
    }

    function incrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume + (amount || Config.services.audioIncrement));
    }

    function decrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume - (amount || Config.services.audioIncrement));
    }

    function setAudioSink(newSink: PwNode): void {
        Pipewire.preferredDefaultAudioSink = newSink;
    }

    function setAudioSource(newSource: PwNode): void {
        Pipewire.preferredDefaultAudioSource = newSource;
    }

    PwObjectTracker {
        objects: [...root.sinks, ...root.sources]
    }

    CavaProvider {
        id: cava

        bars: Config.services.visualiserBars
    }

    BeatTracker {
        id: beatTracker
    }

    Connections {
        target: Pipewire

        function onDefaultAudioSinkChanged(): void {
            if (!Config.utilities.audioToasts.outputEnabled) return;
            
            const sink = Pipewire.defaultAudioSink;
            if (!sink || !sink.ready) return;

            const newSinkName = sink.description || sink.name || "Unknown Device";
            
            if (root.previousSinkName && root.previousSinkName !== newSinkName) {
                Toaster.toast(
                    qsTr("Audio Output Changed"), 
                    qsTr("Now using: %1").arg(newSinkName),
                    "volume_up",
                    Toast.Info,
                    Config.utilities.audioToasts.timeout
                );
            }
            
            root.previousSinkName = newSinkName;
        }
    }

    Connections {
        target: Pipewire

        function onDefaultAudioSourceChanged(): void {
            if (!Config.utilities.audioToasts.inputEnabled) return;
            
            const source = Pipewire.defaultAudioSource;
            if (!source || !source.ready) return;

            const newSourceName = source.description || source.name || "Unknown Device";
            
            if (root.previousSourceName && root.previousSourceName !== newSourceName) {
                Toaster.toast(
                    qsTr("Audio Input Changed"), 
                    qsTr("Now using: %1").arg(newSourceName),
                    "mic",
                    Toast.Info,
                    Config.utilities.audioToasts.timeout
                );
            }
            
            root.previousSourceName = newSourceName;
        }
    }

    Component.onCompleted: {
        if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.ready) {
            root.previousSinkName = Pipewire.defaultAudioSink.description || Pipewire.defaultAudioSink.name || "Unknown Device";
        }
        if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.ready) {
            root.previousSourceName = Pipewire.defaultAudioSource.description || Pipewire.defaultAudioSource.name || "Unknown Device";
        }
    }
}
