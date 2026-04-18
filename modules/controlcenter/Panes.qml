pragma ComponentBehavior: Bound

import "bluetooth"
import "network"
import "audio"
import "appearance"
import "taskbar"
import "notifications"
import "launcher"
import "dashboard"
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.controlcenter

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
        onPressed: function (mouse) {
            root.focus = true;
            mouse.accepted = false;
        }
    }

    Connections {
        function onActiveIndexChanged(): void {
            root.focus = true;
        }

        target: root.session
    }

    ColumnLayout {
        id: layout

        property bool animationComplete: true
        property bool initialOpeningComplete: false

        spacing: 0
        y: -root.session.activeIndex * root.height
        clip: true

        Timer {
            id: animationDelayTimer

            interval: Tokens.anim.durations.normal
            onTriggered: {
                layout.animationComplete = true;
            }
        }

        Timer {
            id: initialOpeningTimer

            interval: Tokens.anim.durations.large
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
            function onActiveIndexChanged(): void {
                layout.animationComplete = false;
                animationDelayTimer.restart();
            }

            target: root.session
        }
    }

    component Pane: Item {
        id: pane

        required property int paneIndex
        required property string componentPath
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

        implicitWidth: root.width
        implicitHeight: root.height

        Loader {
            id: loader

            anchors.fill: parent
            asynchronous: true
            clip: false
            active: false

            Component.onCompleted: {
                Qt.callLater(pane.updateActive);
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
            function onActiveIndexChanged(): void {
                pane.updateActive();
            }

            target: root.session
        }

        Connections {
            function onInitialOpeningCompleteChanged(): void {
                pane.updateActive();
            }
            function onAnimationCompleteChanged(): void {
                pane.updateActive();
            }

            target: layout
        }
    }
}
