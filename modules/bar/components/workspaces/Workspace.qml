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
        if (focused)
            indicator.shape = focusedShapeList[Math.floor(Math.random() * focusedShapeList.length)];
        else
            indicator.shape = Qt.binding(() => isOccupied ? MaterialShape.Square : MaterialShape.Circle);
    }

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredHeight: size

    spacing: 0

    onFocusedChanged: updateShape()
    Component.onCompleted: updateShape()

    MaterialShape {
        id: indicator

        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
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
