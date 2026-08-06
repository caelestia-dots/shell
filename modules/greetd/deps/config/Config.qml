pragma Singleton

import "../utils"
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Hardcoded configuration for greetd environment
    // These are reasonable defaults that work without user config files
    
    property QtObject background: QtObject {
        readonly property bool blurEnabled: true
    }
    
    property QtObject bar: QtObject {}
    property QtObject border: QtObject {}
    property QtObject dashboard: QtObject {}
    property QtObject dcontent: QtObject {}
    property QtObject launcher: QtObject {}
    
    property QtObject notifs: QtObject {
        readonly property QtObject sizes: QtObject {
            readonly property int width: 400
        }
    }
    
    property QtObject osd: QtObject {}
    property QtObject session: QtObject {}
    property QtObject winfo: QtObject {}
    
    property QtObject lock: QtObject {
        readonly property int maxNotifs: 3
        
        readonly property QtObject sizes: QtObject {
            readonly property int border: 8
            readonly property int smallScreenWidth: 1400
            readonly property int largeScreenWidth: 1800
            readonly property int inputWidth: 400
            readonly property int inputHeight: 385
            readonly property int clockWidth: 400
            readonly property int clockHeight: 150
            readonly property int weatherWidth: 300
            readonly property int weatherHeight: 100
            readonly property int mediaWidth: 400
            readonly property int mediaHeight: 100
            readonly property int mediaWidthSmall: 300
            readonly property int mediaHeightSmall: 80
            readonly property int buttonsWidth: 150
            readonly property int buttonsWidthSmall: 50
            readonly property int buttonsHeight: 200
            readonly property int faceSize: 80
        }
    }
    
    property QtObject services: QtObject {
        readonly property bool useFahrenheit: false
        readonly property string weatherLocation: ""
    }
    
    property QtObject paths: QtObject {
        // Use system paths for greetd
        readonly property string wallpaper: "/usr/share/backgrounds/default.jpg"
        readonly property string wallpaperDir: "/usr/share/backgrounds"
    }
}