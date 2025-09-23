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
        property bool outputEnabled: true
        property bool inputEnabled: true
        property int timeout: 3000
    }
}
