pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services

// Liquid hand-off between the notch and the dock: the island splits in two drops that run down
// the screen sides and merge at the bottom (progress 0 = top, 1 = bottom)
StyledWindow {
    id: root

    property real progress
    property bool running
    property real dockWidth: 300
    property real dockHeight: 70
    readonly property ScreenState screenState: ShellState.forScreen(screen)

    // Config needs an item inside the window to resolve the screen
    readonly property real t: blobs.Config.border.thickness
    readonly property real rounding: blobs.Config.border.rounding
    readonly property real r: 17
    // Drop centres run just inside the frame so they read as bulges of it
    readonly property real inset: t + r * 0.45
    readonly property real corner: Math.max(rounding, r * 1.5)
    readonly property real topRun: width / 2 - inset - corner
    readonly property real sideRun: height - inset * 2 - corner * 2
    readonly property real arc: Math.PI * corner / 2
    readonly property real halfPath: topRun * 2 + sideRun + arc * 2
    // Fraction of the (linear) trip spent splitting at the top and merging at the bottom
    readonly property real ends: 0.12
    readonly property real travel: smooth(ease((progress - ends) / (1 - ends * 2)))
    readonly property real topK: 1 - ease(progress / ends)
    readonly property real bottomK: ease((progress - 1 + ends) / ends)
    readonly property point drop: pointAt(travel * halfPath)
    readonly property point trailDrop: pointAt(Math.max(0, travel - 0.055) * halfPath)
    readonly property bool trailShown: travel > 0.02 && travel < 0.98

    // Point at distance s along the right half of the frame, from top centre to bottom centre
    function pointAt(s: real): point {
        const right = width - inset;
        const top = inset;
        const bottom = height - inset;
        if (s <= topRun)
            return Qt.point(width / 2 + s, top);
        s -= topRun;
        if (s <= arc) {
            const a = -Math.PI / 2 + s / corner;
            return Qt.point(right - corner + Math.cos(a) * corner, top + corner + Math.sin(a) * corner);
        }
        s -= arc;
        if (s <= sideRun)
            return Qt.point(right, top + corner + s);
        s -= sideRun;
        if (s <= arc) {
            const a = s / corner;
            return Qt.point(right - corner + Math.cos(a) * corner, bottom - corner + Math.sin(a) * corner);
        }
        s -= arc;
        return Qt.point(right - corner - s, bottom);
    }

    function ease(x: real): real {
        return Math.max(0, Math.min(1, x));
    }

    // In-out quad: the drops speed up off the island and slow into the dock
    function smooth(x: real): real {
        return x < 0.5 ? 2 * x * x : 1 - Math.pow(-2 * x + 2, 2) / 2;
    }

    function lerp(a: real, b: real, k: real): real {
        return a + (b - a) * k;
    }

    name: "goo"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    mask: Region {}

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Item {
        id: blobs

        anchors.fill: parent

        // Hide the shapes, never the effect chain: once the output is hidden the textures stop
        // updating and the next run shows a frozen frame
        Item {
            anchors.fill: parent
            visible: root.running

            // The frame itself, so drops neck smoothly into it
            Rectangle {
                x: -root.corner
                y: -root.corner
                width: parent.width + root.corner * 2
                height: parent.height + root.corner * 2
                color: "transparent"
                border.width: root.corner + root.t
                border.color: "white"
                radius: root.rounding + root.corner + root.t
            }

            // Island at the top, shrinking from the notch's own size into the two drops;
            // centred on the edge so only its lower half shows
            Rectangle {
                readonly property real reach: root.lerp(root.r, root.screenState.notchHeight, root.topK)

                anchors.horizontalCenter: parent.horizontalCenter
                y: -reach
                width: root.lerp(root.r * 2, root.screenState.notchWidth, root.topK)
                height: reach * 2
                radius: Math.min(reach, width / 2, root.lerp(root.r, root.screenState.notchRadius, root.topK))
                visible: root.topK > 0
            }

            // Dock at the bottom, growing to exactly the dock's island
            Rectangle {
                readonly property real reach: root.lerp(root.r, root.dockHeight, root.bottomK)

                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height - reach
                width: root.lerp(root.r * 2, root.dockWidth, root.bottomK)
                height: reach * 2
                radius: Math.min(reach, width / 2, root.lerp(root.r, 22, root.bottomK))
                visible: root.bottomK > 0
            }

            Repeater {
                model: [1, -1]

                Item {
                    id: dropPair

                    required property int modelData

                    Rectangle {
                        x: root.width / 2 + (root.drop.x - root.width / 2) * dropPair.modelData - root.r
                        y: root.drop.y - root.r
                        width: root.r * 2
                        height: root.r * 2
                        radius: root.r
                    }

                    Rectangle {
                        readonly property real tr: root.r * 0.62

                        visible: root.trailShown
                        x: root.width / 2 + (root.trailDrop.x - root.width / 2) * dropPair.modelData - tr
                        y: root.trailDrop.y - tr
                        width: tr * 2
                        height: tr * 2
                        radius: tr
                    }
                }
            }
        }
    }

    // Sources stay visible behind hideSource so their changes schedule repaints; hidden layered
    // items never repaint while the drops move
    ShaderEffectSource {
        id: blobsTexture

        anchors.fill: parent
        sourceItem: blobs
        hideSource: true
        live: true
        visible: false
        textureSize: Qt.size(width / 2, height / 2)
    }

    MultiEffect {
        id: blurred

        anchors.fill: parent
        source: blobsTexture
        blurEnabled: true
        blur: 1
        blurMax: 24
        autoPaddingEnabled: false
    }

    ShaderEffectSource {
        id: blurredTexture

        anchors.fill: parent
        sourceItem: blurred
        hideSource: true
        live: true
        visible: false
    }

    Rectangle {
        id: fill

        anchors.fill: parent
        visible: false
        layer.enabled: true
        color: Colours.transparency.enabled ? Qt.alpha(Hallownest.void_, Colours.transparency.base) : Hallownest.void_
    }

    // Thresholding the blurred shapes gives the metaball (gooey) merge
    MultiEffect {
        anchors.fill: parent
        source: fill
        maskEnabled: true
        maskSource: blurredTexture
        maskThresholdMin: 0.5
        maskSpreadAtMin: 0.08
    }
}
