pragma ComponentBehavior: Bound

import qs.services
import qs.config
import "popouts" as BarPopouts
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts

    readonly property int exclusiveZone: Config.bar.persistent || visibilities.bar ? content.implicitWidth : Config.border.thickness
    property bool isHovered

    function checkPopout(y: real): void {
        content.item?.checkPopout(y);
    }

    visible: width > Config.border.thickness
    implicitWidth: Config.border.thickness
    implicitHeight: content.implicitHeight

    states: State {
        name: "visible"
        when: Config.bar.persistent || root.visibilities.bar || root.isHovered

        PropertyChanges {
            root.implicitWidth: content.implicitWidth
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            NumberAnimation {
                target: root
                property: "implicitWidth"
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            NumberAnimation {
                target: root
                property: "implicitWidth"
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    ]

    Loader {
        id: content

        Component.onCompleted: active = Qt.binding(() => Config.bar.persistent || root.visibilities.bar || root.isHovered || root.visible)

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        sourceComponent: Bar {
            screen: root.screen
            visibilities: root.visibilities
            popouts: root.popouts
        }
    }
}
