import Quickshell.Io

JsonObject {
    property bool enabled: true
    property int maxToasts: 4

    property Sizes sizes: Sizes {}
    property Toasts toasts: Toasts {}
    property Vpn vpn: Vpn {}

    component Sizes: JsonObject {
        property int width: 430
        property int toastWidth: 430
    }

    component Toasts: JsonObject {
        property bool configLoaded: true
        property bool chargingChanged: true
        property bool gameModeChanged: true
        property bool dndChanged: true
        property bool audioOutputChanged: true
        property bool audioInputChanged: true
        property bool capsLockChanged: true
        property bool numLockChanged: true
        property bool kbLayoutChanged: true
        property bool kbLimit: true
        property bool vpnChanged: true
        property bool nowPlaying: false
    }

    component Vpn: JsonObject {
        property bool enabled: false
        property list<var> provider: ["netbird"]
    }

    property list<var> quickToggles: [
        {
            id: "wifi",
            enabled: true
        },
        {
            id: "bluetooth",
            enabled: true
        },
        {
            id: "mic",
            enabled: true
        },
        {
            id: "settings",
            enabled: true
        },
        {
            id: "gameMode",
            enabled: true
        },
        {
            id: "dnd",
            enabled: true
        },
        {
            id: "vpn",
            enabled: false
        },
        {
            id: "nightLight",
            enabled: false
        }
    ]
}
