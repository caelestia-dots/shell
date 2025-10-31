pragma ComponentBehavior: Bound

import qs.services
import qs.config
import qs.components
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

StyledClippingRect {
    id: root

    required property ShellScreen screen

    readonly property int activeWsId: niri.focusedWindow?.workspaceId ?? 0

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: layout.implicitHeight + Appearance.padding.small * 2

    color: Colours.tPalette.m3surfaceContainer
    radius: Appearance.rounding.full

    Item {
        anchors.fill: parent
        scale: root.onSpecial ? 0.8 : 1
        opacity: root.onSpecial ? 0.5 : 1

        layer.enabled: root.blur > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blur
            blurMax: 32
        }

        ColumnLayout {
            id: layout

            anchors.centerIn: parent
            spacing: Math.floor(Appearance.spacing.small / 2)

            Repeater {
                id: workspaces

                model: niri.workspaces
                delegate: Workspace {
                    required property int id
                    required property int activeWindowId
                    required property bool isActive
                    required property bool isUrgent
                    required property bool isFocused
                    required property string name
                    required property string output
                    wsId: id
                    wsIsFocused: isFocused
                    wsIsActive: isActive
                    wsActiveWindowId: activeWindowId
                    wsIsUrgent: isUrgent
                    wsName: name

                    // only show the workspace of the current output
                    visible: {
                        screen: ShellScreen
                        return output === screen.name
                    }
                }
            }
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {}
        }
    }
}
