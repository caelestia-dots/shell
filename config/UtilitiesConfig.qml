import Quickshell.Io

JsonObject {
    property bool enabled: true
    property int maxToasts: 4

    property Sizes sizes: Sizes {}
    property Toasts toasts: Toasts {}

    component Sizes: JsonObject {
        property int width: 430
    }

    component Toasts: JsonObject {
        property bool audioOutputChanged: true
        property bool audioInputChanged: true
    }
}
