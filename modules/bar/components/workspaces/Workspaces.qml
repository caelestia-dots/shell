pragma ComponentBehavior: Bound

import qs.widgets
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property list<Workspace> workspaces: layout.children.filter(c => c.isWorkspace).sort((w1, w2) => w1.ws - w2.ws)
    readonly property var occupied: Hyprland.workspaces.values.reduce((acc, curr) => {
        acc[curr.id] = curr.lastIpcObject.windows > 0;
        return acc;
    }, {})
    readonly property int groupOffset: Math.floor((Hyprland.activeWsId - 1) / Config.bar.workspaces.shown) * Config.bar.workspaces.shown

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

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
            maskWidth: root.width
            maskHeight: root.height
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
