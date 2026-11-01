import QtQuick
import Quickshell.Wayland

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    color: "#101014"

    Content {
        anchors.fill: parent
        pam: root.pam
    }
}
