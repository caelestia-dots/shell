pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: root

    property int count: 6
    property color colour: Hallownest.soul
    property bool running
    property real size: 2
    property real rise: height
    property int duration: 2800

    Repeater {
        model: root.running || root.visible ? root.count : 0

        Rectangle {
            id: particle

            required property int index
            readonly property real xSeed: Math.random()
            readonly property real phaseSeed: Math.random()
            readonly property real sizeSeed: Math.random()
            property real t
            readonly property real p: (t + phaseSeed) % 1

            x: xSeed * (root.width - width) + Math.sin(p * 6.28 + phaseSeed * 10) * 2
            y: root.height - height - p * root.rise
            width: root.size * (0.6 + sizeSeed * 0.8)
            height: width
            radius: width / 2
            color: root.colour
            opacity: Math.sin(p * Math.PI) * 0.85

            NumberAnimation on t {
                running: root.running
                loops: Animation.Infinite
                from: 0
                to: 1
                duration: root.duration * (0.7 + particle.sizeSeed * 0.9)
            }
        }
    }
}
