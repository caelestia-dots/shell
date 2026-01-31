import qs.services
import qs.services as Services
import qs.components
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: workspaceSubmenu

    required property var launchApp

    spacing: Appearance.spacing.smaller

    Repeater {
        model: Services.Hypr.workspaces
        MenuItem {
            required property var modelData
            property bool isCurrent: modelData.id === Services.Hypr.activeWsId
            text: modelData.name || qsTr("Workspace %1").arg(modelData.id)
            icon: isCurrent ? "radio_button_checked" : "radio_button_unchecked"
            bold: isCurrent
            isSubmenuItem: true
            onTriggered: workspaceSubmenu.launchApp(modelData.id)
        }
    }

    Separator {}

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
