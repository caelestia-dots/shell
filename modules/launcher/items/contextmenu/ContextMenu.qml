import "../../services"
import "../../../../services" as Services
import "." as ContextMenus
import qs.components
import qs.components.effects
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property DesktopEntry app: null
    property PersistentProperties visibilities
    property bool showAbove: false
    property int activeSubmenuIndex: -1
    property int targetSubmenuIndex: -1
    property real submenuProgress: 0
    property int hoveredSubmenuIndex: -1
    property real contentOpacity: 1
    property real submenuItemY: 0
    property int displayedSubmenuIndex: -1
    property real targetWidth: 0
    property real targetHeight: 0
    property real previousTargetWidth: 0
    property real previousTargetHeight: 0
    property real previousTopY: 0

    property real gooOverlapPx: 28
    readonly property real gooMarginPx: 30

    readonly property real bottomPadding: 16

    Timer {
        id: contentSwitchTimer
        interval: Appearance.anim.durations.small
        onTriggered: {
            if (targetSubmenuIndex >= 0) {
                activeSubmenuIndex = displayedSubmenuIndex = targetSubmenuIndex;
                targetSubmenuIndex = -1;
            }
            contentOpacity = 1;
            Qt.callLater(() => {
                if (activeSubmenuIndex >= 0) {
                    targetWidth = submenuColumn.implicitWidth + Appearance.padding.smaller * 2;
                    targetHeight = submenuColumn.implicitHeight + Appearance.padding.smaller * 2;
                }
            });
        }
    }

    onHoveredSubmenuIndexChanged: {
        if (hoveredSubmenuIndex < 0)
            return;
        if (activeSubmenuIndex < 0) {
            activeSubmenuIndex = displayedSubmenuIndex = hoveredSubmenuIndex;
            targetSubmenuIndex = -1;
            Qt.callLater(() => {
                targetWidth = submenuColumn.implicitWidth + Appearance.padding.smaller * 2;
                targetHeight = submenuColumn.implicitHeight + Appearance.padding.smaller * 2;
            });
        } else if (activeSubmenuIndex !== hoveredSubmenuIndex) {
            previousTargetWidth = targetWidth;
            previousTargetHeight = targetHeight;
            previousTopY = submenuContainer.interpolatedTopY;
            targetSubmenuIndex = hoveredSubmenuIndex;
            contentSwitchTimer.restart();
        }
    }

    onActiveSubmenuIndexChanged: {
        if (activeSubmenuIndex < 0) {
            targetSubmenuIndex = displayedSubmenuIndex = -1;
            targetWidth = targetHeight = previousTargetWidth = previousTargetHeight = previousTopY = 0;
        } else if (displayedSubmenuIndex < 0) {
            // First submenu open via direct activeSubmenuIndex assignment (from MenuItem timer)
            displayedSubmenuIndex = activeSubmenuIndex;
            Qt.callLater(() => {
                targetWidth = submenuColumn.implicitWidth + Appearance.padding.smaller * 2;
                targetHeight = submenuColumn.implicitHeight + Appearance.padding.smaller * 2;
            });
        }
    }

    Connections {
        target: submenuColumn
        function onImplicitWidthChanged() {
            if (displayedSubmenuIndex >= 0)
                targetWidth = submenuColumn.implicitWidth + Appearance.padding.smaller * 2;
        }
        function onImplicitHeightChanged() {
            if (displayedSubmenuIndex >= 0)
                targetHeight = submenuColumn.implicitHeight + Appearance.padding.smaller * 2;
        }
    }

    visible: false
    signal closed

    function launchApp(workspace) {
        if (!root.app)
            return;
        if (workspace)
            Services.Hypr.dispatch(`workspace ${workspace}`);
        Apps.launch(root.app);
        if (root.visibilities)
            root.visibilities.launcher = false;
        toggle();
    }

    function toggle() {
        if (!root.app)
            return;
        if (root.visible) {
            menuContainer.opacity = 0;
            menuContainer.scale = 0.8;
            Qt.callLater(() => {
                root.visible = false;
                root.app = null;
                activeSubmenuIndex = -1;
                submenuProgress = 0;
                root.closed();
            });
        } else {
            activeSubmenuIndex = -1;
            submenuProgress = 0;
            root.visible = true;
            menuContainer.opacity = 1;
            menuContainer.scale = 1;
            root.forceActiveFocus();
        }
    }

    onActiveFocusChanged: if (!activeFocus && visible)
        toggle()

    Behavior on submenuProgress {
        NumberAnimation {
            duration: Appearance.anim.durations.normal / 1.2
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: submenuCloseTimer
        interval: 150
        onTriggered: if (hoveredSubmenuIndex < 0) {
            submenuProgress = 0;
            Qt.callLater(() => {
                if (submenuProgress === 0) {
                    activeSubmenuIndex = -1;
                }
            });
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: mouse => mouse.accepted = true
    }

    Item {
        id: gooBounds
        visible: root.visible

        readonly property real menuLeft: menuContainer.x
        readonly property real menuTop: menuContainer.y
        readonly property real menuRight: menuContainer.x + menuContainer.width
        readonly property real menuBottom: menuContainer.y + menuContainer.height

        readonly property bool hasSub: submenuContainer.visible
        readonly property real subLeft: submenuContainer.x - root.gooOverlapPx
        readonly property real subTop: submenuContainer.y
        readonly property real subRight: submenuContainer.x + submenuContainer.width
        readonly property real subBottom: submenuContainer.y + submenuContainer.height

        readonly property real gooLeft: (hasSub ? Math.min(menuLeft, subLeft) : menuLeft) - root.gooMarginPx
        readonly property real gooTop: (hasSub ? Math.min(menuTop, subTop) : menuTop) - root.gooMarginPx
        readonly property real gooRight: (hasSub ? Math.max(menuRight, subRight) : menuRight) + root.gooMarginPx
        readonly property real gooBottom: (hasSub ? Math.max(menuBottom, subBottom) : menuBottom) + root.gooMarginPx

        x: gooLeft
        y: gooTop
        width: Math.max(1, gooRight - gooLeft)
        height: Math.max(1, gooBottom - gooTop)
    }

    ShaderEffect {
        id: gooEffect
        x: gooBounds.x
        y: gooBounds.y
        width: gooBounds.width
        height: gooBounds.height
        z: -2
        visible: root.visible

        property vector2d sizePx: Qt.vector2d(width, height)

        property vector4d menuRectPx: Qt.vector4d(menuContainer.x - gooBounds.x, menuContainer.y - gooBounds.y, menuContainer.width, menuContainer.height)

        property vector4d subRectPx: submenuContainer.visible ? Qt.vector4d((submenuContainer.x - gooBounds.x) - 24, submenuContainer.y - gooBounds.y, submenuContainer.width + 24, submenuContainer.height) : Qt.vector4d(0, 0, 0, 0)

        property real radiusPx: Appearance.rounding.normal * 0.75

        readonly property real topEdgeDiff: submenuContainer.visible ? Math.abs(menuContainer.y - submenuContainer.y) : 999
        readonly property real bottomEdgeDiff: submenuContainer.visible ? Math.abs((menuContainer.y + menuContainer.height) - (submenuContainer.y + submenuContainer.height)) : 999
        readonly property bool isTopAligned: submenuContainer.visible && topEdgeDiff < 10
        readonly property bool isBottomAligned: submenuContainer.visible && bottomEdgeDiff < 10

        property real smoothPxTop: isTopAligned ? 0 : 12
        property real smoothPxBottom: isBottomAligned ? 0 : 12

        property color fillColor: Colours.palette.m3surfaceContainer
        property color shadowColor: Qt.rgba(0, 0, 0, 0.20)
        property vector2d shadowOffsetPx: Qt.vector2d(0, 0)
        property real shadowSoftPx: 6

        vertexShader: Qt.resolvedUrl("shaders/goo_sdf.vert.qsb")
        fragmentShader: Qt.resolvedUrl("shaders/goo_sdf.frag.qsb")
    }

    Item {
        id: menuContainer

        x: 0
        y: 0
        width: menuColumn.implicitWidth + Appearance.padding.smaller * 2
        height: menuColumn.implicitHeight + Appearance.padding.smaller * 2

        opacity: 0

        scale: 0.80
        transformOrigin: Item.TopLeft
        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
        Behavior on scale {
            Anim {
                duration: Appearance.anim.durations.normal / 2
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }

        ColumnLayout {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: Appearance.padding.smaller
            spacing: Appearance.spacing.smaller

            MenuItem {
                text: qsTr("Launch")
                icon: "play_arrow"
                bold: true
                hasSubMenu: true
                submenuIndex: 0
            }

            Separator {}

            MenuItem {
                text: (root.app && Strings.testRegexList(Config.launcher.favouriteApps, root.app.id)) ? qsTr("Remove from Favourites") : qsTr("Add to Favourites")
                icon: "favorite"
                onTriggered: {
                    if (!root.app?.id)
                        return toggle();
                    const favourites = Config.launcher.favouriteApps.slice();
                    const index = favourites.indexOf(root.app.id);
                    if (index > -1)
                        favourites.splice(index, 1);
                    else
                        favourites.push(root.app.id);
                    Config.launcher.favouriteApps = favourites;
                    Config.save();
                    toggle();
                }
            }

            MenuItem {
                text: qsTr("Hide from Launcher")
                icon: "visibility_off"
                onTriggered: {
                    if (!root.app?.id)
                        return toggle();
                    const hidden = Config.launcher.hiddenApps.slice();
                    hidden.push(root.app.id);
                    Config.launcher.hiddenApps = hidden;
                    Config.save();
                    if (root.visibilities)
                        root.visibilities.launcher = false;
                    toggle();
                }
            }

            MenuItem {
                text: qsTr("Open in Workspace")
                icon: "workspaces"
                hasSubMenu: true
                submenuIndex: 4
            }

            Separator {}

            MenuItem {
                text: qsTr("Open .desktop File")
                icon: "description"
                onTriggered: {
                    if (root.app?.id) {
                        Quickshell.execDetached({
                            command: ["sh", "-c", `file=$(find ~/.local/share/applications /usr/share/applications /usr/local/share/applications /var/lib/flatpak/exports/share/applications ~/.local/share/flatpak/exports/share/applications -name '${root.app.id}.desktop' 2>/dev/null | head -n1); [ -n "$file" ] && xdg-open "$file"`]
                        });
                    }
                    toggle();
                }
            }
        }
    }

    Item {
        id: submenuContainer
        z: -1

        readonly property bool isTransitioning: targetSubmenuIndex >= 0

        // Interpolated dimensions and position
        property real interpolatedWidth: targetWidth
        property real interpolatedHeight: targetHeight
        property real interpolatedTopY: isTransitioning ? previousTopY : submenuItemY - targetHeight / 2

        property real centerOffset: (interpolatedHeight - interpolatedHeight * submenuProgress) / 2
        property real clampedY: {
            const unclampedY = interpolatedTopY + centerOffset;
            if (activeSubmenuIndex < 0 || height === 0)
                return unclampedY;

            // Clamp to menu top edge when close
            const topDiff = Math.abs(unclampedY - menuContainer.y);
            if (topDiff < 10) {
                return menuContainer.y;
            }

            // Clamp to menu bottom edge when close
            const menuBottom = menuContainer.y + menuContainer.height;
            const subBottom = unclampedY + height;
            const bottomDiff = Math.abs(subBottom - menuBottom);
            if (bottomDiff < 10) {
                return menuBottom - height;
            }

            // Clamp to screen bottom
            const maxY = (root.parent ? root.parent.height - root.y : 1000) - height - bottomPadding;
            return Math.min(unclampedY, maxY);
        }

        readonly property real slideOffsetX: -10 * (1 - submenuProgress)

        Behavior on interpolatedWidth {
            enabled: submenuProgress >= 1
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
        Behavior on interpolatedHeight {
            enabled: submenuProgress >= 1
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
        Behavior on interpolatedTopY {
            enabled: submenuProgress >= 1
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }

        width: (activeSubmenuIndex >= 0 && submenuProgress > 0) ? interpolatedWidth * submenuProgress : 0
        height: (activeSubmenuIndex >= 0 && submenuProgress > 0) ? interpolatedHeight * submenuProgress : 0

        x: menuContainer.width + slideOffsetX
        y: clampedY
        visible: width > 0 || height > 0
        clip: true

        ColumnLayout {
            id: submenuColumn
            anchors.fill: parent
            anchors.margins: Appearance.padding.smaller
            spacing: Appearance.spacing.smaller
            opacity: contentOpacity

            Loader {
                active: displayedSubmenuIndex === 0
                visible: displayedSubmenuIndex === 0
                Layout.fillWidth: true
                Layout.preferredHeight: active ? implicitHeight : 0
                sourceComponent: ContextMenus.LaunchSubmenu {
                    app: root.app
                    visibilities: root.visibilities
                    launchApp: root.launchApp
                    toggle: root.toggle
                }
            }

            Loader {
                active: displayedSubmenuIndex === 4
                visible: displayedSubmenuIndex === 4
                Layout.fillWidth: true
                Layout.preferredHeight: active ? implicitHeight : 0
                sourceComponent: ContextMenus.WorkspaceSubmenu {
                    launchApp: root.launchApp
                }
            }
        }
    }
}
