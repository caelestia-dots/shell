pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    required property ShellScreen screen
    required property bool horizontal
    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property string activeSpecial: (GlobalConfig.bar.workspaces.perMonitorWorkspaces ? monitor : Hypr.focusedMonitor)?.lastIpcObject.specialWorkspace?.name ?? ""

    layer.enabled: true
    layer.effect: Mask {
        maskSource: mask
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.full

            gradient: Gradient {
                orientation: root.horizontal ? Gradient.Horizontal : Gradient.Vertical

                GradientStop {
                    position: 0
                    color: Qt.rgba(0, 0, 0, 0)
                }
                GradientStop {
                    position: 0.3
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 0.7
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0, 0, 0, 0)
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: root.horizontal ? parent.bottom : undefined
            anchors.left: parent.left
            anchors.right: root.horizontal ? undefined : parent.right

            radius: Tokens.rounding.full
            implicitWidth: root.horizontal ? parent.width / 2 : 0
            implicitHeight: root.horizontal ? 0 : parent.height / 2
            opacity: (root.horizontal ? view.contentX : view.contentY) > 0 ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Rectangle {
            anchors.top: root.horizontal ? parent.top : undefined
            anchors.bottom: parent.bottom
            anchors.left: root.horizontal ? undefined : parent.left
            anchors.right: parent.right

            radius: Tokens.rounding.full
            implicitWidth: root.horizontal ? parent.width / 2 : 0
            implicitHeight: root.horizontal ? 0 : parent.height / 2
            opacity: (root.horizontal ? view.contentX < view.contentWidth - parent.width + Tokens.padding.extraSmall : view.contentY < view.contentHeight - parent.height + Tokens.padding.extraSmall) ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    ListView {
        id: view

        anchors.fill: parent
        spacing: Tokens.spacing.medium
        interactive: false
        orientation: root.horizontal ? ListView.Horizontal : ListView.Vertical

        currentIndex: model.values.findIndex(w => w.name === root.activeSpecial)
        onCurrentIndexChanged: currentIndex = Qt.binding(() => model.values.findIndex(w => w.name === root.activeSpecial))

        model: ScriptModel {
            values: Hypr.workspaces.values.filter(w => w.name.startsWith("special:") && (!GlobalConfig.bar.workspaces.perMonitorWorkspaces || w.monitor === root.monitor))
        }

        preferredHighlightBegin: 0
        preferredHighlightEnd: root.horizontal ? width : height
        highlightRangeMode: ListView.StrictlyEnforceRange

        highlightFollowsCurrentItem: false
        highlight: Item {
            x: root.horizontal ? view.currentItem?.x ?? 0 : 0
            y: root.horizontal ? 0 : view.currentItem?.y ?? 0
            implicitWidth: root.horizontal ? (view.currentItem as SpecialWsDelegate)?.size ?? 0 : 0
            implicitHeight: root.horizontal ? 0 : (view.currentItem as SpecialWsDelegate)?.size ?? 0

            Behavior on x {
                Anim {}
            }

            Behavior on y {
                Anim {}
            }
        }

        delegate: SpecialWsDelegate {}

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing: Tokens.anim.standardDecel
            }
        }

        remove: Transition {
            Anim {
                property: "scale"
                to: 0.5
                type: Anim.StandardSmall
            }
            Anim {
                property: "opacity"
                to: 0
                type: Anim.StandardSmall
            }
        }

        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }

        displaced: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }
    }

    Loader {
        asynchronous: true
        active: Config.bar.workspaces.activeIndicator
        anchors.fill: parent

        sourceComponent: Item {
            StyledClippingRect {
                id: indicator

                anchors.top: root.horizontal ? parent.top : undefined
                anchors.bottom: root.horizontal ? parent.bottom : undefined
                anchors.left: root.horizontal ? undefined : parent.left
                anchors.right: root.horizontal ? undefined : parent.right

                x: root.horizontal ? (view.currentItem?.x ?? 0) - view.contentX : 0
                y: root.horizontal ? 0 : (view.currentItem?.y ?? 0) - view.contentY
                implicitWidth: root.horizontal ? (view.currentItem as SpecialWsDelegate)?.size ?? 0 : 0
                implicitHeight: root.horizontal ? 0 : (view.currentItem as SpecialWsDelegate)?.size ?? 0

                color: Colours.palette.m3tertiary
                radius: Tokens.rounding.full

                Colouriser {
                    source: view
                    sourceColor: Colours.palette.m3onSurface
                    colorizationColor: Colours.palette.m3onTertiary

                    anchors.horizontalCenter: root.horizontal ? undefined : parent.horizontalCenter
                    anchors.verticalCenter: root.horizontal ? parent.verticalCenter : undefined

                    x: root.horizontal ? -indicator.x : 0
                    y: root.horizontal ? 0 : -indicator.y
                    implicitWidth: view.width
                    implicitHeight: view.height
                }

                Behavior on x {
                    Anim {
                        type: Anim.Emphasized
                    }
                }

                Behavior on y {
                    Anim {
                        type: Anim.Emphasized
                    }
                }

                Behavior on implicitWidth {
                    Anim {
                        type: Anim.Emphasized
                    }
                }

                Behavior on implicitHeight {
                    Anim {
                        type: Anim.Emphasized
                    }
                }
            }
        }
    }

    MouseArea {
        property real startX
        property real startY

        anchors.fill: view

        drag.target: view.contentItem
        drag.axis: root.horizontal ? Drag.XAxis : Drag.YAxis
        drag.maximumX: 0
        drag.minimumX: Math.min(0, view.width - view.contentWidth - Tokens.padding.extraSmall)
        drag.maximumY: 0
        drag.minimumY: Math.min(0, view.height - view.contentHeight - Tokens.padding.extraSmall)

        onPressed: event => {
            startX = event.x;
            startY = event.y;
        }

        onClicked: event => {
            if (Math.abs((root.horizontal ? event.x - startX : event.y - startY)) > drag.threshold)
                return;

            const ws = view.itemAt(event.x, event.y) as SpecialWsDelegate;
            if (ws?.modelData)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.workspace.toggle_special("${ws.modelData.name.slice(8)}")` : `togglespecialworkspace ${ws.modelData.name.slice(8)}`);
            else
                Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.workspace.toggle_special("special")' : "togglespecialworkspace special");
        }
    }

    component SpecialWsDelegate: GridLayout {
        id: ws

        required property HyprlandWorkspace modelData
        readonly property int size: (root.horizontal ? label.Layout.preferredWidth : label.Layout.preferredHeight) + (hasWindows ? (root.horizontal ? windows.implicitWidth : windows.implicitHeight) + Tokens.padding.extraSmall : 0)
        property int wsId
        property string icon
        property bool hasWindows

        anchors.top: root.horizontal ? view.contentItem.top : undefined
        anchors.bottom: root.horizontal ? view.contentItem.bottom : undefined
        anchors.left: root.horizontal ? undefined : view.contentItem.left
        anchors.right: root.horizontal ? undefined : view.contentItem.right

        columns: root.horizontal ? -1 : 1
        rowSpacing: 0
        columnSpacing: 0

        Component.onCompleted: {
            wsId = modelData.id;
            icon = Icons.getSpecialWsIcon(modelData.name);
            hasWindows = Config.bar.workspaces.showWindowsOnSpecialWorkspaces && modelData.lastIpcObject.windows > 0;
        }

        // Hacky thing cause modelData gets destroyed before the remove anim finishes
        Connections {
            function onIdChanged(): void {
                if (ws.modelData)
                    ws.wsId = ws.modelData.id;
            }

            function onNameChanged(): void {
                if (ws.modelData)
                    ws.icon = Icons.getSpecialWsIcon(ws.modelData.name);
            }

            function onLastIpcObjectChanged(): void {
                if (ws.modelData)
                    ws.hasWindows = root.Config.bar.workspaces.showWindowsOnSpecialWorkspaces && ws.modelData.lastIpcObject.windows > 0;
            }

            target: ws.modelData
        }

        Connections {
            function onShowWindowsOnSpecialWorkspacesChanged(): void {
                if (ws.modelData)
                    ws.hasWindows = root.Config.bar.workspaces.showWindowsOnSpecialWorkspaces && ws.modelData.lastIpcObject.windows > 0;
            }

            target: root.Config.bar.workspaces
        }

        Loader {
            id: label

            asynchronous: true

            Layout.alignment: root.horizontal ? Qt.AlignVCenter | Qt.AlignLeft : Qt.AlignHCenter | Qt.AlignTop
            Layout.preferredWidth: root.horizontal ? Tokens.sizes.bar.innerWidth - Tokens.padding.small : -1
            Layout.preferredHeight: root.horizontal ? -1 : Tokens.sizes.bar.innerWidth - Tokens.padding.small

            sourceComponent: ws.icon.length === 1 ? letterComp : iconComp

            Component {
                id: iconComp

                MaterialIcon {
                    fill: 1
                    text: ws.icon
                    verticalAlignment: Qt.AlignVCenter
                }
            }

            Component {
                id: letterComp

                StyledText {
                    text: ws.icon
                    verticalAlignment: Qt.AlignVCenter
                }
            }
        }

        Loader {
            id: windows

            asynchronous: true

            Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
            Layout.fillWidth: root.horizontal
            Layout.fillHeight: !root.horizontal
            Layout.preferredWidth: root.horizontal ? implicitWidth : -1
            Layout.preferredHeight: root.horizontal ? -1 : implicitHeight

            visible: active
            active: ws.hasWindows

            sourceComponent: Grid {
                columns: root.horizontal ? items.count : 1
                spacing: 0

                add: Transition {
                    Anim {
                        properties: "scale"
                        from: 0
                        to: 1
                        easing: Tokens.anim.standardDecel
                    }
                }

                move: Transition {
                    Anim {
                        properties: "scale"
                        to: 1
                        easing: Tokens.anim.standardDecel
                    }
                    Anim {
                        properties: "x,y"
                    }
                }

                Repeater {
                    id: items

                    model: ScriptModel {
                        values: {
                            const windows = Hypr.toplevels.values.filter(c => c.workspace?.id === ws.wsId);
                            const maxIcons = root.Config.bar.workspaces.maxWindowIcons;
                            return maxIcons > 0 ? windows.slice(0, maxIcons) : windows;
                        }
                    }

                    MaterialIcon {
                        required property var modelData

                        grade: 0
                        text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }

            Behavior on Layout.preferredHeight {
                Anim {}
            }

            Behavior on Layout.preferredWidth {
                Anim {}
            }
        }
    }
}
