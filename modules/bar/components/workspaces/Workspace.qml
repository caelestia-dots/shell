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

    required property int index
    required property int activeWsId
    required property int ws
    required property HyprlandMonitor monitor
    required property var modelData

    required property int displayType
    required property bool showWindows
    required property var iconRules
    property string activeLabel
    property string occupiedLabel
    property string label

    readonly property list<HyprlandToplevel> toplevels: Hypr.toplevelsForWs(ws, GlobalConfig.bar.workspaces.ignoredTags)
    readonly property bool isOccupied: toplevels.length > 0
    readonly property int maxWindowIcons: Config.bar.workspaces.maxWindowIcons
    readonly property bool hasWindows: isOccupied && showWindows && maxWindowIcons > 0
    readonly property bool focused: activeWsId === ws
    readonly property list<int> focusedShapeList: [MaterialShape.Slanted, MaterialShape.Oval, MaterialShape.Pill, MaterialShape.Triangle, MaterialShape.Arrow, MaterialShape.Diamond, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.VerySunny, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Clover4Leaf, MaterialShape.SoftBurst, MaterialShape.Ghostish]

    property color offMonitorColour: Colours.palette.m3outlineVariant
    readonly property bool onOtherMonitor: {
        if (Config.bar.workspaces.perMonitor) return false;
        const mon = Hypr.workspaces.values.find(w => w.id === ws)?.monitor;
        return mon && mon !== monitor;
    }
    readonly property color fgColour: {
        if (onOtherMonitor) return offMonitorColour;
        if (focused || isOccupied || Config.bar.workspaces.occupiedBg) return Colours.palette.m3onSurface;
        return Colours.layer(Colours.palette.m3outlineVariant, 2);
    }

    readonly property bool isHorizontal: Config.bar.alignment === "top" || Config.bar.alignment === "bottom"
    readonly property real crossAxisSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small

    function updateShape(): void {
        const shape = indicator.item as MaterialShape;
        if (!shape) return;
        if (focused) shape.shape = focusedShapeList[Math.floor(Math.random() * focusedShapeList.length)];
        else shape.shape = Qt.binding(() => isOccupied ? MaterialShape.Square : MaterialShape.Circle);
    }

    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

    property real extraPadding: hasWindows ? Tokens.padding.extraSmall : 0.0

    implicitWidth: isHorizontal ? layout.implicitWidth + extraPadding : Tokens.sizes.bar.innerWidth
    implicitHeight: isHorizontal ? Tokens.sizes.bar.innerWidth : layout.implicitHeight + extraPadding

    opacity: 1.0

    onFocusedChanged: updateShape()
    Component.onCompleted: updateShape()

    Behavior on implicitWidth {
        enabled: isHorizontal
        Anim {}
    }
    Behavior on implicitHeight {
        enabled: !isHorizontal
        Anim {}
    }
    Behavior on opacity {
        Anim {}
    }
    Behavior on y {
        Anim {}
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
            id: wsText
            animate: true
            text: {
                if (root.displayType === BarWorkspaceDisplay.Numbers && root.ws > 0) return String(root.ws);
                if (root.focused && root.activeLabel) return root.activeLabel;
                if ((root.focused || root.isOccupied) && root.occupiedLabel) return root.occupiedLabel;
                if (root.label) return root.label;
                const ws = Hypr.workspaces.values.find(w => w.id === root.ws);
                const wsName = !ws || ws.name == root.ws ? root.ws : Hypr.trimWsName(ws.name)[0];
                const capitalisation = Config.bar.workspaces.capitalisation;
                if (capitalisation === BarWorkspaceCapitalisation.Upper) return String(wsName).toUpperCase();
                else if (capitalisation === BarWorkspaceCapitalisation.Lower) return String(wsName).toLowerCase();
                return wsName;
            }
            font.pointSize: root.displayType === BarWorkspaceDisplay.Numbers ? 14 : Tokens.font.body.small.pointSize
            font.weight: root.displayType === BarWorkspaceDisplay.Numbers ? Font.Bold : Tokens.font.body.small.weight       
            transform: Translate {
                x: (!root.isHorizontal && wsText.text === "1") ? -1.5 : 0
            }
            color: root.fgColour
            verticalAlignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
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
            verticalAlignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            WsIconCacher { id: iconCacher }
        }
    }
    
    Component {
        id: iconLoaderComponent
        Loader {
            sourceComponent: loaderIconCacher.icon ? iconComponent : textComponent
            WsIconCacher { id: loaderIconCacher }
        }
    }

    GridLayout {
        id: layout
        
        anchors.top: root.isHorizontal ? undefined : parent.top
        anchors.left: root.isHorizontal ? parent.left : undefined
        anchors.verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined
        anchors.horizontalCenter: root.isHorizontal ? undefined : parent.horizontalCenter

        columnSpacing: 0
        rowSpacing: 0
        flow: root.isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
        
        Loader {
            id: indicator
            Layout.alignment: root.isHorizontal ? (Qt.AlignLeft | Qt.AlignVCenter) : (Qt.AlignHCenter | Qt.AlignTop)
            Layout.preferredHeight: Tokens.sizes.bar.innerWidth - Tokens.padding.small
            Layout.preferredWidth: Tokens.sizes.bar.innerWidth - Tokens.padding.small
            
            sourceComponent: {
                if (root.displayType === BarWorkspaceDisplay.Icons) return iconLoaderComponent;
                if (root.displayType === BarWorkspaceDisplay.Text || root.displayType === BarWorkspaceDisplay.Numbers) return textComponent;
                return shapeComponent;
            }
            onItemChanged: root.updateShape()
        }

        Loader {
            id: windows
            asynchronous: true
            
            Layout.alignment: root.isHorizontal ? (Qt.AlignLeft | Qt.AlignVCenter) : (Qt.AlignHCenter | Qt.AlignTop)
            Layout.topMargin: root.isHorizontal ? 0.0 : -Tokens.spacing.extraSmall / 2
            Layout.leftMargin: root.isHorizontal ? -Tokens.spacing.extraSmall / 2 : 0.0

            visible: active && root.hasWindows
            active: root.showWindows && root.maxWindowIcons > 0

            sourceComponent: root.isHorizontal ? rowComp : colComp

            Component {
                id: winDelegate
                MaterialIcon {
                    required property var modelData
                    required property int index
                    grade: 0
                    horizontalAlignment: Text.AlignHCenter
                    text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                    color: root.onOtherMonitor ? root.offMonitorColour : Colours.palette.m3onSurfaceVariant
                    opacity: 1.0
                }
            }

            Component {
                id: rowComp
                Row {
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
                                const windows = root.toplevels;
                                const maxIcons = root.maxWindowIcons;
                                return maxIcons > 0 ? windows.slice(0, maxIcons) : windows;
                            }
                        }
                        delegate: winDelegate
                    }
                }
            }

            Component {
                id: colComp
                Column {
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
                            to: 1; easing: Tokens.anim.standardDecel
                            }

                        Anim {
                            properties: "x,y"
                            }

                    }
                    Repeater {
                        model: ScriptModel {
                            values: {
                                const windows = root.toplevels;
                                const maxIcons = root.maxWindowIcons;
                                return maxIcons > 0 ? windows.slice(0, maxIcons) : windows;
                            }
                        }
                        delegate: winDelegate
                    }
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
            function onNameChanged(): void { cacher.updateName(); }
            target: cacher.wsObj
        }
        function updateName(): void { if (wsObj) name = wsObj.name; }
        onWsObjChanged: updateName()
        Component.onCompleted: updateName()
    }
}