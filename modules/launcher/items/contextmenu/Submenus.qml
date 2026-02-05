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
}
