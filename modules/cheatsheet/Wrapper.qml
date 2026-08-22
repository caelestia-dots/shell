pragma ComponentBehavior: Bound

import QtQuick
import qs.components

Item {
    id: root

    required property ScreenState screenState

    readonly property bool shouldBeActive: Boolean(screenState && screenState.cheatsheet)

    implicitWidth: 1200
    implicitHeight: 900

    visible: false
    enabled: false

    width: implicitWidth
    height: implicitHeight

    opacity: 0
    scale: 0.95

    property real slideX: 0
    property real slideY: -250

    transform: Translate {
        x: root.slideX
        y: root.slideY
    }

    states: [
        State {
            name: "active"
            when: root.shouldBeActive

            PropertyChanges {
                target: root

                root.visible: true
                root.enabled: true

                root.opacity: 1
                root.scale: 1.0

                root.slideX: 0
                root.slideY: 0
            }
        },
        State {
            name: "inactive"
            when: !root.shouldBeActive

            PropertyChanges {
                target: root

                root.visible: false
                root.enabled: false

                root.opacity: 0
                root.scale: 0.95

                root.slideX: 0
                root.slideY: -250
            }
        }
    ]

    transitions: [
        Transition {
            from: "inactive"
            to: "active"

            NumberAnimation {
                properties: "opacity,scale,slideX,slideY"
                duration: 320
                easing.type: Easing.OutCubic
            }
        },
        Transition {
            from: "active"
            to: "inactive"

            NumberAnimation {
                properties: "opacity,scale,slideX,slideY"
                duration: 220
                easing.type: Easing.InCubic
            }
        }
    ]

    Loader {
        id: contentLoader

        width: root.implicitWidth
        height: root.implicitHeight

        active: root.visible

        sourceComponent: Content {
            screenState: root.screenState
        }
    }
}
