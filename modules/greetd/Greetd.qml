pragma ComponentBehavior: Bound

import qs.widgets
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root
    
    property bool sessionStarted: false
    
    // Main greetd surface
    GreetdSurface {
        id: greetdSurface
        
        onSessionStarted: {
            root.sessionStarted = true;
            // The greetd process will handle starting the session
            // This scope can be unloaded after successful login
        }
    }
    
    // IPC handler for potential external control
    IpcHandler {
        target: "greetd"
        
        function reset(): void {
            greetdSurface.reset();
        }
        
        function isActive(): bool {
            return !root.sessionStarted;
        }
    }
}