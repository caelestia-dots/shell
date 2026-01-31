import qs.services
import qs.services as Services
import qs.components
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: launchSubmenu

    required property DesktopEntry app
    required property PersistentProperties visibilities
    required property var launchApp
    required property var toggle

    spacing: Appearance.spacing.smaller

    MenuItem {
        text: qsTr("Launch")
        icon: "play_arrow"
        isSubmenuItem: true
        onTriggered: launchApp()
    }

    Repeater {
        model: launchSubmenu.app ? launchSubmenu.app.actions : []
        MenuItem {
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

    Separator {
        visible: launchSubmenu.app && launchSubmenu.app.actions && launchSubmenu.app.actions.length > 0
    }

    MenuItem {
        text: qsTr("Run in Terminal")
        icon: "terminal"
        isSubmenuItem: true
        onTriggered: {
            if (launchSubmenu.app && launchSubmenu.app.execString) {
                Quickshell.execDetached({
                    command: [...Config.general.apps.terminal, "-e", launchSubmenu.app.execString]
                });
                if (launchSubmenu.visibilities)
                    launchSubmenu.visibilities.launcher = false;
            }
            launchSubmenu.toggle();
        }
    }
}
