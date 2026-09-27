pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

WorkspaceList {
    id: root

    readonly property int activeSpecialId: monitor?.lastIpcObject.specialWorkspace?.id ?? 0

    special: true
    activeWsId: activeSpecialId
    activeIndex: wsIds.indexOf(activeSpecialId)
    wsIds: {
        const allMonitors = !Config.bar.workspaces.perMonitor;
        return Hypr.workspaces.values.filter(w => w.name.startsWith("special:") && (allMonitors || w.monitor === root.monitor)).map(w => w.id);
    }

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
                orientation: root.isHorizontal ? Gradient.Horizontal : Gradient.Vertical

                GradientStop {
                    position: 0
                    color: Qt.rgba(0, 0, 0, 0)
                }
                GradientStop {
                    position: 0.2
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 0.8
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
            anchors.left: parent.left
            anchors.right: root.isHorizontal ? undefined : parent.right
            anchors.bottom: root.isHorizontal ? parent.bottom : undefined

            radius: Tokens.rounding.full
            implicitWidth: root.isHorizontal ? parent.width / 2 : 0
            implicitHeight: root.isHorizontal ? 0 : parent.height / 2
            opacity: root.scrollOffset > Tokens.padding.extraSmall ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Rectangle {
            anchors.top: root.isHorizontal ? parent.top : undefined
            anchors.bottom: parent.bottom
            anchors.left: root.isHorizontal ? undefined : parent.left
            anchors.right: parent.right

            radius: Tokens.rounding.full
            implicitWidth: root.isHorizontal ? parent.width / 2 : 0
            implicitHeight: root.isHorizontal ? 0 : parent.height / 2
            opacity: root.scrollOffset < root.maxScrollOffset - Tokens.padding.extraSmall ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }
}
