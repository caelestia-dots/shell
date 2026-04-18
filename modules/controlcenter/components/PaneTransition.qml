pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config

SequentialAnimation {
    id: root

    required property Item target
    property list<PropertyAction> propertyActions

    property real scaleFrom: 1.0
    property real scaleTo: 0.8
    property real opacityFrom: 1.0
    property real opacityTo: 0.0

    ParallelAnimation {
        NumberAnimation {
            target: root.target
            property: "opacity"
            from: root.opacityFrom
            to: root.opacityTo
            duration: Tokens.anim.durations.normal / 2
            easing: Tokens.anim.standardAccel
        }

        NumberAnimation {
            target: root.target
            property: "scale"
            from: root.scaleFrom
            to: root.scaleTo
            duration: Tokens.anim.durations.normal / 2
            easing: Tokens.anim.standardAccel
        }
    }

    ScriptAction {
        script: {
            for (let i = 0; i < root.propertyActions.length; i++) {
                const action = root.propertyActions[i];
                if (action.target && action.property !== undefined) {
                    action.target[action.property] = action.value;
                }
            }
        }
    }

    ParallelAnimation {
        NumberAnimation {
            target: root.target
            property: "opacity"
            from: root.opacityTo
            to: root.opacityFrom
            duration: Tokens.anim.durations.normal / 2
            easing: Tokens.anim.standardDecel
        }

        NumberAnimation {
            target: root.target
            property: "scale"
            from: root.scaleTo
            to: root.scaleFrom
            duration: Tokens.anim.durations.normal / 2
            easing: Tokens.anim.standardDecel
        }
    }
}
