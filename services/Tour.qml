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
    
    property string currentTourId: ""
    property int currentStepIndex: -1
    property var currentTour: null
    property var currentStep: null
    property bool tourActive: false
    
    property Timer highlightTimer: Timer {
        interval: 300
        repeat: false
        property string pendingId: ""
        onTriggered: root.highlightElement(pendingId)
    }
    
    function register(tourId: string, element: Item): void {
        elements[tourId] = element;
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
    
    function isDrawerOpen(drawer: string): bool {
        const visibilities = Visibilities.getForActive();
        if (!visibilities) return false;
        return visibilities[drawer] === true;
    }
    
    function openDrawerAndHighlight(drawer: string, elementId: string): void {
        const drawerAlreadyOpen = isDrawerOpen(drawer);
        Quickshell.execDetached(["quickshell", "ipc", "-c", "caelestia", "call", "drawers", "open", drawer]);
        
        if (drawerAlreadyOpen) {
            highlightElement(elementId);
        } else {
            highlightTimer.pendingId = elementId;
            highlightTimer.restart();
        }
    }
    
    function startTour(tourId: string): void {
        const tour = TourSteps.getTour(tourId);
        if (!tour) {
            console.warn("Tour not found:", tourId);
            return;
        }
        
        currentTourId = tourId;
        currentTour = tour;
        currentStepIndex = 0;
        tourActive = true;
        showCurrentStep();
    }
    
    function showCurrentStep(): void {
        if (!currentTour || currentStepIndex < 0 || currentStepIndex >= currentTour.steps.length) {
            return;
        }
        
        currentStep = currentTour.steps[currentStepIndex];
        const step = currentStep;
        
        if (step.drawer && step.drawer !== "null") {
            openDrawerAndHighlight(step.drawer, step.elementId);
        } else {
            highlightElement(step.elementId);
        }
    }
    
    function nextStep(): void {
        if (!tourActive || !currentTour) return;
        
        if (currentStepIndex < currentTour.steps.length - 1) {
            currentStepIndex++;
            showCurrentStep();
        } else {
            completeTour();
        }
    }
    
    function previousStep(): void {
        if (!tourActive || !currentTour || currentStepIndex <= 0) return;
        
        currentStepIndex--;
        showCurrentStep();
    }
    
    function skipTour(): void {
        endTour();
    }
    
    function completeTour(): void {
        endTour();
    }
    
    function endTour(): void {
        Quickshell.execDetached(["quickshell", "ipc", "-c", "caelestia", "call", "drawers", "close", "utilities"]);
        Quickshell.execDetached(["quickshell", "ipc", "-c", "caelestia", "call", "drawers", "close", "sidebar"]);
        Quickshell.execDetached(["quickshell", "ipc", "-c", "caelestia", "call", "drawers", "close", "launcher"]);
        Quickshell.execDetached(["quickshell", "ipc", "-c", "caelestia", "call", "drawers", "close", "dashboard"]);
        
        currentTourId = "";
        currentTour = null;
        currentStep = null;
        currentStepIndex = -1;
        tourActive = false;
        clearHighlight();
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
            if (drawer && drawer !== "null") {
                root.openDrawerAndHighlight(drawer, elementId);
                return `Opening ${drawer} and will highlight ${elementId}`;
            } else {
                root.highlightElement(elementId);
                return `Highlighting ${elementId} without drawer`;
            }
        }

        function status(): string {
            return root.spotlightActive 
                ? `Active - highlighting: ${root.currentTarget}` 
                : "Inactive";
        }
    }
}
