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
import QtQuick.Shapes

Item {
    id: root

    property DesktopEntry app: null
    property PersistentProperties visibilities
    property bool showAbove: false
    property int activeSubmenuIndex: -1
    property int targetSubmenuIndex: -1
    property real submenuProgress: 0
    property bool submenuWasFullyOpen: false
    property int hoveredSubmenuIndex: -1
    property real contentOpacity: 1
    property real submenuItemY: 0
    property int displayedSubmenuIndex: -1
    property real targetWidth: 0
    property real targetHeight: 0
    property real previousTargetWidth: 0
    property real previousTargetHeight: 0
    property real previousTopY: 0

    Behavior on contentOpacity {
        Anim {
            duration: Appearance.anim.durations.small
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    readonly property real bottomPadding: 16
    readonly property real cornerRadius: Appearance.rounding.normal
    readonly property real notchRadius: 15
    readonly property real tolerance: 0.5

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
            contentOpacity = 1;
            Qt.callLater(() => {
                targetWidth = submenuColumn.implicitWidth + Appearance.padding.smaller * 2;
                targetHeight = submenuColumn.implicitHeight + Appearance.padding.smaller * 2;
            });
        } else if (activeSubmenuIndex !== hoveredSubmenuIndex) {
            previousTargetWidth = targetWidth;
            previousTargetHeight = targetHeight;
            previousTopY = submenuContainer.interpolatedTopY;
            targetSubmenuIndex = hoveredSubmenuIndex;
            contentOpacity = 0;
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
        interval: 300
        onTriggered: if (hoveredSubmenuIndex < 0) {
            submenuProgress = 0;
            Qt.callLater(() => {
                if (submenuProgress === 0) {
                    activeSubmenuIndex = -1;
                    submenuWasFullyOpen = false;
                }
            });
        }
    }

    onSubmenuProgressChanged: submenuWasFullyOpen = submenuProgress >= 1 ? true : (submenuProgress === 0 ? false : submenuWasFullyOpen)
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: mouse => mouse.accepted = true
    }

    Elevation {
        id: menuContainer

        x: 0
        y: 0
        width: menuColumn.implicitWidth + Appearance.padding.smaller * 2
        height: menuColumn.implicitHeight + Appearance.padding.smaller * 2

        radius: cornerRadius
        level: 3
        opacity: 0

        // Dynamic corner radii based on submenu position
        property real topRightRadius: cornerRadius
        property real bottomRightRadius: cornerRadius

        Behavior on topRightRadius {
            NumberAnimation {
                duration: Appearance.anim.durations.normal * 0.5
                easing.type: Easing.OutCubic
            }
        }
        Behavior on bottomRightRadius {
            NumberAnimation {
                duration: Appearance.anim.durations.normal * 0.5
                easing.type: Easing.OutCubic
            }
        }

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
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }

        ContextMenus.RoundedRect {
            anchors.fill: parent
            fillColor: Colours.palette.m3surfaceContainer
            topLeftRadius: cornerRadius
            topRightRadius: menuContainer.topRightRadius
            bottomRightRadius: menuContainer.bottomRightRadius
            bottomLeftRadius: cornerRadius
        }

        Rectangle {
            x: parent.width
            y: submenuContainer.visible ? submenuContainer.y - parent.y + (submenuContainer.topLeftRadius > 0 ? cornerRadius : 0) : 0
            width: submenuContainer.visible && submenuContainer.width > 0 ? 6 : 0
            height: {
                if (!submenuContainer.visible)
                    return 0;
                const topR = submenuContainer.topLeftRadius;
                const botR = submenuContainer.bottomLeftRadius;
                return Math.max(0, submenuContainer.height - (topR > 0 ? cornerRadius : 0) - (botR > 0 ? cornerRadius : 0));
            }
            color: Colours.palette.m3surfaceContainer
            z: 10
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

    Elevation {
        id: submenuContainer
        z: -1
        level: 1

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
            const maxY = (root.parent ? root.parent.height - root.y : 1000) - height - bottomPadding;
            return Math.min(unclampedY, maxY);
        }

        property real animatedTopEdge: clampedY
        property real animatedBottomEdge: clampedY + height
        property real topDiff: Math.abs(y - menuContainer.y)
        property real bottomDiff: Math.abs((y + height) - (menuContainer.y + menuContainer.height))

        property real topLeftRadius: (activeSubmenuIndex >= 0 && notchScale > 0 && y > menuContainer.y + tolerance) ? 0 : cornerRadius
        property real bottomLeftRadius: (activeSubmenuIndex >= 0 && notchScale > 0 && y + height < menuContainer.y + menuContainer.height - tolerance) ? 0 : cornerRadius

        // Update main menu corner radii
        onTopDiffChanged: updateMainCorners()
        onBottomDiffChanged: updateMainCorners()
        onYChanged: updateMainCorners()
        onHeightChanged: updateMainCorners()

        function updateMainCorners() {
            if (activeSubmenuIndex < 0 || height === 0) {
                menuContainer.topRightRadius = menuContainer.bottomRightRadius = cornerRadius;
                return;
            }
            menuContainer.topRightRadius = (notchScale > 0 && y < menuContainer.y - tolerance) ? 0 : cornerRadius;
            menuContainer.bottomRightRadius = (notchScale > 0 && y + height > menuContainer.y + menuContainer.height + tolerance) ? 0 : cornerRadius;
        }

        readonly property real notchScale: submenuProgress
        readonly property real slideOffsetY: notchRadius * 2 * (1 - submenuProgress)
        readonly property real closeYOffset: submenuWasFullyOpen && submenuProgress < 1 ? notchRadius * (1 - submenuProgress) : 0
        readonly property real slideOffsetX: closeYOffset

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

        x: menuContainer.width - 20 * (1 - submenuProgress)
        y: clampedY
        radius: cornerRadius
        visible: width > 0 || height > 0
        clip: true

        ContextMenus.RoundedRect {
            anchors.fill: parent
            fillColor: Colours.palette.m3surfaceContainer
            topLeftRadius: submenuContainer.topLeftRadius
            topRightRadius: cornerRadius
            bottomRightRadius: cornerRadius
            bottomLeftRadius: submenuContainer.bottomLeftRadius
        }

        Rectangle {
            x: parent.width
            y: submenuContainer.topLeftRadius > 0 ? cornerRadius : 0
            width: submenuContainer.visible && submenuContainer.width > 0 ? 6 : 0
            height: {
                const topR = submenuContainer.topLeftRadius;
                const botR = submenuContainer.bottomLeftRadius;
                return Math.max(0, parent.height - (topR > 0 ? cornerRadius : 0) - (botR > 0 ? cornerRadius : 0));
            }
            color: Colours.palette.m3surfaceContainer
            z: 10
        }

        ColumnLayout {
            id: submenuColumn
            anchors.fill: parent
            anchors.margins: Appearance.padding.smaller
            spacing: Appearance.spacing.smaller
            opacity: contentOpacity

            Behavior on opacity {
                Anim {
                    duration: Appearance.anim.durations.small
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }

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

    ContextMenus.MenuNotch {
        visible: submenuContainer.visible && submenuContainer.notchScale > 0.01
        property bool onMenuSide: submenuContainer.animatedTopEdge > menuContainer.y
        cornerX: (onMenuSide ? menuContainer.x + menuContainer.width : submenuContainer.x) - submenuContainer.slideOffsetX
        cornerY: (onMenuSide ? submenuContainer.animatedTopEdge : menuContainer.y) + submenuContainer.slideOffsetY + submenuContainer.closeYOffset
        radius: notchRadius * submenuContainer.notchScale
        directionX: onMenuSide ? 1 : -1
        directionY: -1
        fillColor: Colours.palette.m3surfaceContainer
        opacity: submenuContainer.notchScale
    }

    ContextMenus.MenuNotch {
        visible: submenuContainer.visible && submenuContainer.notchScale > 0.01
        property bool onMenuSide: submenuContainer.animatedBottomEdge < menuContainer.y + menuContainer.height
        cornerX: (onMenuSide ? menuContainer.x + menuContainer.width : submenuContainer.x) - submenuContainer.slideOffsetX
        cornerY: (onMenuSide ? submenuContainer.animatedBottomEdge : menuContainer.y + menuContainer.height) - submenuContainer.slideOffsetY - submenuContainer.closeYOffset
        radius: notchRadius * submenuContainer.notchScale
        directionX: onMenuSide ? 1 : -1
        directionY: 1
        fillColor: Colours.palette.m3surfaceContainer
        opacity: submenuContainer.notchScale
    }
}
