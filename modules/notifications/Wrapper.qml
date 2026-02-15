import qs.components
import qs.config
import QtQuick

Item {
    id: root

    required property var visibilities
    required property Item panels

    visible: height > 0
    implicitWidth: Math.max(panels.sidebar.width, content.implicitWidth)
    implicitHeight: content.implicitHeight

    states: State {
        name: "hidden"
        when: root.visibilities.sidebar && Config.sidebar.enabled

        PropertyChanges {
            root.implicitHeight: 0
        }
    }

    transitions: Transition {
        Anim {
            target: root
            property: "implicitHeight"
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    Content {
        id: content

        visibilities: root.visibilities
        panels: root.panels
    }
}
