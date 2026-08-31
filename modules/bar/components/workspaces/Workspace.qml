pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import M3Shapes
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property int index
    required property int activeWsId
    required property var occupied
    required property int groupOffset

    readonly property bool isWorkspace: true // Flag for finding workspace children
    // Unanimated prop for others to use as reference
    readonly property int size: implicitHeight + (hasWindows ? Tokens.padding.extraSmall : 0)

    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows
    readonly property bool focused: activeWsId === ws
    readonly property list<int> focusedShapeList: [MaterialShape.Slanted, MaterialShape.Oval, MaterialShape.Pill, MaterialShape.Triangle, MaterialShape.Arrow, MaterialShape.Diamond, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.VerySunny, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Clover4Leaf, MaterialShape.SoftBurst, MaterialShape.Ghostish]

    function updateShape(): void {
        const shape = indicator.item as MaterialShape;
        if (!shape)
            return;

        if (focused)
            shape.shape = focusedShapeList[Math.floor(Math.random() * focusedShapeList.length)];
        else
            shape.shape = Qt.binding(() => isOccupied ? MaterialShape.Square : MaterialShape.Circle);
    }

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredHeight: size

    spacing: 0

    onFocusedChanged: updateShape()
    Component.onCompleted: updateShape()

    Loader {
        id: indicator

        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        Layout.preferredHeight: Tokens.sizes.bar.innerWidth - Tokens.padding.small
        sourceComponent: Config.bar.workspaces.displayType === BarWorkspaceDisplay.Text ? textComponent : shapeComponent

        onItemChanged: root.updateShape()
    }

    Component {
        id: shapeComponent

        MaterialShape {
            implicitSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small

            color: Config.bar.workspaces.occupiedBg || root.isOccupied || root.focused ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)
            scale: root.focused ? 2 / 3 : root.isOccupied ? 1 / 3 : 1 / 4

            animationEasing: Tokens.anim.expressiveDefaultSpatial
            animationDuration: Tokens.anim.durations.expressiveDefaultSpatial * Tokens.anim.durations.scale

            Behavior on color {
                CAnim {}
            }

            Behavior on scale {
                Anim {}
            }
        }
    }

    Component {
        id: textComponent

        StyledText {
            animate: true
            text: {
                if (root.focused) {
                    const label = Config.bar.workspaces.activeLabel;
                    if (label)
                        return label;
                }

                if (root.focused || root.isOccupied) {
                    const label = Config.bar.workspaces.occupiedLabel;
                    if (label)
                        return label;
                }

                const label = Config.bar.workspaces.label;
                if (label)
                    return label;

                const ws = Hypr.workspaces.values.find(w => w.id === root.ws);
                const wsName = !ws || ws.name == root.ws ? root.ws : ws.name[0];

                const capitalisation = Config.bar.workspaces.capitalisation;
                if (capitalisation === BarWorkspaceCapitalisation.Upper)
                    return wsName.toString().toUpperCase();
                else if (capitalisation === BarWorkspaceCapitalisation.Lower)
                    return wsName.toString().toLowerCase();
                return wsName;
            }
            color: Config.bar.workspaces.occupiedBg || root.isOccupied || root.focused ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)
            verticalAlignment: Qt.AlignVCenter
            font.family: Tokens.font.workspaces
        }
    }

    Loader {
        id: windows

        asynchronous: true

        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
        Layout.topMargin: -Tokens.spacing.extraSmall / 2

        visible: active
        active: root.hasWindows

        sourceComponent: Column {
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
                model: ScriptModel {
                    values: {
                        const windows = Hypr.toplevelsForWs(root.ws);
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
    }

    Behavior on Layout.preferredHeight {
        Anim {}
    }
}
