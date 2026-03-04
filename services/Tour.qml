pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string currentTarget: ""
    property bool spotlightActive: false
    property rect targetRect: Qt.rect(0, 0, 0, 0)
    
    property var elements: ({})
    
    property Timer highlightTimer: Timer {
        interval: 500
        repeat: false
        property string pendingId: ""
        onTriggered: root.highlightElement(pendingId)
    }
    
    function register(tourId: string, element: Item): void {
        elements[tourId] = element;
        const globalPos = element.mapToItem(null, 0, 0);
        console.log("Tour element registered:", tourId, "at", globalPos.x, globalPos.y, element.width, element.height);
    }
    
    function unregister(tourId: string): void {
        delete elements[tourId];
    }
    
    function getCoordinates(tourId: string): var {
        const element = elements[tourId];
        if (!element) return null;
        
        const globalPos = element.mapToItem(null, 0, 0);
        return {
            x: globalPos.x,
            y: globalPos.y,
            width: element.width,
            height: element.height
        };
    }
    
    function highlightElement(elementId: string): void {
        const coords = getCoordinates(elementId);
        if (coords) {
            currentTarget = elementId;
            targetRect = Qt.rect(coords.x, coords.y, coords.width, coords.height);
            spotlightActive = true;
        }
    }
    
    function clearHighlight(): void {
        currentTarget = "";
        spotlightActive = false;
        targetRect = Qt.rect(0, 0, 0, 0);
    }
    
    function openDrawerAndHighlight(drawer: string, elementId: string): void {
        Quickshell.execDetached(["quickshell", "ipc", "-c", "caelestia", "call", "drawers", "toggle", drawer]);
        highlightTimer.pendingId = elementId;
        highlightTimer.restart();
    }

    IpcHandler {
        target: "tour"

        function highlight(elementId: string): string {
            root.highlightElement(elementId);
            return root.spotlightActive ? `Highlighting element: ${elementId}` : `Element not found: ${elementId}`;
        }

        function clear(): string {
            root.clearHighlight();
            return "Cleared highlight";
        }
        
        function openDrawerAndHighlight(drawer: string, elementId: string): string {
            root.openDrawerAndHighlight(drawer, elementId);
            return `Opening ${drawer} and will highlight ${elementId}`;
        }

        function status(): string {
            return root.spotlightActive 
                ? `Active - highlighting: ${root.currentTarget}` 
                : "Inactive";
        }
    }
}
