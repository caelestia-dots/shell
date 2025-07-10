pragma ComponentBehavior: Bound

import "root:/widgets"
import "root:/services"
import "root:/config"
import Quickshell
import QtQuick
import QtQuick.Controls

StyledListView {
    id: root

    required property TextField search
    required property PersistentProperties visibilities

    property bool isAction: search.text.startsWith(Config.launcher.actionPrefix)
    property bool isCalc: search.text.startsWith(`${Config.launcher.actionPrefix}calc `)
    property bool isScheme: search.text.startsWith(`${Config.launcher.actionPrefix}scheme `)
    property bool isVariant: search.text.startsWith(`${Config.launcher.actionPrefix}variant `)

    function getModelValues() {
        let text = search.text;
        if (isCalc)
            return [0];
        if (isScheme)
            return Schemes.fuzzyQuery(text);
        if (isVariant)
            return M3Variants.fuzzyQuery(text);
        if (isAction)
            return Actions.fuzzyQuery(text);
        if (text.startsWith(Config.launcher.actionPrefix))
            text = search.text.slice(Config.launcher.actionPrefix.length);
        return Apps.fuzzyQuery(text);
    }

    model: ScriptModel {
        values: root.getModelValues()
        onValuesChanged: root.currentIndex = 0
    }

    spacing: Appearance.spacing.small
    orientation: Qt.Vertical
    implicitHeight: (Config.launcher.sizes.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing

    highlightMoveDuration: Appearance.anim.durations.normal
    highlightResizeDuration: 0

    highlight: StyledRect {
        radius: Appearance.rounding.full
        color: Colours.palette.m3onSurface
        opacity: 0.08
    }

    delegate: {
        if (isCalc)
            return calcItem;
        if (isScheme)
            return schemeItem;
        if (isVariant)
            return variantItem;
        if (isAction)
            return actionItem;
        return appItem;
    }

    ScrollBar.vertical: StyledScrollBar {}

    add: Transition {
        Anim {
            properties: "opacity,scale"
            from: 0
            to: 1
        }
    }

    remove: Transition {
        Anim {
            properties: "opacity,scale"
            from: 1
            to: 0
        }
    }

    move: Transition {
        Anim {
            property: "y"
        }
        Anim {
            properties: "opacity,scale"
            to: 1
        }
    }

    addDisplaced: Transition {
        Anim {
            property: "y"
            duration: Appearance.anim.durations.small
        }
        Anim {
            properties: "opacity,scale"
            to: 1
        }
    }

    displaced: Transition {
        Anim {
            property: "y"
        }
        Anim {
            properties: "opacity,scale"
            to: 1
        }
    }

    Component {
        id: appItem

        AppItem {
            visibilities: root.visibilities
        }
    }

    Component {
        id: actionItem

        ActionItem {
            list: root
        }
    }

    Component {
        id: calcItem

        CalcItem {
            list: root
        }
    }

    Component {
        id: schemeItem

        SchemeItem {
            list: root
        }
    }

    Component {
        id: variantItem

        VariantItem {
            list: root
        }
    }

    Behavior on isAction {
        ChangeAnim {}
    }

    Behavior on isCalc {
        ChangeAnim {}
    }

    Behavior on isScheme {
        ChangeAnim {}
    }

    Behavior on isVariant {
        ChangeAnim {}
    }

    component ChangeAnim: SequentialAnimation {
        ParallelAnimation {
            Anim {
                target: root
                property: "opacity"
                from: 1
                to: 0
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.standardAccel
            }
            Anim {
                target: root
                property: "scale"
                from: 1
                to: 0.9
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.standardAccel
            }
        }
        PropertyAction {}
        ParallelAnimation {
            Anim {
                target: root
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
            Anim {
                target: root
                property: "scale"
                from: 0.9
                to: 1
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
