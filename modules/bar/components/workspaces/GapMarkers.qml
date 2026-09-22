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

    readonly property bool isHorizontal: Config.bar.alignment === "top" || Config.bar.alignment === "bottom"

    AnimatedRepeater {
        model: ScriptModel {
            values: root.workspaces
        }

        removeDuration: Tokens.anim.durations.expressiveDefaultEffects

        StyledRect {
            required property int index
            required property var modelData

            property real shift: {
                if (!modelData || index === 0)
                    return 0;
                if (modelData.focused)
                    return -root.wsSpacing / 2 - (root.isHorizontal ? implicitWidth : implicitHeight);
                
                const prev = root.workspaces[index - 1];
                return (prev && prev.focused) ? root.wsSpacing / 2 : 0;
            }

            x: root.isHorizontal ? (modelData ? modelData.x - root.wsSpacing / 2 + shift : 0.0) : (modelData ? modelData.x + (modelData.width - implicitWidth) / 2 : 0.0)
            y: root.isHorizontal ? (modelData ? modelData.y + (modelData.height - implicitHeight) / 2 : 0.0) : (modelData ? modelData.y - root.wsSpacing / 2 + shift : 0.0)

            implicitWidth: root.isHorizontal ? 1 : 4
            implicitHeight: root.isHorizontal ? 4 : 1
            color: Colours.palette.m3outline

            opacity: {
                if (AnimatedRepeater.adding || AnimatedRepeater.removing || !modelData || index === 0) return 0;
                const prev = root.workspaces[index - 1];
                if (prev && prev.ws === modelData.ws - 1) return 0;
                return 1;
            }

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
