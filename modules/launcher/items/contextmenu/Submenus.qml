import qs.config
import qs.services
import qs.services as Services
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: submenus

    component LaunchSubmenu: ColumnLayout {
        id: launchSubmenu

        required property DesktopEntry app
        required property PersistentProperties visibilities
        required property var launchApp
        required property var toggle
        property var children: []
        property var menuFactory: null

        spacing: Appearance.spacing.smaller

        MenuItem {
            text: qsTr("Launch")
            icon: "play_arrow"
            isSubmenuItem: true
            onTriggered: launchSubmenu.launchApp()
        }

        Repeater {
            model: launchSubmenu.app ? launchSubmenu.app.actions : []
            delegate: MenuItem {
                required property var modelData
                text: modelData.name || ""
                icon: "play_arrow"
                isSubmenuItem: true
                visible: text.length > 0
                onTriggered: {
                    if (modelData && modelData.execute)
                        modelData.execute();
                    if (launchSubmenu.visibilities)
                        launchSubmenu.visibilities.launcher = false;
                    launchSubmenu.toggle();
                }
            }
        }

        MenuItem {
            isSeparator: true
            visible: launchSubmenu.children && launchSubmenu.children.length > 0
        }

        Repeater {
            model: launchSubmenu.children || []

            delegate: MenuItem {
                required property var modelData
                readonly property var itemData: modelData.id === "separator" ? null : (launchSubmenu.menuFactory ? launchSubmenu.menuFactory.createMenuItem(modelData, true, -1) : null)

                visible: modelData.id === "separator" || (itemData !== null && itemData.text && itemData.text.length > 0)
                isSeparator: modelData.id === "separator"
                text: itemData?.text || ""
                icon: itemData?.icon || ""
                bold: itemData?.bold || false
                hasSubMenu: false
                submenuIndex: -1
                isSubmenuItem: true

                onTriggered: {
                    if (itemData?.onTriggered) {
                        itemData.onTriggered();
                    }
                }
            }
        }
    }

    component WorkspaceSubmenu: ColumnLayout {
        id: workspaceSubmenu

        required property var launchApp

        spacing: Appearance.spacing.smaller

        Repeater {
            model: Services.Hypr.workspaces
            delegate: MenuItem {
                required property var modelData
                property bool isCurrent: modelData.id === Services.Hypr.activeWsId
                text: modelData.name || qsTr("Workspace %1").arg(modelData.id)
                icon: isCurrent ? "radio_button_checked" : "radio_button_unchecked"
                bold: isCurrent
                isSubmenuItem: true
                onTriggered: workspaceSubmenu.launchApp(modelData.id)
            }
        }

        MenuItem {
            isSeparator: true
        }

        MenuItem {
            text: qsTr("New Workspace")
            icon: "add_circle"
            isSubmenuItem: true
            onTriggered: {
                Services.Hypr.dispatch("workspace empty");
                workspaceSubmenu.launchApp();
            }
        }
    }

    component CategorySubmenu: ColumnLayout {
        id: categorySubmenu

        required property DesktopEntry app

        spacing: Appearance.spacing.smaller

        property var pendingChanges: ({})
        property int updateCounter: 0

        function initializeState() {
            pendingChanges = {};
            updateCounter = 0;
        }

        function saveChanges() {
            if (!categorySubmenu.app || Object.keys(pendingChanges).length === 0)
                return;

            const appId = categorySubmenu.app.id;
            const newCategories = [];

            for (let i = 0; i < Config.launcher.categories.length; i++) {
                const category = Config.launcher.categories[i];
                const newCategory = {
                    name: category.name,
                    icon: category.icon,
                    apps: category.apps ? [...category.apps] : []
                };

                if (pendingChanges.hasOwnProperty(category.name)) {
                    const shouldBeIncluded = pendingChanges[category.name];
                    const index = newCategory.apps.indexOf(appId);

                    if (shouldBeIncluded && index < 0) {
                        newCategory.apps.push(appId);
                    } else if (!shouldBeIncluded && index >= 0) {
                        newCategory.apps.splice(index, 1);
                    }
                }

                newCategories.push(newCategory);
            }

            Config.launcher.categories = newCategories;
            Config.save();
            pendingChanges = {};
        }

        Repeater {
            model: Config.launcher.categories || []
            delegate: MenuItem {
                required property var modelData

                property bool checked: {
                    categorySubmenu.updateCounter; // Depend on counter

                    if (!categorySubmenu.app || !modelData.apps)
                        return false;
                    const appId = categorySubmenu.app.id;

                    if (categorySubmenu.pendingChanges.hasOwnProperty(modelData.name)) {
                        return categorySubmenu.pendingChanges[modelData.name];
                    }

                    for (let i = 0; i < modelData.apps.length; i++) {
                        if (modelData.apps[i] === appId)
                            return true;
                    }
                    return false;
                }

                text: modelData.name || ""
                icon: checked ? "check_box" : "check_box_outline_blank"
                isSubmenuItem: true
                preventSubmenuClose: true

                onTriggered: {
                    categorySubmenu.pendingChanges[modelData.name] = !checked;
                    categorySubmenu.updateCounter++;
                }
            }
        }
    }
}
