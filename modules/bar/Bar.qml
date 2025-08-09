import qs.components
import qs.components.controls
import qs.services
import qs.config
import "popouts" as BarPopouts
import "components"
import "components/workspaces"
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts

    function checkPopout(y: real): void {
        const spacing = Appearance.spacing.small;
        let popoutFound = false;

        for (let i = 0; i < column.children.length; i++) {
            const loader = column.children[i];
            if (!loader.active || !loader.item) continue;

            const role = Config.bar.entries[i].id;
            const item = loader.item;

            const itemPos = loader.mapToItem(root, 0, 0);
            const itemY = itemPos.y;
            const itemHeight = loader.implicitHeight;

            if (role === "statusIcons" && item.hoverAreas) {
                for (const area of item.hoverAreas) {
                    if (!area.enabled) continue;
                    const areaPos = area.item.mapToItem(root, 0, 0);
                    const areaHeight = area.item.implicitHeight + spacing;
                    if (y >= areaPos.y - spacing / 2 && y <= areaPos.y - spacing / 2 + areaHeight) {
                        popouts.currentName = area.name;
                        popouts.currentCenter = area.item.mapToItem(root, 0, area.item.implicitHeight / 2).y;
                        popouts.hasCurrent = true;
                        popoutFound = true;
                        break;
                    }
                }
                if (popoutFound) break;
            }

            if (role === "activeWindow") {
                if (y >= itemY && y <= itemY + item.height) {
                    popouts.currentName = "activewindow";
                    popouts.currentCenter = item.mapToItem(root, 0, item.height / 2).y;
                    popouts.hasCurrent = true;
                    popoutFound = true;
                    break;
                }
            }

            if (role === "tray" && item.items) {
                const th = item.implicitHeight;
                if (y >= itemY && y <= itemY + th) {
                    const index = Math.floor(((y - itemY) / th) * item.items.count);
                    const trayItem = item.items.itemAt(index);
                    if (trayItem) {
                        popouts.currentName = `traymenu${index}`;
                        popouts.currentCenter = trayItem.mapToItem(root, 0, trayItem.implicitHeight / 2).y;
                        popouts.hasCurrent = true;
                        popoutFound = true;
                        break;
                    }
                }
            }
        }

        if (!popoutFound) {
            popouts.hasCurrent = false;
        }
    }

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.bottomMargin: Appearance.padding.large
    anchors.topMargin: Appearance.padding.large

    Component.onCompleted: implicitWidth = Qt.binding(() =>  column.implicitWidth + Config.border.thickness * 2)

    component WrappedLoader: Loader {
        required property bool enabled
        required property string id

        id: id

        active: enabled
        asynchronous: true
        Layout.alignment: Qt.AlignHCenter
    }

    ColumnLayout {
        id: column

        anchors.fill: parent

        Repeater {
            model: Config.bar.entries

            DelegateChooser {
                role: "id"

                DelegateChoice {
                    id: test
                    roleValue: "spacer"
                    delegate: Item {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }
                }
                DelegateChoice {
                    roleValue: "logo"
                    delegate: WrappedLoader {
                        sourceComponent: OsIcon {}
                    }
                }
                DelegateChoice {
                    roleValue: "workspaces"
                    delegate: WrappedLoader {
                        sourceComponent: Workspaces {}
                    }
                }
                DelegateChoice {
                    roleValue: "activeWindow"
                    id: activeWindowDelegate
                    delegate: WrappedLoader {
                        Layout.fillHeight: enabled
                        sourceComponent: ActiveWindow {
                            monitor: Brightness.getMonitorForScreen(root.screen)
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "tray"
                    delegate: WrappedLoader {
                        sourceComponent: Tray {}
                    }
                }
                DelegateChoice {
                    roleValue: "clock"
                    delegate: WrappedLoader {
                        sourceComponent: Clock {}
                    }
                }
                DelegateChoice {
                    roleValue: "statusIcons"
                    delegate: WrappedLoader {
                        id: statusIcons
                        sourceComponent: StatusIcons {}
                    }
                }
                DelegateChoice {
                    roleValue: "power"
                    delegate: WrappedLoader {
                        sourceComponent: Power {
                            visibilities: root.visibilities
                        }
                    }
                }
            }
        }
    }
}
