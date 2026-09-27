pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import M3Shapes
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property int modelData
    required property int index
    required property int activeWsId
    required property int ws
    required property HyprlandMonitor monitor
    required property bool horizontal

    required property int displayType
    required property bool showWindows
    required property var iconRules
    property string activeLabel
    property string occupiedLabel
    property string label

    readonly property list<HyprlandToplevel> toplevels: Hypr.toplevelsForWs(ws, GlobalConfig.bar.workspaces.ignoredTags)
    readonly property bool isOccupied: toplevels.length > 0
    readonly property bool hasWindows: isOccupied && showWindows && Config.bar.workspaces.maxWindowIcons > 0
    readonly property bool focused: activeWsId === ws
    readonly property list<int> focusedShapeList: [MaterialShape.Slanted, MaterialShape.Oval, MaterialShape.Pill, MaterialShape.Triangle, MaterialShape.Arrow, MaterialShape.Diamond, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.VerySunny, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Clover4Leaf, MaterialShape.SoftBurst, MaterialShape.Ghostish]

    property color offMonitorColour: Colours.palette.m3outlineVariant
    readonly property bool onOtherMonitor: {
        if (Config.bar.workspaces.perMonitor)
            return false;
        const mon = Hypr.workspaces.values.find(w => w.id === ws)?.monitor;
        return !!(mon && mon !== monitor);
    }
    readonly property color fgColour: {
        if (onOtherMonitor)
            return offMonitorColour;
        if (focused || isOccupied || Config.bar.workspaces.occupiedBg)
            return Colours.palette.m3onSurface;
        return Colours.layer(Colours.palette.m3outlineVariant, 2);
    }
    readonly property real indSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small
    readonly property LazyListView winList: windows.item as LazyListView
    readonly property real winLen: winList ? (root.horizontal ? winList.layoutWidth : winList.layoutHeight) : 0
    readonly property real winGap: hasWindows ? Tokens.padding.extraSmall : 0
    readonly property real mainContent: indSize + winGap + winLen

    function updateShape(): void {
        const shape = indicator.item as MaterialShape;
        if (!shape)
            return;

        if (focused)
            shape.shape = focusedShapeList[Math.floor(Math.random() * focusedShapeList.length)];
        else
            shape.shape = Qt.binding(() => isOccupied ? MaterialShape.Square : MaterialShape.Circle);
    }

    LazyListView.preferredHeight: root.horizontal ? 0 : (LazyListView.removing ? 0 : mainContent)
    LazyListView.preferredWidth: root.horizontal ? (LazyListView.removing ? 0 : mainContent) : 0
    LazyListView.visibleHeight: LazyListView.preferredHeight
    LazyListView.visibleWidth: LazyListView.preferredWidth

    opacity: LazyListView.removing || LazyListView.adding ? 0 : 1

    onFocusedChanged: updateShape()
    Component.onCompleted: updateShape()

    Behavior on LazyListView.visibleHeight {
        Anim {}
    }

    Behavior on LazyListView.visibleWidth {
        Anim {}
    }

    Behavior on y {
        enabled: root.horizontal ? false : root.LazyListView.ready

        Anim {}
    }

    Behavior on x {
        enabled: root.horizontal ? root.LazyListView.ready : false

        Anim {}
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Component {
        id: shapeComponent

        MaterialShape {
            implicitSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small

            color: root.fgColour
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
                    const label = root.activeLabel;
                    if (label)
                        return label;
                }

                if (root.focused || root.isOccupied) {
                    const label = root.occupiedLabel;
                    if (label)
                        return label;
                }

                const label = root.label;
                if (label)
                    return label;

                const ws = Hypr.workspaces.values.find(w => w.id === root.ws);
                const wsName = !ws || ws.name == root.ws ? root.ws : Hypr.trimWsName(ws.name)[0];

                const capitalisation = Config.bar.workspaces.capitalisation;
                if (capitalisation === BarWorkspaceCapitalisation.Upper)
                    return String(wsName).toUpperCase();
                else if (capitalisation === BarWorkspaceCapitalisation.Lower)
                    return String(wsName).toLowerCase();
                return wsName;
            }
            color: root.fgColour
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            font.family: Tokens.font.workspaces
        }
    }

    Component {
        id: iconComponent

        MaterialIcon {
            fill: 1
            grade: 25
            text: iconCacher.icon
            color: root.fgColour
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Qt.AlignVCenter

            WsIconCacher {
                id: iconCacher
            }
        }
    }

    Component {
        id: iconLoaderComponent

        Loader {
            sourceComponent: loaderIconCacher.icon ? iconComponent : textComponent

            WsIconCacher {
                id: loaderIconCacher
            }
        }
    }

    Loader {
        id: indicator

        x: root.horizontal ? 0 : (parent.width - width) / 2
        y: root.horizontal ? (parent.height - height) / 2 : 0
        width: root.indSize
        height: root.indSize
        sourceComponent: {
            if (root.displayType === BarWorkspaceDisplay.Icons)
                return iconLoaderComponent;
            if (root.displayType === BarWorkspaceDisplay.Text)
                return textComponent;
            return shapeComponent;
        }

        onItemChanged: root.updateShape()
    }

    Loader {
        id: windows

        asynchronous: true

        x: root.horizontal ? root.indSize + Tokens.spacing.extraSmall / 2 : 0
        y: root.horizontal ? 0 : root.indSize - Tokens.spacing.extraSmall / 2
        width: root.horizontal ? Math.max(root.winLen, 0) : parent.width
        height: root.horizontal ? parent.height : Math.max(root.winLen, 0)

        visible: active
        active: root.showWindows && Config.bar.workspaces.maxWindowIcons > 0

        sourceComponent: LazyListView {
            anchors.fill: parent
            orientation: root.horizontal ? LazyListView.Horizontal : LazyListView.Vertical
            spacing: 0
            cullDelegates: false
            removeDuration: Tokens.anim.durations.expressiveDefaultEffects

            model: ScriptModel {
                values: {
                    const windows = root.toplevels;
                    const maxIcons = root.Config.bar.workspaces.maxWindowIcons;
                    return maxIcons > 0 ? windows.slice(0, maxIcons) : windows;
                }
            }

            delegate: MaterialIcon {
                id: win

                required property var modelData
                required property int index // Needed, LazyListView will fail to set it if it doesn't exist

                grade: 0
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                color: root.onOtherMonitor ? root.offMonitorColour : Colours.palette.m3onSurfaceVariant

                opacity: LazyListView.adding || LazyListView.removing ? 0 : 1

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                // Behaviors on the main-axis property let icons slide when the list reorganises
                Behavior on x {
                    enabled: root.horizontal

                    Anim {}
                }

                Behavior on y {
                    enabled: !root.horizontal

                    Anim {}
                }
            }
        }
    }

    component WsIconCacher: QtObject {
        id: cacher

        property string name
        readonly property string icon: Icons.matchIconRuleList(Hypr.trimWsName(name), root.iconRules)
        readonly property HyprlandWorkspace wsObj: Hypr.workspaces.values.find(w => w.id === root.ws) ?? null

        readonly property Connections conn: Connections {
            function onNameChanged(): void {
                cacher.updateName();
            }

            target: cacher.wsObj
        }

        function updateName(): void {
            if (wsObj)
                name = wsObj.name;
        }

        onWsObjChanged: updateName()
        Component.onCompleted: updateName()
    }
}
