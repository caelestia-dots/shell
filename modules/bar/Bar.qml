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
        let popoutFound = false;

        for (let i = 0; i < column.children.length; i++) {
            const loader = column.children[i];
            if (!loader.active || !loader.item) continue;

            const role = Config.bar.entries[i].id;
            const item = loader.item;

            if (role === "statusIcons" && item.hoverAreas) {
                for (const area of item.hoverAreas) {
                    if (!area.enabled) continue;

                    const spacing = Appearance.spacing.normal;
                    const areaTop = area.item.mapToItem(root, 0, 0).y - spacing / 2;
                    if (y >= areaTop && y <= areaTop + (area.item.implicitHeight + spacing)) {
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
                const visHeight = item.child.implicitHeight;
                const visTop = item.child.mapToItem(root, 0, 0).y;

                if (y >= visTop && y <= visTop + visHeight) {
                    popouts.currentName = "activewindow";
                    popouts.currentCenter = item.child.mapToItem(root, 0, visHeight / 2).y;
                    popouts.hasCurrent = true;
                    popoutFound = true;
                    break;
                }
            }

            if (role === "tray" && item.items) {
                const th = item.implicitHeight;
                const ty = item.mapToItem(root, 0, 0).y;
                if (y >= ty && y <= ty + th) {
                    const index = Math.floor(((y - ty) / th) * item.items.count);
                    const trayItem = item.items.itemAt(index);
                    if (trayItem) {
                        popouts.currentName = `traymenu${index}`;
                        popouts.currentCenter = Qt.binding(() => trayItem.mapToItem(root, 0, trayItem.implicitHeight / 2).y);
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
                    delegate: WrappedLoader {
                        Layout.fillHeight: enabled
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
