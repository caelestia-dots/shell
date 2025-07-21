pragma ComponentBehavior: Bound

import qs.services
import qs.config
import qs.modules.windowinfo
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Item {
    id: root

    required property ShellScreen screen

    readonly property real nonAnimWidth: x > 0 || hasCurrent ? children.find(c => c.shouldBeActive)?.implicitWidth ?? content.implicitWidth : 0
    readonly property real nonAnimHeight: children.find(c => c.shouldBeActive)?.implicitHeight ?? content.implicitHeight

    property string currentName
    property real currentCenter
    property bool hasCurrent

    property string detachedMode
    readonly property bool isDetached: detachedMode.length > 0

    property int animLength: Appearance.anim.durations.normal
    property list<real> animCurve: Appearance.anim.curves.emphasized

    function detach(mode: string): void {
        animLength = Appearance.anim.durations.large;
        detachedMode = mode;
        focus = true;
    }

    function close(): void {
        hasCurrent = false;
        animCurve = Appearance.anim.curves.emphasizedAccel;
        animLength = Appearance.anim.durations.normal;
        detachedMode = "";
        animCurve = Appearance.anim.curves.emphasized;
    }

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    Keys.onEscapePressed: close()

    HyprlandFocusGrab {
        active: root.isDetached
        windows: [QsWindow.window]
        onCleared: root.close()
    }

    Binding {
        when: root.isDetached

        target: QsWindow.window
        property: "WlrLayershell.keyboardFocus"
        value: WlrKeyboardFocus.OnDemand
    }

    Comp {
        id: content

        shouldBeActive: !root.detachedMode
        asynchronous: true
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        sourceComponent: Content {
            wrapper: root
            screen: root.screen
            currentName: root.currentName
            currentCenter: root.currentCenter
            hasCurrent: root.hasCurrent
        }
    }

    Comp {
        shouldBeActive: root.detachedMode === "winfo"
        asynchronous: true
        anchors.centerIn: parent

        sourceComponent: WindowInfo {
            screen: root.screen
            client: Hyprland.activeToplevel
        }
    }

    Behavior on x {
        Anim {
            duration: root.animLength
            easing.bezierCurve: root.animCurve
        }
    }

    Behavior on y {
        enabled: root.implicitWidth > 0

        Anim {
            duration: root.animLength
            easing.bezierCurve: root.animCurve
        }
    }

    Behavior on implicitWidth {
        Anim {
            duration: root.animLength
            easing.bezierCurve: root.animCurve
        }
    }

    Behavior on implicitHeight {
        enabled: root.implicitWidth > 0

        Anim {
            duration: root.animLength
            easing.bezierCurve: root.animCurve
        }
    }

    component Comp: Loader {
        id: comp

        property bool shouldBeActive

        asynchronous: true
        active: false
        opacity: 0

        states: State {
            name: "active"
            when: comp.shouldBeActive

            PropertyChanges {
                comp.opacity: 1
                comp.active: true
            }
        }

        transitions: [
            Transition {
                from: ""
                to: "active"

                SequentialAnimation {
                    PropertyAction {
                        property: "active"
                    }
                    Anim {
                        property: "opacity"
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                }
            },
            Transition {
                from: "active"
                to: ""

                SequentialAnimation {
                    Anim {
                        property: "opacity"
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                    PropertyAction {
                        property: "active"
                    }
                }
            }
        ]
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.emphasized
    }
}
