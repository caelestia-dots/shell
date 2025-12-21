pragma ComponentBehavior: Bound

import "bluetooth"
import "network"
import "audio"
import "appearance"
import "taskbar"
import "launcher"
import qs.components
import qs.services
import qs.config
import qs.modules.controlcenter
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ClippingRectangle {
    id: root

    required property Session session

    readonly property bool initialOpeningComplete: layout.initialOpeningComplete

    color: "transparent"
    clip: true
    focus: false
    activeFocusOnTab: false

    MouseArea {
        anchors.fill: parent
        z: -1
        onPressed: function(mouse) {
            root.focus = true;
            mouse.accepted = false;
        }
    }

    Connections {
        target: root.session

        function onActiveIndexChanged(): void {
            root.focus = true;
        }
    }

    ColumnLayout {
        id: layout

        spacing: 0
        y: -root.session.activeIndex * root.height
        clip: true

        property bool animationComplete: true
        property bool initialOpeningComplete: false

        Timer {
            id: animationDelayTimer
            interval: Appearance.anim.durations.normal
            onTriggered: {
                layout.animationComplete = true;
            }
        }

        Timer {
            id: initialOpeningTimer
            interval: Appearance.anim.durations.large
            running: true
            onTriggered: {
                layout.initialOpeningComplete = true;
            }
        }

        Repeater {
            model: PaneRegistry.count

            Pane {
                required property int index
                paneIndex: index
                componentPath: PaneRegistry.getByIndex(index).component
            }
        }

        Behavior on y {
            Anim {}
        }

        Connections {
            target: root.session
            function onActiveIndexChanged(): void {
                layout.animationComplete = false;
                animationDelayTimer.restart();
            }
        }
    }

    component Pane: Item {
        id: pane

        required property int paneIndex
        required property string componentPath

        implicitWidth: root.width
        implicitHeight: root.height

        property bool hasBeenLoaded: false
        
        function updateActive(): void {
            const diff = Math.abs(root.session.activeIndex - pane.paneIndex);
            const isActivePane = diff === 0;
            let shouldBeActive = false;
            
            if (!layout.initialOpeningComplete) {
                shouldBeActive = isActivePane;
            } else {
                if (diff <= 1) {
                    shouldBeActive = true;
                } else if (pane.hasBeenLoaded) {
                    shouldBeActive = true;
                } else {
                    shouldBeActive = layout.animationComplete;
                }
            }
            
            loader.active = shouldBeActive;
        }

        Loader {
            id: loader

            anchors.fill: parent
            clip: false
            asynchronous: true
            active: false
            
            Component.onCompleted: {
                pane.updateActive();
            }
            
            onActiveChanged: {
                if (active && !pane.hasBeenLoaded) {
                    pane.hasBeenLoaded = true;
                }
                
                if (active && !item) {
                    loader.setSource(pane.componentPath, {
                        "session": root.session
                    });
                }
            }
            
            onItemChanged: {
                if (item) {
                    pane.hasBeenLoaded = true;
                }
            }
        }
        
        Connections {
            target: root.session
            function onActiveIndexChanged(): void {
                pane.updateActive();
            }
        }
        
        Connections {
            target: layout
            function onInitialOpeningCompleteChanged(): void {
                pane.updateActive();
            }
            function onAnimationCompleteChanged(): void {
                pane.updateActive();
            }
        }
    }
}
