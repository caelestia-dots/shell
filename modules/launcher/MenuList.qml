pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.State
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

StyledListView {
    id: root

    required property SearchBar search
    required property ScreenState screenState
    readonly property string queryText: {
        const prefix = GlobalConfig.launcher.menu.prefix;
        if (prefix !== "" && root.search.text.startsWith(prefix))
            return root.search.text.slice(prefix.length);
        return root.search.text;
    }

    function clearMenuQuery(): void {
        const prefix = GlobalConfig.launcher.menu.prefix;
        if (!GlobalConfig.launcher.menu.defaultView && prefix !== "")
            root.search.text = prefix;
        else
            root.search.clear();
    }

    function enterRow(row: var): void {
        if (!row || (row.type === "item" && row.disabled))
            return;

        if ((row.type === "submenu" && (row.id === "style.background" || row.id === "style.theme")) || (row.type === "internal" && row.internal === "variant")) {
            const prefix = GlobalConfig.launcher.actionPrefix;
            if (row.id === "style.background")
                root.search.text = `${prefix}wallpaper `;
            else if (row.id === "style.theme")
                root.search.text = `${prefix}scheme `;
            else
                root.search.text = `${prefix}variant `;
            return;
        }

        if (row.id === "trigger.reminder.set") {
            const prefix = !GlobalConfig.launcher.menu.defaultView ? GlobalConfig.launcher.menu.prefix : "";
            root.search.text = `${prefix}@remind `;
            return;
        }

        const staysOpen = row.type === "submenu" || (row.type === "internal" && (row.internal === "keybindings" || row.toggle)) || (row.type === "item" && row.toggle);
        if (row.type === "submenu" || (row.type === "internal" && row.internal === "keybindings"))
            root.clearMenuQuery();

        MenuService.enter(row);

        if (!staysOpen)
            root.screenState.launcher = false;
    }

    function pickable(row: var): bool {
        return row !== undefined && row !== null && row.type !== "separator" && !(row.type === "item" && row.disabled);
    }

    function moveSelection(dir: int): void {
        const vals = menuModel.values ?? [];
        let i = root.currentIndex + dir;
        while (i >= 0 && i < vals.length && !root.pickable(vals[i]))
            i += dir;
        if (i >= 0 && i < vals.length)
            root.currentIndex = i;
    }

    function settle(): void {
        const vals = menuModel.values ?? [];
        for (let i = 0; i < vals.length; i++) {
            if (root.pickable(vals[i])) {
                root.currentIndex = i;
                return;
            }
        }
    }

    model: ScriptModel {
        id: menuModel

        values: {
            void MenuService.loaded;
            void MenuService.route;
            void MenuService.mode;
            void MenuService.condRevision;
            void MenuService.bindings.length;
            void RuntimeState.inhibitIdle;
            void PersistentState.doNotDisturb;
            return MenuService.rowsFor(root.queryText);
        }
        onValuesChanged: root.settle()
    }

    spacing: Tokens.spacing.small
    orientation: Qt.Vertical
    implicitHeight: (Tokens.sizes.launcher.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange

    highlightFollowsCurrentItem: false
    highlight: StyledRect {
        radius: Tokens.rounding.large
        color: Colours.palette.m3onSurface
        opacity: 0.08

        y: root.currentItem?.y ?? 0
        implicitWidth: root.width
        implicitHeight: root.currentItem?.implicitHeight ?? 0

        Behavior on y {
            Anim {}
        }
    }

    delegate: MenuItem {
        list: root
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    Connections {
        function onViewChanged(): void {
            root.currentIndex = 0;
            root.positionViewAtBeginning();
        }

        target: MenuService
    }
}
