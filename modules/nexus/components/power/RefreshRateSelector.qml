pragma ComponentBehavior: Bound

import QtQuick
import qs.components.controls
import qs.services

SplitButtonRow {
    id: root

    required property string value
    property bool showRestore: false
    property bool showUnchanged: false

    property var availableRates: {
        const rates = [];
        if (showRestore)
            rates.push({
                value: "restore",
                label: qsTr("Restore"),
                icon: "refresh"
            });
        if (showUnchanged)
            rates.push({
                value: "",
                label: qsTr("Unchanged"),
                icon: "block"
            });

        const monitors = Object.values(Hypr.monitors?.values || Hypr.monitors || {});
        const uniqueRates = new Set();
        for (const monitor of monitors) {
            const data = monitor?.lastIpcObject;
            if (data && data.availableModes) {
                for (const mode of data.availableModes) {
                    const match = mode.match(/@(\d+(?:\.\d+)?)Hz/);
                    if (match)
                        uniqueRates.add(Math.round(parseFloat(match[1])));
                }
            }
        }
        const sortedRates = Array.from(uniqueRates).sort((a, b) => a - b);
        for (const rate of sortedRates)
            rates.push({
                value: rate.toString(),
                label: rate + " Hz",
                icon: "speed"
            });
        rates.push({
            value: "auto",
            label: qsTr("Auto (lowest)"),
            icon: "battery_saver"
        });
        return rates;
    }

    signal rateChanged(string newValue)

    label: qsTr("Refresh rate")
    menuItems: {
        const items = [];
        for (const rate of availableRates) {
            items.push(Qt.createQmlObject(`import qs.components.controls; MenuItem { text: "${rate.label}"; icon: "${rate.icon}"; property string val: "${rate.value}" }`, root, "dynamicMenuItem"));
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
    //qmllint disable missing-property
    onSelected: item => root.rateChanged(item.val)
}
