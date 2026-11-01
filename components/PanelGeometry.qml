import QtQuick

// Geometry published by a drawer panel so the drawers coordinator can stack
// panels without reaching into their internals.
QtObject {
    id: root

    property real x: 0
    property real y: 0
    property real width: 0
    property real height: 0
    property real offsetScale: 0
    property real nonAnimWidth: width
    property real nonAnimHeight: height

    readonly property real visibleWidth: width * (1 - offsetScale)
    readonly property real visibleHeight: height * (1 - offsetScale)
}
