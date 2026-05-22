pragma ComponentBehavior: Bound

import "items"
import "services"
import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

StyledListView {
    id: root

    required property StyledTextField search
    required property DrawerVisibilities visibilities

    readonly property string searchQuery: (search.text.slice((GlobalConfig.launcher.actionPrefix + "keybinds ").length)).toLowerCase()

    Component.onCompleted: {
        refreshModel();
    }

    Connections {
        target: Keybinds
        function onLoaded() {
            refreshModel();
        }
    }

    function refreshModel() {
        const results = Keybinds.query(searchQuery);
        model.values = results;
    }

    model: ScriptModel {
        id: model
        values: []
        onValuesChanged: root.currentIndex = 0
    }

    onVisibleChanged: {
        if (visible) {
            refreshModel();
        }
    }

    Connections {
        target: search
        function onTextChanged() {
            refreshModel();
        }
    }

    onStateChanged: {
        if (state === "keybinds") {
            refreshModel();
        }
    }

    spacing: Tokens.spacing.small
    orientation: Qt.Vertical
    implicitHeight: (Tokens.sizes.launcher.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange

    highlightFollowsCurrentItem: false
    highlight: StyledRect {
        radius: Tokens.rounding.normal
        color: Colours.palette.m3onSurface
        opacity: 0.08

        y: root.currentItem?.y ?? 0
        implicitWidth: root.width
        implicitHeight: root.currentItem?.implicitHeight ?? 0

        Behavior on y {
            Anim {
                type: Anim.DefaultSpatial
            }
        }
    }

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

    delegate: KeybindItem {
        list: root
    }
}