pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.hallownest
import qs.services
import qs.utils
import qs.modules.launcher as Launcher

StyledWindow {
    id: root

    readonly property ScreenState screenState: ShellState.forScreen(screen)
    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property string specialName: monitor?.lastIpcObject.specialWorkspace?.name ?? ""
    readonly property var visibleWindows: {
        if (specialName.length > 0)
            return Hypr.workspaces.values.find(ws => ws.name === specialName)?.toplevels.values ?? [];
        return monitor?.activeWorkspace?.toplevels.values ?? [];
    }
    readonly property bool hasFullscreen: visibleWindows.some(t => t.lastIpcObject.fullscreen > 1)
    // Island or dock, switched with the paleshell:dock shortcut
    readonly property bool wanted: Dock.mode
    // 0 = the island is at the top, 1 = it has run down the sides into the dock
    property real progress
    readonly property bool shown: wanted && progress === 1 && !hasFullscreen
    readonly property bool gooRunning: settle.running && !hasFullscreen && NotchSettings.values.animGoo
    // Island body without the fillets, glued to the screen edge
    readonly property real islandWidth: shape.w
    readonly property real islandHeight: shape.h

    // The app menu is the launcher: it follows the launcher state, so the shortcut and every
    // launcher item that closes it keep working
    readonly property bool drawerOpen: screenState.launcher && !hasFullscreen
    // In island mode the dock peeks up while the cursor is at the bottom edge
    readonly property bool canPeek: !Dock.mode && progress === 0 && !hasFullscreen
    property bool peeking
    // In island mode the menu rises on its own, without the dock row under it
    readonly property bool bodyShown: shown || drawerOpen || (peeking && canPeek)
    readonly property bool rowShown: Dock.mode || peeking
    readonly property bool searching: (launcher.item?.query ?? "") !== ""
    readonly property var fakePanels: ({
            bar: {
                implicitWidth: 0
            },
            popouts: {
                hasCurrent: false
            },
            utilities: {
                implicitWidth: 0
            }
        })
    property string previewId
    // Slot the dragged app would take; the dock shows it there live
    property int dragIndex: -1
    readonly property var dockIds: {
        const ids = Dock.entries.map(e => e.id);
        if (!proxy.appId || dragIndex < 0)
            return ids;
        const rest = ids.filter(i => i !== proxy.appId);
        rest.splice(dragIndex, 0, proxy.appId);
        return rest;
    }
    property real previewX
    readonly property var previewGroup: Dock.entries.find(e => e.id === previewId) ?? null
    // Same hidden list as the launcher (launcher.hiddenApps in shell.json)
    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay && !Strings.testRegexList(GlobalConfig.launcher.hiddenApps, a.id)).sort((a, b) => a.name.localeCompare(b.name))

    readonly property real pitch: 48
    readonly property real dockHeight: 60
    readonly property real padding: 12
    readonly property real drawerWidth: 7 * 92
    readonly property real drawerHeight: 440

    function iconFor(group: var): string {
        return group.entry ? Quickshell.iconPath(group.entry.icon, "image-missing") : Icons.getAppIcon(group.id, "image-missing");
    }

    function startDrag(from: Item, id: string, source: string): void {
        proxy.appId = id;
        proxy.source = source;
        const p = from.mapToItem(proxy.parent, from.width / 2 - proxy.width / 2, from.height / 2 - proxy.height / 2);
        proxy.x = p.x;
        proxy.y = p.y;
    }

    function moveDrag(active: bool): void {
        if (active && proxy.appId && !proxy.Drag.active)
            proxy.Drag.active = true;
    }

    function endDrag(): void {
        if (proxy.Drag.active) {
            proxy.Drag.drop();
            proxy.Drag.active = false;
        }
        dragIndex = -1;
        proxy.appId = "";
    }

    function showPreview(group: var, item: Item): void {
        previewClose.stop();
        previewId = group.id;
        previewX = item.mapToItem(null, item.width / 2, 0).x;
    }

    name: "dock"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: drawerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region {
        item: root.bodyShown ? body : null

        Region {
            item: root.canPeek ? peekZone : null
        }

        Region {
            item: preview.visible ? preview : null
        }
    }

    anchors.bottom: true
    implicitWidth: Math.min(screen.width, 1100)
    implicitHeight: Math.min(screen.height, 560)

    onDrawerOpenChanged: {
        if (drawerOpen) {
            grabDelay.restart();
            grid.currentIndex = -1;
        }
        else if (peeking)
            peekHide.restart();
    }
    onWantedChanged: {
        peeking = false;
        progressAnim.stop();
        progressAnim.to = wanted ? 1 : 0;
        progressAnim.duration = NotchSettings.values.animGoo ? Math.abs(progressAnim.to - progress) * 2200 : 0;
        progressAnim.start();
        // Covers the run plus a beat while the notch or dock fades in under the drops
        settle.interval = progressAnim.duration + 250;
        settle.restart();
    }

    Component.onCompleted: progress = wanted ? 1 : 0

    Binding {
        target: root.screenState
        property: "dockShown"
        value: root.wanted || root.progress > 0
    }

    NumberAnimation {
        id: progressAnim

        target: root
        property: "progress"
        // Linear so reversing mid-way is seamless; GooWindow eases each phase itself
        easing.type: Easing.Linear
    }

    Timer {
        id: settle
    }

    HyprlandFocusGrab {
        active: root.drawerOpen && !grabDelay.running
        windows: [root]
        onCleared: root.screenState.launcher = false
    }

    // Grabbing before the menu has an input region makes Hyprland clear the grab at once
    Timer {
        id: grabDelay

        interval: 150
    }

    Timer {
        id: peekHide

        interval: 600
        onTriggered: {
            if (!peekHover.hovered && !bodyHover.hovered && !previewHover.hovered && !root.drawerOpen && !proxy.Drag.active)
                root.peeking = false;
        }
    }

    Timer {
        id: previewClose

        interval: 300
        onTriggered: root.previewId = ""
    }

    Item {
        id: peekZone

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(shape.width, 300)
        height: 3

        HoverHandler {
            id: peekHover

            onHoveredChanged: {
                if (hovered && root.canPeek) {
                    root.peeking = true;
                    peekHide.restart();
                }
            }
        }
    }

    Item {
        id: body

        // Hide with a margin, not a transform: the input mask only follows geometry. The drops
        // in GooWindow do the motion
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bodyShown ? 0 : -(height + 24)
        anchors.horizontalCenter: parent.horizontalCenter
        width: shape.width
        height: shape.height

        HoverHandler {
            id: bodyHover

            onHoveredChanged: {
                if (!hovered && root.peeking)
                    peekHide.restart();
            }
        }

        // Only the island-mode menu slides; in dock mode the drops hand over
        Behavior on anchors.bottomMargin {
            enabled: !Dock.mode

            Anim {
                type: Anim.DefaultSpatial
            }
        }

        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 32
                shadowBlur: 1
                shadowVerticalOffset: -2
                shadowColor: Qt.alpha("black", Hallownest.light ? 0.28 : 0.75)
            }

            IslandShape {
                id: shape

                w: Math.max(dockRow.implicitWidth, root.drawerOpen ? root.drawerWidth : 0) + root.padding * 2
                h: Config.border.thickness + (root.rowShown ? root.dockHeight : 0) + (root.drawerOpen ? root.drawerHeight : 0)
                radius: 22
                rotation: 180

                Behavior on w {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }

                Behavior on h {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }
            }
        }

        Item {
            id: inner

            x: shape.leftFillet + root.padding
            width: shape.w - root.padding * 2
            height: shape.h - Config.border.thickness
            clip: true

            Item {
                id: drawer

                anchors.top: parent.top
                anchors.topMargin: root.padding
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.drawerWidth
                height: root.drawerHeight - root.padding
                opacity: root.drawerOpen ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                StyledText {
                    id: drawerTitle

                    visible: !root.searching
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Tr.tr("Applications")
                    color: Hallownest.soul
                    font.family: Hallownest.serif
                    font.pointSize: 12
                    font.weight: Font.Bold
                }

                StyledText {
                    id: drawerHint

                    visible: !root.searching
                    anchors.top: drawerTitle.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Tr.tr("Drag apps to the dock to keep them at hand")
                    color: Hallownest.subtext
                    font.pointSize: 9
                }

                GridView {
                    id: grid

                    anchors.top: drawerHint.bottom
                    anchors.topMargin: Tokens.spacing.medium
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: (launcher.item?.searchHeight ?? 0) + Tokens.spacing.small
                    visible: !root.searching
                    cellWidth: 92
                    cellHeight: 88
                    clip: true
                    model: root.apps

                    delegate: Item {
                        id: app

                        required property DesktopEntry modelData
                        readonly property bool selected: appArea.containsMouse || GridView.isCurrentItem

                        function launch(): void {
                            const group = Dock.openGroup(modelData.id);
                            if (group)
                                Dock.activate(group);
                            else
                                Dock.launch(modelData);
                            root.screenState.launcher = false;
                        }

                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: 12
                            color: app.selected ? Qt.alpha(Hallownest.soul, 0.08) : "transparent"
                            border.width: app.GridView.isCurrentItem ? 1 : 0
                            border.color: Qt.alpha(Hallownest.soul, 0.35)
                        }

                        IconImage {
                            id: appIcon

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            implicitSize: 48
                            source: Quickshell.iconPath(app.modelData.icon, "image-missing")
                        }

                        StyledText {
                            anchors.top: appIcon.bottom
                            anchors.topMargin: 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - 8
                            horizontalAlignment: Text.AlignHCenter
                            text: app.modelData.name
                            color: app.selected ? Hallownest.soul : Hallownest.subtext
                            font.pointSize: 8
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: appArea

                            anchors.fill: parent
                            hoverEnabled: true
                            preventStealing: true
                            cursorShape: Qt.PointingHandCursor
                            drag.target: proxy

                            onPressed: root.startDrag(appIcon, app.modelData.id, appIcon.source)
                            onPositionChanged: root.moveDrag(drag.active)
                            onReleased: root.endDrag()
                            onClicked: app.launch()
                        }
                    }
                }

                // The launcher: search bar at the bottom, results above it once something is typed
                Loader {
                    id: launcher

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: parent.height
                    active: root.drawerOpen

                    sourceComponent: Launcher.Content {
                        screenState: root.screenState
                        panels: root.fakePanels
                        maxHeight: root.drawerHeight - root.padding
                        listShown: query !== ""
                        appGrid: grid
                    }
                }
            }

            Row {
                id: dockRow

                visible: root.rowShown
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                height: root.dockHeight

                Item {
                    id: slots

                    width: root.dockIds.length * root.pitch
                    height: parent.height

                    Behavior on width {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    Repeater {
                        // Ids keep delegates alive across the frequent Hyprland refreshes; order is drawn by x
                        model: ScriptModel {
                            values: Dock.entries.map(e => e.id)
                        }

                        DockItem {}
                    }
                }

                Item {
                    width: 13
                    height: parent.height

                    Rectangle {
                        anchors.centerIn: parent
                        width: 1
                        height: 26
                        color: Qt.alpha(Hallownest.steel, 0.3)
                    }
                }

                Item {
                    width: root.pitch
                    height: parent.height

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "apps"
                        color: root.drawerOpen || gridArea.containsMouse ? Hallownest.soul : Hallownest.steel
                        fill: root.drawerOpen ? 1 : 0
                        fontStyle: Tokens.font.icon.large
                    }

                    MouseArea {
                        id: gridArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.screenState.launcher = !root.screenState.launcher
                    }
                }
            }

            DropArea {
                anchors.fill: dockRow
                keys: ["dock-app"]

                onPositionChanged: drag => {
                    const max = Dock.pinned.filter(p => p !== proxy.appId).length;
                    root.dragIndex = Math.max(0, Math.min(max, Math.floor((drag.x - slots.x) / root.pitch)));
                }
                onExited: root.dragIndex = -1
                onDropped: {
                    if (root.dragIndex >= 0)
                        Dock.pin(proxy.appId, root.dragIndex);
                }
            }
        }
    }

    Rectangle {
        id: preview

        readonly property var windows: root.previewGroup?.windows ?? []

        x: Math.max(8, Math.min(root.width - width - 8, root.previewX - width / 2))
        anchors.bottom: body.top
        anchors.bottomMargin: 8
        implicitWidth: previewRow.implicitWidth + 16
        implicitHeight: previewRow.implicitHeight + 16
        radius: 16
        color: Hallownest.void_
        border.width: 1
        border.color: Hallownest.border
        opacity: windows.length > 0 && !root.drawerOpen ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        HoverHandler {
            id: previewHover

            onHoveredChanged: {
                if (!hovered && root.peeking)
                    peekHide.restart();
                if (hovered)
                    previewClose.stop();
                else
                    previewClose.restart();
            }
        }

        Row {
            id: previewRow

            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: ScriptModel {
                    values: preview.windows
                }

                Item {
                    id: thumb

                    required property var modelData

                    width: 200
                    height: 140

                    Rectangle {
                        id: frame

                        width: parent.width
                        height: 112
                        radius: 10
                        color: Hallownest.card
                        border.width: 1
                        border.color: thumbArea.containsMouse ? Hallownest.soul : Hallownest.border
                        clip: true

                        ScreencopyView {
                            anchors.fill: parent
                            anchors.margins: 1
                            captureSource: thumb.modelData.wayland ?? null
                            live: preview.visible
                        }
                    }

                    StyledText {
                        anchors.top: frame.bottom
                        anchors.topMargin: 6
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: thumb.modelData.title
                        color: thumbArea.containsMouse ? Hallownest.soul : Hallownest.subtext
                        font.pointSize: 8
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: thumbArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Dock.focus(thumb.modelData);
                            root.previewId = "";
                        }
                    }
                }
            }
        }
    }

    IconImage {
        id: proxy

        property string appId

        implicitSize: 40
        visible: Drag.active
        z: 100
        Drag.keys: ["dock-app"]
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
    }

    component DockItem: Item {
        id: item

        required property string modelData
        readonly property var group: Dock.entries.find(e => e.id === modelData) ?? {
            id: modelData,
            entry: null,
            pinned: false,
            windows: []
        }
        readonly property bool focused: group.windows.includes(Hypr.activeToplevel)

        x: Math.max(0, root.dockIds.indexOf(modelData)) * root.pitch
        width: root.pitch
        height: root.dockHeight
        // The proxy under the cursor stands in for the grabbed icon
        opacity: proxy.Drag.active && proxy.appId === modelData ? 0 : 1

        Behavior on x {
            Anim {
                type: Anim.FastSpatial
            }
        }

        IconImage {
            id: icon

            anchors.centerIn: parent
            anchors.verticalCenterOffset: -3
            implicitSize: area.containsMouse ? 38 : 34
            source: root.iconFor(item.group)

            Behavior on implicitSize {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            width: item.focused ? 14 : 6
            height: 3
            radius: 1.5
            color: item.focused ? Hallownest.soul : Hallownest.steel
            visible: item.group.windows.length > 0

            Behavior on width {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        Rectangle {
            x: icon.x + icon.width - width + 4
            y: icon.y - 4
            width: 16
            height: 16
            radius: 8
            color: Hallownest.lifeblood
            visible: item.group.windows.length > 1

            StyledText {
                anchors.centerIn: parent
                text: item.group.windows.length
                color: Hallownest.void_
                font.pointSize: 7
                font.weight: Font.Bold
            }
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            drag.target: item.group.entry ? proxy : null

            onPressed: {
                if (item.group.entry)
                    root.startDrag(icon, item.group.entry.id, icon.source);
            }
            onPositionChanged: root.moveDrag(drag.active)
            onReleased: root.endDrag()
            onContainsMouseChanged: {
                if (containsMouse && item.group.windows.length > 0)
                    root.showPreview(item.group, item);
                else if (!containsMouse)
                    previewClose.restart();
            }
            onClicked: mouse => {
                const group = item.group;
                if (mouse.button === Qt.MiddleButton) {
                    if (group.entry)
                        Dock.launch(group.entry);
                } else if (mouse.button === Qt.RightButton) {
                    if (group.pinned)
                        Dock.unpin(group.id);
                    else if (group.entry)
                        Dock.pin(group.entry.id, Dock.pinned.length);
                } else {
                    Dock.activate(group);
                }
            }
        }
    }
}
