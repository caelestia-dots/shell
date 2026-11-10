pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services

LazyLoader {
    id: root

    property bool annotate
    property bool open
    property real contentOpacity: open ? 1 : 0

    signal saved(path: string)
    signal copied(path: string)
    signal failed
    signal unsupported
    signal cancelled

    onSaved: open = false
    onCopied: open = false
    onFailed: open = false
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

            onCancelled: root.cancelled()
        }

        CaptureSession {
            id: captureSession

            document.font: Tokens.font.body.medium
            document.textBackgroundColor: Qt.alpha("black", 0.67)
            document.textPadding: TokenConfig.appearance.padding.small
            document.textRadius: TokenConfig.appearance.rounding.small

            onSaved: path => root.saved(path)
            onCopied: path => root.copied(path)
            onSaveFailed: root.failed()
            onCopyFailed: root.failed()
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
                }
            }
        }
    }
}
