pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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
    property bool isHorizontal: false
    property int maxHorizontalWindowIcons: 0

    required property int displayType
    required property bool showWindows
    required property var iconRules
    property string activeLabel
    property string occupiedLabel
    property string label

    readonly property list<HyprlandToplevel> toplevels: Hypr.toplevelsForWs(ws, GlobalConfig.bar.workspaces.ignoredTags)
    readonly property bool isOccupied: toplevels.length > 0
    readonly property int shownWindowCount: showWindows ? Math.max(0, Math.min(toplevels.length, isHorizontal ? maxHorizontalWindowIcons : Config.bar.workspaces.maxWindowIcons)) : 0
    readonly property bool hasWindows: shownWindowCount > 0
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

    readonly property real itemSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small
    readonly property real windowIconSize: itemSize * 2 / 3
    readonly property real horizontalWindowsWidth: shownWindowCount * windowIconSize
    readonly property bool adding: isHorizontal ? AnimatedRepeater.adding : LazyListView.adding
    readonly property bool removing: isHorizontal ? AnimatedRepeater.removing : LazyListView.removing
    readonly property real layoutStart: isHorizontal ? x : LazyListView.layoutY
    readonly property real layoutLength: isHorizontal ? implicitWidth : LazyListView.preferredHeight
    readonly property real visibleLength: isHorizontal ? width : LazyListView.visibleHeight

    function updateShape(): void {
        const shape = indicator.item as MaterialShape;
        if (!shape)
            return;

        if (focused)
            shape.shape = focusedShapeList[Math.floor(Math.random() * focusedShapeList.length)];
        else
            shape.shape = Qt.binding(() => isOccupied ? MaterialShape.Square : MaterialShape.Circle);
    }

    anchors.horizontalCenter: isHorizontal ? undefined : parent?.horizontalCenter
    anchors.verticalCenter: isHorizontal ? parent?.verticalCenter : undefined

    LazyListView.preferredHeight: isHorizontal ? itemSize : (LazyListView.removing ? 0 : layout.implicitHeight + (hasWindows ? Tokens.padding.extraSmall : 0))
    LazyListView.visibleHeight: isHorizontal ? itemSize : LazyListView.preferredHeight

    width: isHorizontal ? (removing ? 0 : implicitWidth) : undefined
    height: isHorizontal ? itemSize : undefined

    implicitWidth: isHorizontal && hasWindows ? itemSize + Tokens.spacing.extraSmall / 2 + horizontalWindowsWidth : itemSize
    implicitHeight: isHorizontal ? itemSize : layout.implicitHeight

    opacity: removing || adding ? 0 : 1

    onFocusedChanged: updateShape()
    Component.onCompleted: updateShape()

    Behavior on LazyListView.visibleHeight {
        Anim {}
    }

    Behavior on y {
        enabled: !root.isHorizontal && root.LazyListView.ready

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
            implicitSize: root.itemSize

            color: root.fgColour
            scale: root.focused ? 2 / 3 : root.isOccupied ? 1 / 3 : 1 / 4

            animationEasing: Tokens.anim.expressiveDefaultSpatial
            animationDuration: Tokens.anim.durations.expressiveDefaultSpatial * Tokens.anim.durations.scale

            Behavior on color {
                CAnim {}
            }

            Behavior on scale {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }
        }
    }

    Component {
        id: textComponent

        StyledText {
            height: root.itemSize
            width: root.itemSize
            animate: true
            elide: Text.ElideRight
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
            verticalAlignment: Text.AlignVCenter
            font.family: Tokens.font.workspaces

            Behavior on color {
                CAnim {}
            }
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
            verticalAlignment: Text.AlignVCenter

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

    ScriptModel {
        id: windowModel

        values: Array.from({
            length: root.shownWindowCount
        }, (_, i) => root.toplevels[i])
    }

    Component {
        id: windowDelegate

        MaterialIcon {
            required property HyprlandToplevel modelData
            required property int index

            width: root.isHorizontal ? (AnimatedRepeater.removing ? 0 : root.windowIconSize) : undefined
            height: root.isHorizontal ? root.itemSize : implicitHeight
            grade: 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Icons.getAppCategoryIcon(modelData?.lastIpcObject.class ?? "", "terminal")
            color: root.onOtherMonitor ? root.offMonitorColour : Colours.palette.m3onSurfaceVariant
            opacity: (root.isHorizontal ? AnimatedRepeater.adding || AnimatedRepeater.removing : LazyListView.adding || LazyListView.removing) ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on y {
                enabled: !root.isHorizontal

                Anim {}
            }
        }
    }

    GridLayout {
        id: layout

        anchors.fill: parent
        columns: root.isHorizontal ? 2 : 1
        columnSpacing: 0
        rowSpacing: 0

        Loader {
            id: indicator

            Layout.alignment: root.isHorizontal ? Qt.AlignVCenter : (Qt.AlignHCenter | Qt.AlignTop)
            Layout.preferredHeight: root.itemSize
            Layout.preferredWidth: root.itemSize
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
            asynchronous: true
            active: root.showWindows && (root.isHorizontal ? root.maxHorizontalWindowIcons : Config.bar.workspaces.maxWindowIcons) > 0
            visible: active

            Layout.fillWidth: !root.isHorizontal
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: root.isHorizontal && root.hasWindows ? Tokens.spacing.extraSmall / 2 : 0
            Layout.topMargin: root.isHorizontal ? 0 : -Tokens.spacing.extraSmall / 2
            Layout.preferredWidth: root.isHorizontal ? root.horizontalWindowsWidth : root.itemSize
            Layout.preferredHeight: root.isHorizontal ? root.itemSize : root.hasWindows && item ? (item as LazyListView).layoutHeight : 0

            sourceComponent: root.isHorizontal ? horizontalWindows : verticalWindows
        }
    }

    Component {
        id: verticalWindows

        LazyListView {
            spacing: 0
            implicitHeight: contentHeight
            cullDelegates: false
            removeDuration: Tokens.anim.durations.expressiveDefaultEffects
            model: windowModel
            delegate: windowDelegate
        }
    }

    Component {
        id: horizontalWindows

        Row {
            spacing: 0

            move: Transition {
                Anim {
                    properties: "x"
                }
            }

            AnimatedRepeater {
                model: windowModel
                delegate: windowDelegate
                removeDuration: Tokens.anim.durations.expressiveDefaultEffects
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
