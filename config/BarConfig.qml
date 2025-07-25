import Quickshell.Io

JsonObject {
    property bool persistent: true
    property bool showOnHover: true
    property int dragThreshold: 20
    property Workspaces workspaces: Workspaces {}
    property Sizes sizes: Sizes {}

    component Workspaces: JsonObject {
        property int shown: 5
        property bool rounded: true
        property bool activeIndicator: true
        property bool occupiedBg: false
        property bool showWindows: true
        property bool activeTrail: false
        property string label: "  "
        property string occupiedLabel: "󰮯 "
        property string activeLabel: "󰮯 "
    }

    component Sizes: JsonObject {
        property int innerHeight: 30
        property int windowPreviewSize: 400
        property int trayMenuWidth: 300
        property int batteryWidth: 250
        property int networkWidth: 320
    }
}
