import qs.widgets
import qs.services
import qs.config
import "popouts" as BarPopouts
import "components"
import "components/workspaces"
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts

    function checkPopout(y: real): void {
        const spacing = Appearance.spacing.small;
        const aw = activeWindow.child;
        const awy = activeWindow.y + aw.y;

        const ty = tray.y;
        const th = tray.implicitHeight;
        const trayItems = tray.items;

        // Check status icons hover areas
        let statusIconFound = false;
        for (const area of statusIconsInner.hoverAreas) {
            if (!area.enabled)
                continue;

            const item = area.item;
            const itemY = statusIcons.y + statusIconsInner.y + item.y - spacing / 2;
            const itemHeight = item.implicitHeight + spacing;

            if (y >= itemY && y <= itemY + itemHeight) {
                popouts.currentName = area.name;
                popouts.currentCenter = Qt.binding(() => statusIcons.y + statusIconsInner.y + item.y + item.implicitHeight / 2);
                popouts.hasCurrent = true;
                statusIconFound = true;
                break;
            }
        }

        if (y >= awy && y <= awy + aw.implicitHeight) {
            popouts.currentName = "activewindow";
            popouts.currentCenter = Qt.binding(() => activeWindow.y + aw.y + aw.implicitHeight / 2);
            popouts.hasCurrent = true;
        } else if (y > ty && y < ty + th) {
            const index = Math.floor(((y - ty) / th) * trayItems.count);
            const item = trayItems.itemAt(index);

            popouts.currentName = `traymenu${index}`;
            popouts.currentCenter = Qt.binding(() => tray.y + item.y + item.implicitHeight / 2);
            popouts.hasCurrent = true;
        } else if (!statusIconFound) {
            popouts.hasCurrent = false;
        }
    }

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left

    implicitWidth: child.implicitWidth + Config.border.thickness * 2

    Item {
        id: child

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        implicitWidth: Math.max(osIcon.implicitWidth, workspaces.implicitWidth, activeWindow.implicitWidth, tray.implicitWidth, clock.implicitWidth, statusIcons.implicitWidth, power.implicitWidth)

        OsIcon {
            id: osIcon

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Appearance.padding.large
        }

        StyledRect {
            id: workspaces

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: osIcon.bottom
            anchors.topMargin: Appearance.spacing.normal

            radius: Appearance.rounding.full
            color: Colours.palette.m3surfaceContainer

            implicitWidth: workspacesInner.implicitWidth + Appearance.padding.small * 2
            implicitHeight: workspacesInner.implicitHeight + Appearance.padding.small * 2

            CustomMouseArea {
                anchors.fill: parent
                anchors.leftMargin: -Config.border.thickness
                anchors.rightMargin: -Config.border.thickness

                function onWheel(event: WheelEvent): void {
                    const activeWs = Hyprland.activeToplevel?.workspace?.name;
                    if (activeWs?.startsWith("special:"))
                        Hyprland.dispatch(`togglespecialworkspace ${activeWs.slice(8)}`);
                    else if (event.angleDelta.y < 0 || Hyprland.activeWsId > 1)
                        Hyprland.dispatch(`workspace r${event.angleDelta.y > 0 ? "-" : "+"}1`);
                }
            }

            Workspaces {
                id: workspacesInner

                anchors.centerIn: parent
            }
        }

        ActiveWindow {
            id: activeWindow

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: workspaces.bottom
            anchors.bottom: tray.top
            anchors.margins: Appearance.spacing.large

            monitor: Brightness.getMonitorForScreen(root.screen)
        }

        Tray {
            id: tray

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: clock.top
            anchors.bottomMargin: Appearance.spacing.larger
        }

        Clock {
            id: clock

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: statusIcons.top
            anchors.bottomMargin: Appearance.spacing.normal
        }

        StyledRect {
            id: statusIcons

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: power.top
            anchors.bottomMargin: Appearance.spacing.normal

            radius: Appearance.rounding.full
            color: Colours.palette.m3surfaceContainer

            implicitHeight: statusIconsInner.implicitHeight + Appearance.padding.normal * 2

            StatusIcons {
                id: statusIconsInner

                anchors.centerIn: parent
            }
        }

        Power {
            id: power

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Appearance.padding.large

            visibilities: root.visibilities
        }
    }
}
