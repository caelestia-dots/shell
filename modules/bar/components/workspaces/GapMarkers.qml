pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var workspaces
    required property int wsSpacing

    AnimatedRepeater {
        model: ScriptModel {
            values: root.workspaces
        }

        removeDuration: Tokens.anim.durations.expressiveDefaultEffects

        StyledRect {
            required property int index
            required property Workspace modelData

            property real shift: {
                if (!modelData || index === 0)
                    return 0;
                if (modelData.focused)
                    return -root.wsSpacing / 2 - implicitHeight;
                return (root.workspaces[index - 1]?.focused ?? false) ? root.wsSpacing / 2 : 0;
            }

            anchors.left: parent?.left
            anchors.right: parent?.right
            anchors.margins: Tokens.padding.extraSmall

            y: modelData ? modelData.y - root.wsSpacing / 2 + shift : 0
            implicitHeight: 1
            color: Colours.palette.m3outline

            opacity: AnimatedRepeater.adding || AnimatedRepeater.removing || !modelData || index === 0 || root.workspaces[index - 1]?.ws === modelData?.ws - 1 ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on shift {
                Anim {}
            }
        }
    }
}
