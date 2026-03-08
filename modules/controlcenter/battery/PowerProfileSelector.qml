pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

SplitButtonRow {
    id: root

    required property string value
    property bool showRestore: false
    property bool showUnchanged: false
    signal profileChanged(string newValue)

    label: qsTr("Power profile")

    menuItems: {
        const items = [];
        
        if (showRestore) {
            items.push(Qt.createQmlObject(
                `import qs.components.controls; MenuItem {
                    text: "Restore"
                    icon: "refresh"
                    property string val: "restore"
                }`,
                root,
                "restoreMenuItem"
            ));
        }
        
        if (showUnchanged) {
            items.push(Qt.createQmlObject(
                `import qs.components.controls; MenuItem {
                    text: "Unchanged"
                    icon: "block"
                    property string val: ""
                }`,
                root,
                "unchangedMenuItem"
            ));
        }
        
        items.push(Qt.createQmlObject(
            `import qs.components.controls; MenuItem {
                text: "Power Saver"
                icon: "battery_saver"
                property string val: "power-saver"
            }`,
            root,
            "powerSaverMenuItem"
        ));
        
        items.push(Qt.createQmlObject(
            `import qs.components.controls; MenuItem {
                text: "Balanced"
                icon: "balance"
                property string val: "balanced"
            }`,
            root,
            "balancedMenuItem"
        ));
        
        items.push(Qt.createQmlObject(
            `import qs.components.controls; MenuItem {
                text: "Performance"
                icon: "speed"
                property string val: "performance"
            }`,
            root,
            "performanceMenuItem"
        ));
        
        return items;
    }

    Component.onCompleted: {
        for (let i = 0; i < menuItems.length; i++) {
            if (menuItems[i].val === root.value) {
                active = menuItems[i];
                break;
            }
        }
    }

    onSelected: item => {
        root.profileChanged(item.val);
    }
}
