import Quickshell.Io

JsonObject {
    property bool enabled: true
    property int dragThreshold: 80
    property Sizes sizes: Sizes {}

    component Sizes: JsonObject {
        property int width: 430
    }
}
