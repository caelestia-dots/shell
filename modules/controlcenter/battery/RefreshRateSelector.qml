pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

SplitButtonRow {
    id: root

    required property string value
    property bool showRestore: false
    property bool showUnchanged: false
    signal rateChanged(string newValue)

    label: qsTr("Refresh rate")

    property var availableRates: {
        const rates = [];
        
        if (showRestore) {
            rates.push({ value: "restore", label: qsTr("Restore"), icon: "refresh" });
        }
        if (showUnchanged) {
            rates.push({ value: "", label: qsTr("Unchanged"), icon: "block" });
        }
        
        const monitors = Hypr.monitors.values || Object.values(Hypr.monitors);
        const uniqueRates = new Set();
        
        for (const monitor of monitors) {
            const data = monitor.lastIpcObject;
            if (data && data.availableModes) {
                for (const mode of data.availableModes) {
                    const match = mode.match(/@(\d+(?:\.\d+)?)Hz/);
                    if (match) {
                        const rate = Math.round(parseFloat(match[1]));
                        uniqueRates.add(rate);
                    }
                }
            }
        }
        
        const sortedRates = Array.from(uniqueRates).sort((a, b) => a - b);
        for (const rate of sortedRates) {
            rates.push({ value: rate.toString(), label: rate + " Hz", icon: "speed" });
        }
        rates.push({ value: "auto", label: qsTr("Auto (lowest)"), icon: "battery_saver" });
        return rates;
    }

    menuItems: {
        const items = [];
        for (const rate of availableRates) {
            items.push(Qt.createQmlObject(
                `import qs.components.controls; MenuItem {
                    text: "${rate.label}"
                    icon: "${rate.icon}"
                    property string val: "${rate.value}"
                }`,
                root,
                "dynamicMenuItem"
            ));
        }
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
        root.rateChanged(item.val);
    }
}
