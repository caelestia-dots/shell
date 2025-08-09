pragma Singleton

import QtQuick
import Quickshell

QtObject {
    id: root
    
    property bool enabled: false
    
    function toggle() {
        enabled = !enabled
    }
    
    function enable() {
        if (!enabled) {
            enabled = true
        }
    }
    
    function disable() {
        if (enabled) {
            enabled = false
        }
    }
}
