pragma ComponentBehavior: Bound
import "." as ContextMenus
import QtQuick

QtObject {
    id: factory

    required property var app
    required property var visibilities
    required property var launchApp
    required property var toggle
    required property var menuContext

    readonly property var registry: ContextMenus.ActionRegistry

    function parseConfigItem(item) {
        if (typeof item === "string") {
            return {
                id: item,
                config: {}
            };
        } else if (typeof item === "object" && item !== null) {
            const id = Object.keys(item)[0];
            return {
                id: id,
                config: item[id] || {}
            };
        }
        return {
            id: "",
            config: {}
        };
    }

    function processMenuItems(configArray) {
        if (!configArray || typeof configArray.length !== 'number' || !configArray.forEach)
            return [];

        const items = [];
        const submenus = {};

        // First pass: collect all items and identify submenu children
        configArray.forEach((item, index) => {
            const parsed = parseConfigItem(item);
            const parent = parsed.config.parent;

            if (parent) {
                if (!submenus[parent])
                    submenus[parent] = [];
                submenus[parent].push({
                    id: parsed.id,
                    config: parsed.config,
                    index: index
                });
            } else {
                items.push({
                    id: parsed.id,
                    config: parsed.config,
                    index: index,
                    children: []
                });
            }
        });

        // Second pass: attach children to their parent submenus
        items.forEach(item => {
            if (submenus[item.id]) {
                item.children = submenus[item.id];
            }
        });

        return items;
    }

    function hasChildren(items, id) {
        const item = items.find(i => i.id === id);
        return item && item.children && item.children.length > 0;
    }

    function getSubmenuItems(items, id) {
        const item = items.find(i => i.id === id);
        return item ? item.children : [];
    }

    function shouldShowAsSubmenu(id, config, items) {
        // Launch preset as submenu only if has children OR app has .desktop actions
        if (id === "launch") {
            const hasConfigChildren = hasChildren(items, id);
            const hasDesktopActions = app && app.actions && app.actions.length > 0;
            return Boolean(hasConfigChildren || hasDesktopActions);
        }

        if (id === "workspaces" || id === "categories")
            return true;

        if (hasChildren(items, id))
            return true;

        return false;
    }

    function createMenuItem(itemData, isSubmenuItem, submenuIndex) {
        const id = itemData.id;
        const config = itemData.config;

        if (id === "separator") {
            return {
                type: "separator"
            };
        }

        const defaults = registry.getDefaults(id);
        const text = registry.getText(id, config, app);
        const icon = registry.getIcon(id, config);
        const hasSubmenu = submenuIndex >= 0;
        const bold = config.bold !== undefined ? config.bold : (defaults.bold || false);

        return {
            type: "menuitem",
            id: id,
            text: text,
            icon: icon,
            bold: bold,
            hasSubmenu: hasSubmenu,
            submenuIndex: submenuIndex,
            isSubmenuItem: isSubmenuItem,
            config: config,
            onTriggered: function () {
                if (!hasSubmenu) {
                    registry.execute(id, config, app, menuContext);
                }
            }
        };
    }
}
