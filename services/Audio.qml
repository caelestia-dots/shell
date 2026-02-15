pragma Singleton

import qs.config
import "../components/misc"
import Caelestia.Services
import Caelestia
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    property string previousSinkName: ""
    property string previousSourceName: ""

    CustomShortcut {
        name: "volumeUp"
        description: "Increase volume"
        onPressed: root.incrementVolume()
    }

    CustomShortcut {
        name: "volumeDown"
        description: "Decrease volume"
        onPressed: root.decrementVolume()
    }

    CustomShortcut {
        name: "volumeMute"
        description: "Toggle mute"
        onPressed: {
            if (sink?.audio) {
                sink.audio.muted = !sink.audio.muted;
            }
        }
    }

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

    readonly property var sinks: nodes.sinks
    readonly property var sources: nodes.sources

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    readonly property alias cava: cava
    readonly property alias beatTracker: beatTracker

    function setVolume(newVolume) {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(Config.services.maxVolume, newVolume));
        }
    }

    function incrementVolume(amount) {
        setVolume(volume + (amount || Config.services.audioIncrement));
    }

    function decrementVolume(amount) {
        setVolume(volume - (amount || Config.services.audioIncrement));
    }

    function setSourceVolume(newVolume) {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(Config.services.maxVolume, newVolume));
        }
    }

    function incrementSourceVolume(amount) {
        setSourceVolume(sourceVolume + (amount || Config.services.audioIncrement));
    }

    function decrementSourceVolume(amount) {
        setSourceVolume(sourceVolume - (amount || Config.services.audioIncrement));
    }

    function setAudioSink(newSink) {
        Pipewire.preferredDefaultAudioSink = newSink;
    }

    function setAudioSource(newSource) {
        Pipewire.preferredDefaultAudioSource = newSource;
    }

    onSinkChanged: {
        if (!sink?.ready)
            return;

        const newSinkName = sink.description || sink.name || qsTr("Unknown Device");

        if (previousSinkName && previousSinkName !== newSinkName && Config.utilities.toasts.audioOutputChanged)
            Toaster.toast(qsTr("Audio output changed"), qsTr("Now using: %1").arg(newSinkName), "volume_up");

        previousSinkName = newSinkName;
    }

    onSourceChanged: {
        if (!source?.ready)
            return;

        const newSourceName = source.description || source.name || qsTr("Unknown Device");

        if (previousSourceName && previousSourceName !== newSourceName && Config.utilities.toasts.audioInputChanged)
            Toaster.toast(qsTr("Audio input changed"), qsTr("Now using: %1").arg(newSourceName), "mic");

        previousSourceName = newSourceName;
    }

    Component.onCompleted: {
        previousSinkName = sink?.description || sink?.name || qsTr("Unknown Device");
        previousSourceName = source?.description || source?.name || qsTr("Unknown Device");
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
}
