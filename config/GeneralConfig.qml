import Quickshell.Io

JsonObject {
    property string logo: ""
    property Apps apps: Apps {}
    property Idle idle: Idle {}
    property Battery battery: Battery {}
    

    component PowerActionSchema: JsonObject {
        property string setPowerProfile: ""
        property string setRefreshRate: ""
        property string disableAnimations: ""
        property string disableBlur: ""
        property string disableRounding: ""
        property string disableShadows: ""
    }
    
    component ChargingBehavior: PowerActionSchema {
        setPowerProfile: "restore"
        setRefreshRate: "restore"
    }
    
    component UnpluggedBehavior: PowerActionSchema {
        setPowerProfile: "restore"
        setRefreshRate: "restore"
        property bool evaluateThresholds: true
    }
    
    component ProfileBehavior: PowerActionSchema {
    }
    
    component ProfileBehaviors: JsonObject {
        property ProfileBehavior powerSaver: ProfileBehavior {}
        property ProfileBehavior balanced: ProfileBehavior {}
        property ProfileBehavior performance: ProfileBehavior {}
    }
    
    component PowerManagement: JsonObject {
        property bool enabled: false
        property list<var> thresholds: []
        property ChargingBehavior onCharging: ChargingBehavior {}
        property UnpluggedBehavior onUnplugged: UnpluggedBehavior {}
        property ProfileBehaviors profileBehaviors: ProfileBehaviors {}
    }

    component Apps: JsonObject {
        property list<string> terminal: ["foot"]
        property list<string> audio: ["pavucontrol"]
        property list<string> playback: ["mpv"]
        property list<string> explorer: ["thunar"]
    }

    component Idle: JsonObject {
        property bool lockBeforeSleep: true
        property bool inhibitWhenAudio: true
        property list<var> timeouts: [
            {
                timeout: 180,
                idleAction: "lock"
            },
            {
                timeout: 300,
                idleAction: "dpms off",
                returnAction: "dpms on"
            },
            {
                timeout: 600,
                idleAction: ["systemctl", "suspend-then-hibernate"]
            }
        ]
    }

    component Battery: JsonObject {
        property list<var> warnLevels: [
            {
                level: 20,
                title: qsTr("Low battery"),
                message: qsTr("You might want to plug in a charger"),
                icon: "battery_android_frame_2"
            },
            {
                level: 10,
                title: qsTr("Did you see the previous message?"),
                message: qsTr("You should probably plug in a charger <b>now</b>"),
                icon: "battery_android_frame_1"
            },
            {
                level: 5,
                title: qsTr("Critical battery level"),
                message: qsTr("PLUG THE CHARGER RIGHT NOW!!"),
                icon: "battery_android_alert",
                critical: true
            },
        ]
        property int criticalLevel: 3
        
        property PowerManagement powerManagement: PowerManagement {}
    }
}
