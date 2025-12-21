pragma ComponentBehavior: Bound

import qs.config
import QtQuick

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
            duration: Appearance.anim.durations.normal / 2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standardAccel
        }
        
        NumberAnimation {
            target: root.target
            property: "scale"
            from: root.scaleFrom
            to: root.scaleTo
            duration: Appearance.anim.durations.normal / 2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standardAccel
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
            duration: Appearance.anim.durations.normal / 2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standardDecel
        }
        
        NumberAnimation {
            target: root.target
            property: "scale"
            from: root.scaleTo
            to: root.scaleFrom
            duration: Appearance.anim.durations.normal / 2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standardDecel
        }
    }
}

