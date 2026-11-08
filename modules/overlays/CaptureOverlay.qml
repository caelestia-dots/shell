pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Components
import qs.components
import qs.components.containers
import qs.services

LazyLoader {
    id: root

    property bool annotate
    property bool open
    property real contentOpacity: open ? 1 : 0

    signal saved(path: string)
    signal unsupported
    signal cancelled

    onSaved: open = false
    onUnsupported: open = false
    onCancelled: open = false

    activeAsync: contentOpacity > 0

    Behavior on contentOpacity {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Scope {
        id: scope

        readonly property CaptureState cState: CaptureState {
            annotate: root.annotate
            Component.onCompleted: open = Qt.binding(() => root.open)

            onSaved: path => root.saved(path)
            onCancelled: root.cancelled()
        }

        CaptureSession {
            id: captureSession

            onSaved: path => root.saved(path)
            onUnsupported: root.unsupported()
        }

        Variants {
            model: Screens.screens

            StyledWindow {
                id: win

                required property ShellScreen modelData

                anchors.left: true
                anchors.right: true
                anchors.top: true
                anchors.bottom: true

                screen: modelData
                name: "capture-overlay"
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                mask: root.open ? null : empty

                Region {
                    id: empty
                }

                CaptureSurface {
                    anchors.fill: parent
                    cState: scope.cState
                    screen: win.modelData
                    session: captureSession
                    contentOpacity: root.contentOpacity

                    focus: true
                    Keys.onEscapePressed: root.cancelled()
                }
            }
        }
    }
}
