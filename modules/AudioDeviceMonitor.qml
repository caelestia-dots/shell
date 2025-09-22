import qs.config
import qs.services
import Caelestia
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Scope {
    id: root

    property string previousSinkName: ""
    property string previousSourceName: ""

    Connections {
        target: Pipewire

        function onDefaultAudioSinkChanged(): void {
            if (!Config.utilities.audioNotifications.enabled) return;
            
            const sink = Pipewire.defaultAudioSink;
            if (!sink || !sink.ready) return;

            const newSinkName = sink.description || sink.name || "Unknown Device";
            
            if (root.previousSinkName && root.previousSinkName !== newSinkName) {
                Toaster.toast(
                    qsTr(Config.utilities.audioNotifications.outputChangedTitle), 
                    qsTr(Config.utilities.audioNotifications.outputChangedMessage).arg(newSinkName),
                    Config.utilities.audioNotifications.outputIcon,
                    Toast.Info,
                    Config.utilities.audioNotifications.timeout
                );
            }
            
            root.previousSinkName = newSinkName;
        }
    }

    Connections {
        target: Pipewire

        function onDefaultAudioSourceChanged(): void {
            if (!Config.utilities.audioNotifications.enabled) return;
            
            const source = Pipewire.defaultAudioSource;
            if (!source || !source.ready) return;

            const newSourceName = source.description || source.name || "Unknown Device";
            
            if (root.previousSourceName && root.previousSourceName !== newSourceName) {
                Toaster.toast(
                    qsTr(Config.utilities.audioNotifications.inputChangedTitle), 
                    qsTr(Config.utilities.audioNotifications.inputChangedMessage).arg(newSourceName),
                    Config.utilities.audioNotifications.inputIcon,
                    Toast.Info,
                    Config.utilities.audioNotifications.timeout
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
