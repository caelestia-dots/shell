pragma ComponentBehavior: Bound

import qs.services
import qs.config
import qs.components
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    readonly property list<Workspace> workspaces: layout.children.filter(c => c.isWorkspace).sort((w1, w2) => w1.ws - w2.ws)
    readonly property var occupied: Hyprland.workspaces.values.reduce((acc, curr) => {
        acc[curr.id] = curr.lastIpcObject.windows > 0;
        return acc;
    }, {})
    readonly property int groupOffset: Math.floor((Hyprland.activeWsId - 1) / Config.bar.workspaces.shown) * Config.bar.workspaces.shown

    implicitWidth: layout.implicitWidth + Appearance.padding.small * 2
    implicitHeight: layout.implicitHeight + Appearance.padding.small * 2
    color: Colours.tPalette.m3surfaceContainer
    radius: Appearance.rounding.full

    Item {
        id: inner

        anchors.fill: parent
        anchors.margins: Appearance.padding.small

        ColumnLayout {
            id: layout

            spacing: 0
            layer.enabled: true
            layer.smooth: true

            Repeater {
                model: Config.bar.workspaces.shown

                Workspace {
                    occupied: root.occupied
                    groupOffset: root.groupOffset
                }
            }
        }

        Loader {
            active: Config.bar.workspaces.occupiedBg
            asynchronous: true

            z: -1
            anchors.fill: parent

            sourceComponent: OccupiedBg {
                workspaces: root.workspaces
                occupied: root.occupied
                groupOffset: root.groupOffset
            }
        }

        Loader {
            active: Config.bar.workspaces.activeIndicator
            asynchronous: true

            sourceComponent: ActiveIndicator {
                workspaces: root.workspaces
                mask: layout
                maskWidth: inner.width
                maskHeight: inner.height
                groupOffset: root.groupOffset
            }
        }

        MouseArea {
            anchors.fill: parent

            onPressed: event => {
                const ws = layout.childAt(event.x, event.y).index + root.groupOffset + 1;
                if (Hyprland.activeWsId !== ws)
                    Hyprland.dispatch(`workspace ${ws}`);
            }
        }
    }
}
