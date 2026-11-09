import Quickshell
import QtQuick

ShellRoot {
    FloatingWindow {
        id: mainWindow
        
        visible: true
        
        // Use screen dimensions
        implicitWidth: 1920
        implicitHeight: 1080
        
        color: "transparent"
        
        GreetdSurface {
            anchors.fill: parent
        }
        
        Component.onCompleted: {
            console.log("Greetd window created")
        }
    }
}