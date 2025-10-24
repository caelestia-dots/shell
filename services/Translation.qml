pragma Singleton

import QtQuick
import Quickshell

/**
 * Simplified translation service for Caelestia
 * Provides basic translation function (passthrough for now)
 */
Singleton {
    id: root

    // Simple passthrough translation function
    function tr(text) {
        return text || "";
    }
}
