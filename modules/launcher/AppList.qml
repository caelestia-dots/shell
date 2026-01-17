pragma ComponentBehavior: Bound

import "items"
import "services"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import QtQuick

StyledListView {
    id: root

    required property StyledTextField search
    required property PersistentProperties visibilities
    required property string activeCategory

    model: ScriptModel {
        id: model

        onValuesChanged: {
            root.currentIndex = 0;
        }
    }
    
    property string previousCategory: ""
    property var pendingModelUpdate: null
    
    onActiveCategoryChanged: {
        if (previousCategory !== "" && root.state === "apps") {
            if (categoryChangeAnimation.running) {
                categoryChangeAnimation.stop();
                root.opacity = 1;
                root.scale = 1;
            }
            pendingModelUpdate = root.filterAppsByCategory(Apps.search(search.text));
            categoryChangeAnimation.start();
        }
        previousCategory = activeCategory;
    }
    
    SequentialAnimation {
        id: categoryChangeAnimation
        
        ParallelAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.standardAccel
            }
            Anim {
                target: root
                property: "scale"
                to: 0.95
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.emphasizedAccel
            }
        }
        
        ScriptAction {
            script: {
                // Update model while invisible
                if (root.pendingModelUpdate !== null) {
                    model.values = root.pendingModelUpdate;
                    root.pendingModelUpdate = null;
                }
            }
        }
        
        ParallelAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 1
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
            Anim {
                target: root
                property: "scale"
                to: 1
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
            }
        }
    }
    
    function appHasCategory(appId: string, categoryName: string): bool {
        if (!Config.launcher.categories) return false;
        
        for (let i = 0; i < Config.launcher.categories.length; i++) {
            const category = Config.launcher.categories[i];
            if (!category || category.name.toLowerCase() !== categoryName.toLowerCase()) continue;
            if (!category.apps) continue;
            
            if (typeof category.apps === 'object' && category.apps.length !== undefined) {
                for (let j = 0; j < category.apps.length; j++) {
                    if (category.apps[j] === appId) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
    
    function filterAppsByCategory(apps) {
        if (root.activeCategory === "all") {
            return apps;
        } else if (root.activeCategory === "favorites") {
            return apps.filter(app => {
                const appId = app.id || app.entry?.id;
                return Config.launcher.favoriteApps && Config.launcher.favoriteApps.includes(appId);
            });
        } else {
            // Custom category
            return apps.filter(app => {
                const appId = app.id || app.entry?.id;
                return appHasCategory(appId, root.activeCategory);
            });
        }
    }

    spacing: Appearance.spacing.small
    orientation: Qt.Vertical
    implicitHeight: (Config.launcher.sizes.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange

    highlightFollowsCurrentItem: false
    highlight: StyledRect {
        radius: Appearance.rounding.normal
        color: Colours.palette.m3onSurface
        opacity: 0.08

        y: root.currentItem?.y ?? 0
        implicitWidth: root.width
        implicitHeight: root.currentItem?.implicitHeight ?? 0

        Behavior on y {
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
    }

    state: {
        const text = search.text;
        const prefix = Config.launcher.actionPrefix;
        if (text.startsWith(prefix)) {
            for (const action of ["calc", "scheme", "variant"])
                if (text.startsWith(`${prefix}${action} `))
                    return action;

            return "actions";
        }

        return "apps";
    }

    onStateChanged: {
        if (state === "scheme" || state === "variant")
            Schemes.reload();
    }

    states: [
        State {
            name: "apps"

            PropertyChanges {
                model.values: root.filterAppsByCategory(Apps.search(search.text))
                root.delegate: appItem
                root.opacity: 1
                root.scale: 1
            }
        },
        State {
            name: "actions"

            PropertyChanges {
                model.values: Actions.query(search.text)
                root.delegate: actionItem
            }
        },
        State {
            name: "calc"

            PropertyChanges {
                model.values: [0]
                root.delegate: calcItem
            }
        },
        State {
            name: "scheme"

            PropertyChanges {
                model.values: Schemes.query(search.text)
                root.delegate: schemeItem
            }
        },
        State {
            name: "variant"

            PropertyChanges {
                model.values: M3Variants.query(search.text)
                root.delegate: variantItem
            }
        }
    ]

    transitions: Transition {
        SequentialAnimation {
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
            PropertyAction {
                targets: [model, root]
                properties: "values,delegate"
            }
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
            PropertyAction {
                targets: [root.add, root.remove]
                property: "enabled"
                value: true
            }
        }
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    add: Transition {
        enabled: !root.state

        ParallelAnimation {
            Anim {
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
            Anim {
                property: "scale"
                from: 0.8
                to: 1
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
            }
        }
    }

    remove: Transition {
        enabled: !root.state

        ParallelAnimation {
            Anim {
                property: "opacity"
                from: 1
                to: 0
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.standardAccel
            }
            Anim {
                property: "scale"
                from: 1
                to: 0.8
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasizedAccel
            }
        }
    }

    move: Transition {
        ParallelAnimation {
            Anim {
                property: "y"
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
            Anim {
                properties: "opacity,scale"
                to: 1
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
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

    property var showContextMenuAt: null
    property Item wrapperRoot: null

    Component {
        id: appItem

        AppItem {
            visibilities: root.visibilities
            showContextMenuAt: root.showContextMenuAt
            wrapperRoot: root.wrapperRoot
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
}
