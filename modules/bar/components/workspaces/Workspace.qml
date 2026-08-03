// // pragma ComponentBehavior: Bound

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

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredHeight: size

    spacing: 0

    Item {
        id: indicator

        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        Layout.preferredWidth: Tokens.sizes.bar.innerWidth - Tokens.padding.small
        Layout.preferredHeight: Tokens.sizes.bar.innerWidth - Tokens.padding.small

        readonly property bool active: root.activeWsId === root.ws
        property int randShape: MaterialShape.Slanted
        property int prevActiveWsId: -1

        onActiveChanged: {
            const wasActive = prevActiveWsId === root.ws;
            if (active && !wasActive) {
                const shapes = [MaterialShape.Slanted, MaterialShape.Arch, MaterialShape.Oval, MaterialShape.Pill, MaterialShape.Triangle, MaterialShape.Arrow, MaterialShape.Diamond, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.VerySunny, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Clover4Leaf, MaterialShape.Clover8Leaf, MaterialShape.SoftBurst, MaterialShape.Ghostish];
                const shuffled = [...shapes].sort(() => Math.random() - 0.5);
                randShape = shuffled[0];
                activateAnim.running = true;
            } else if (!active && wasActive) {
                deactivateAnim.running = true;
            }
            prevActiveWsId = root.activeWsId;
        }

        MaterialShape {
            id: wsShape

            anchors.centerIn: parent
            implicitSize: indicator.width
            scale: indicator.active ? 2 / 3 : 1 / 3
            shape: indicator.active ? indicator.randShape : (root.isOccupied ? MaterialShape.Square : MaterialShape.Circle)
            color: Config.bar.workspaces.occupiedBg || root.isOccupied || root.activeWsId === root.ws ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)

            Behavior on color {
                CAnim {}
            }

            Behavior on scale {
                enabled: !activateAnim.running && !deactivateAnim.running

                Anim {
                    type: Anim.DefaultEffects
                }
            }

            SequentialAnimation {
                id: activateAnim

                Anim {
                    target: wsShape
                    property: "scale"
                    from: 1 / 3
                    to: 2 / 3
                    type: Anim.FastSpatial
                }
                PropertyAction {
                    target: wsShape
                    property: "shape"
                    value: indicator.randShape
                }
                PropertyAction {
                    targets: [activateAnim, deactivateAnim]
                    property: "running"
                    value: false
                }
            }

            SequentialAnimation {
                id: deactivateAnim

                Anim {
                    target: wsShape
                    property: "scale"
                    from: 2 / 3
                    to: 1 / 3
                    type: Anim.FastSpatial
                }
                PropertyAction {
                    target: wsShape
                    property: "shape"
                    value: root.isOccupied ? MaterialShape.Square : MaterialShape.Circle
                }
                PropertyAction {
                    targets: [activateAnim, deactivateAnim]
                    property: "running"
                    value: false
                }
            }
        }
    }

    Loader {
        id: windows

        asynchronous: true

        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
        Layout.topMargin: -Tokens.sizes.bar.innerWidth / 10

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
                        const ws = root.ws;
                        const windows = Hypr.toplevels.values.filter(c => c.workspace && c.workspace.id === ws);
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
