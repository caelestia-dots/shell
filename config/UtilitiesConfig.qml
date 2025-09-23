import Quickshell.Io

JsonObject {
    property bool enabled: true
    property int maxToasts: 4

    property Sizes sizes: Sizes {}
    property AudioToasts audioToasts: AudioToasts {}

    component Sizes: JsonObject {
        property int width: 430
    }

    component AudioToasts: JsonObject {
        property bool enabled: true
        property string outputChangedTitle: "Audio Output Changed"
        property string inputChangedTitle: "Audio Input Changed"
        property string outputChangedMessage: "Now using: %1"
        property string inputChangedMessage: "Now using: %1"
        property string outputIcon: "volume_up"
        property string inputIcon: "mic"
        property int timeout: 3000
    }
}
