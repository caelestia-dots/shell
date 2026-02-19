import Quickshell.Io

JsonObject {
    property bool enabled: true
    property int dragThreshold: 30
    property bool vimKeybinds: false
    property Icons icons: Icons {}
    property Commands commands: Commands {}

    property Sizes sizes: Sizes {}

    component Icons: JsonObject {
        property string logout: "logout"
        property string shutdown: "power_settings_new"
        property string hibernate: "downloading"
        property string reboot: "cached"
    }

    component Commands: JsonObject {
        property list<string> logout: ["loginctl", "terminate-user", ""]
        property list<string> shutdown: ["systemctl", "poweroff"]
        property list<string> hibernate: ["systemctl", "hibernate"]
        property list<string> reboot: ["systemctl", "reboot"]
    }

    component Sizes: JsonObject {
        property int button: 80
    }
}
