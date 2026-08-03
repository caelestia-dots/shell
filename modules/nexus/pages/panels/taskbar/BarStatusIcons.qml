pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var builtinIcons: ({
            lockStatus: qsTr("Lock keys"),
            kbLayout: qsTr("Keyboard layout"),
            audio: qsTr("Speakers"),
            microphone: qsTr("Microphone"),
            network: qsTr("Network"),
            bluetooth: qsTr("Bluetooth"),
            battery: qsTr("Battery")
        })

    title: qsTr("Status icons")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Visible icons
        SectionHeader {
            first: true
            text: qsTr("Visible icons")
        }

        ListEditor {
            function labelFor(item: var): string {
                const prettyName = root.builtinIcons[item.id];
                if (prettyName)
                    return prettyName;
                const label = item.id.replace(/([A-Z])/g, " $1");
                return label.charAt(0).toUpperCase() + label.slice(1).toLowerCase();
            }

            function toggledFor(item: var): bool {
                return item.enabled;
            }

            z: 1
            first: true
            values: Config.bar.statusIcons.values
            onItemMoved: (from, to) => GlobalConfig.bar.statusIcons.move(from, to)
            onItemRemoved: index => GlobalConfig.bar.statusIcons.remove(index)
            onItemToggled: (index, checked) => GlobalConfig.bar.statusIcons.at(index).enabled = checked
        }

        DialogSelectButton {
            id: addItemContainer

            rootParent: root.flickable
            icon: "add"
            label: qsTr("Add entry")
            header: qsTr("Add new entry")
            acceptLabel: qsTr("Add")

            model: {
                const builtins = Object.keys(root.builtinIcons).map(k => ({
                            id: k,
                            label: root.builtinIcons[k]
                        }));
                return builtins;
            }

            onAccepted: {
                if (!selectedItem) // Should never happen but just in case
                    return;

                GlobalConfig.bar.statusIcons.insert({
                    id: selectedItem,
                    enabled: true
                });
            }
        }

        // Behaviour
        SectionHeader {
            text: qsTr("Behaviour")
        }

        ToggleRow {
            first: true
            last: true
            text: qsTr("Popout on hover")
            subtext: qsTr("Show a details popout when hovering the status icons")
            checked: Config.bar.popouts.statusIcons
            onToggled: GlobalConfig.bar.popouts.statusIcons = checked
        }
    }
}
