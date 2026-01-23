import "../services"
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
    property bool isAnimating: false
    property var activeSubMenuItem: null
    
    visible: false
    enabled: app !== null
    implicitWidth: menuContainer.width
    implicitHeight: menuContainer.height
    
    states: [
        State {
            name: "visible"
            when: root.visible || root.isAnimating
            PropertyChanges { target: root; opacity: 1 }
        },
        State {
            name: "hidden"
            when: !root.visible && !root.isAnimating
            PropertyChanges { target: root; opacity: 0 }
        }
    ]

    signal closed()

    function toggle(): void {
        if (!root.app) {
            console.warn("Cannot toggle context menu without an app");
            return;
        }
        
        if (root.visible) {
            hide();
        } else {
            if (root.activeSubMenuItem) {
                if (root.activeSubMenuItem.closeSubMenuTimer) {
                    root.activeSubMenuItem.closeSubMenuTimer.stop();
                }
                root.activeSubMenuItem.subMenuOpen = false;
                root.activeSubMenuItem = null;
            }
            root.visible = true;
            root.isAnimating = false;
            menuContainer.opacity = 1;
            menuContainer.scale = 1;
            root.forceActiveFocus();
        }
    }

    function hide(): void {
        if (root.activeSubMenuItem) {
            if (root.activeSubMenuItem.closeSubMenuTimer) {
                root.activeSubMenuItem.closeSubMenuTimer.stop();
            }
            root.activeSubMenuItem.subMenuOpen = false;
        }
        
        root.isAnimating = true;
        menuContainer.opacity = 0;
        menuContainer.scale = 0.8;
        hideTimer.restart();
    }
    
    Timer {
        id: hideTimer
        interval: 200
        onTriggered: {
            if (root.activeSubMenuItem) {
                root.activeSubMenuItem.subMenuOpen = false;
                root.activeSubMenuItem = null;
            }
            root.visible = false;
            root.isAnimating = false;
            root.app = null;
            root.closed();
        }
    }
    
    function show(): void {
        if (root.app) {
            root.visible = true;
            root.forceActiveFocus();
        }
    }

    onActiveFocusChanged: {
        if (!activeFocus && visible) {
            hide();
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onClicked: (mouse) => { mouse.accepted = true; }
        onWheel: (wheel) => { wheel.accepted = true; }
    }
    
    Elevation {
        id: menuContainer

        x: 0
        y: 0
        width: menuColumn.implicitWidth + Appearance.padding.smaller * 2
        height: menuColumn.implicitHeight + Appearance.padding.smaller * 2

        radius: Appearance.rounding.normal
        level: 3
        
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
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }

        StyledClippingRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3surfaceContainer

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
            
            subMenuComponent: Component {
                SubMenu {
                    MenuItem {
                        text: qsTr("Launch")
                        icon: "play_arrow"
                        onTriggered: {
                            if (root.app) {
                                Apps.launch(root.app);
                                if (root.visibilities) {
                                    root.visibilities.launcher = false;
                                }
                            }
                            root.hide();
                        }
                    }
                    
                    Repeater {
                        model: root.app ? root.app.actions : []
                        
                        MenuItem {
                            required property var modelData
                            
                            text: modelData.name || ""
                            icon: "play_arrow"
                            visible: text.length > 0
                            onTriggered: {
                                if (root.app && modelData && modelData.execute) {
                                    try {
                                        modelData.execute();
                                        if (root.visibilities) {
                                            root.visibilities.launcher = false;
                                        }
                                    } catch (error) {
                                        console.error("Failed to execute action:", error);
                                    }
                                }
                                root.hide();
                            }
                        }
                    }
                    
                    Separator {
                        visible: root.app && root.app.actions && root.app.actions.length > 0
                    }
                    
                    MenuItem {
                        text: qsTr("Run in Terminal")
                        icon: "terminal"
                        onTriggered: {
                            if (root.app && root.app.execString) {
                                try {
                                    Quickshell.execDetached({
                                        command: [...Config.general.apps.terminal, "-e", root.app.execString]
                                    });
                                    if (root.visibilities) {
                                        root.visibilities.launcher = false;
                                    }
                                } catch (error) {
                                    console.error("Failed to run in terminal:", error);
                                }
                            }
                            root.hide();
                        }
                    }
                }
            }
        }

        Separator {}

        MenuItem {
            text: (root.app && Strings.testRegexList(Config.launcher.favouriteApps, root.app.id)) ? qsTr("Remove from Favourites") : qsTr("Add to Favourites")
            icon: "favorite"
            onTriggered: {
                if (!root.app || !root.app.id) {
                    root.hide();
                    return;
                }
                
                try {
                    const appId = root.app.id;
                    const favourites = Config.launcher.favouriteApps.slice();
                    const index = favourites.indexOf(appId);
                    
                    if (index > -1) {
                        favourites.splice(index, 1);
                    } else {
                        favourites.push(appId);
                    }
                    
                    Config.launcher.favouriteApps = favourites;
                    Config.save();
                } catch (error) {
                    console.error("Failed to toggle favourite:", error);
                }
                
                root.hide();
            }
        }

        MenuItem {
            text: qsTr("Hide from Launcher")
            icon: "visibility_off"
            onTriggered: {
                if (!root.app || !root.app.id) {
                    root.hide();
                    return;
                }
                
                try {
                    const appId = root.app.id;
                    const hidden = Config.launcher.hiddenApps.slice();
                    hidden.push(appId);
                    Config.launcher.hiddenApps = hidden;
                    Config.save();
                    if (root.visibilities) {
                        root.visibilities.launcher = false;
                    }
                } catch (error) {
                    console.error("Failed to hide app:", error);
                }
                
                root.hide();
            }
        }

        Separator {}

        MenuItem {
            text: qsTr("Open .desktop File")
            icon: "description"
            onTriggered: {
                if (root.app && root.app.id) {
                    try {
                        const desktopFileName = root.app.id + ".desktop";
                        
                        // Use find to locate the .desktop file in standard locations
                        Quickshell.execDetached({
                            command: ["sh", "-c", 
                                `file=$(find ~/.local/share/applications /usr/share/applications /usr/local/share/applications /var/lib/flatpak/exports/share/applications ~/.local/share/flatpak/exports/share/applications -name '${desktopFileName}' 2>/dev/null | head -n1); [ -n "$file" ] && xdg-open "$file" || echo "File not found"`
                            ]
                        });
                    } catch (error) {
                        console.error("Failed to open .desktop file:", error);
                    }
                }
                root.hide();
            }
        }
            }
        }
    }

    component MenuItem: StyledRect {
        id: menuItem

        property string text: ""
        property string icon: ""
        property bool bold: false
        property bool hasSubMenu: false
        property Component subMenuComponent: null
        property bool subMenuOpen: false

        signal triggered()
        signal hovered()
        
        property Timer closeSubMenuTimer: Timer {
            interval: 200
            onTriggered: {
                menuItem.subMenuOpen = false;
            }
        }
        
        function closeSubMenu(): void {
            if (subMenuLoader.item) {
                subMenuLoader.item.width = 0;
                closeSubMenuTimer.restart();
            } else {
                menuItem.subMenuOpen = false;
            }
            menuItem.color = "transparent";
        }

        Layout.fillWidth: true
        Layout.minimumWidth: itemRow.implicitWidth + Appearance.padding.small * 2
        implicitHeight: itemRow.implicitHeight + Appearance.padding.small * 2

        radius: Appearance.rounding.small
        color: "transparent"

        Timer {
            id: hoverTimer
            interval: 250
            onTriggered: {
                if (menuItem.hasSubMenu && mouseArea.containsMouse) {
                    menuItem.subMenuOpen = true;
                }
            }
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: hasSubMenu ? Qt.ArrowCursor : Qt.PointingHandCursor
            
            onClicked: {
                if (!hasSubMenu) {
                    menuItem.triggered();
                }
            }
            
            onEntered: {
                menuItem.color = Qt.alpha(Colours.palette.m3onSurface, 0.08);
                menuItem.hovered();
                
                const isTopLevel = menuItem.parent === menuColumn;
                
                if (isTopLevel) {
                    if (root.activeSubMenuItem && root.activeSubMenuItem !== menuItem) {
                        root.activeSubMenuItem.closeSubMenu();
                    }
                    
                    if (menuItem.hasSubMenu) {
                        root.activeSubMenuItem = menuItem;
                        hoverTimer.restart();
                    }
                }
            }
            
            onExited: {
                hoverTimer.stop();
                if (!menuItem.hasSubMenu) {
                    menuItem.color = "transparent";
                }
            }
            
            onPressed: {
                if (!hasSubMenu) {
                    menuItem.color = Qt.alpha(Colours.palette.m3onSurface, 0.12);
                }
            }
            
            onReleased: {
                if (!hasSubMenu) {
                    menuItem.color = containsMouse ? Qt.alpha(Colours.palette.m3onSurface, 0.08) : "transparent";
                }
            }
        }

        RowLayout {
            id: itemRow

            anchors.fill: parent
            anchors.margins: Appearance.padding.small
            spacing: Appearance.spacing.normal

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                text: menuItem.icon
                visible: text.length > 0
                color: Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.normal
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: menuItem.text
                color: Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.normal
                font.weight: menuItem.bold ? Font.DemiBold : Font.Normal
                elide: Text.ElideNone
                wrapMode: Text.NoWrap
            }
            
            Item {
                Layout.fillWidth: true
            }
            
            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                text: "chevron_right"
                visible: menuItem.hasSubMenu
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.normal
            }
        }
        
        Loader {
            id: subMenuLoader
            active: menuItem.subMenuOpen
            sourceComponent: menuItem.subMenuComponent
            
            onLoaded: {
                if (item) {
                    item.parent = root;
                    item.x = menuContainer.width;
                    item.y = menuItem.mapToItem(root, 0, 0).y;
                    item.z = 10001;
                    item.visible = true;
                    item.width = 0;
                    Qt.callLater(() => {
                        if (item) item.width = item.targetWidth;
                    });
                }
            }
        }
    }

    component SubMenu: Item {
        id: subMenu
        
        property bool containsMouse: subMenuMouseArea.containsMouse
        default property alias content: subMenuColumn.data
        property real targetWidth: subMenuColumn.implicitWidth + Appearance.padding.smaller * 2
        
        width: 0
        height: subMenuColumn.implicitHeight + Appearance.padding.smaller * 2
        
        Behavior on width {
            Anim {
                duration: 200
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
        
        Elevation {
            anchors.fill: parent
            radius: Appearance.rounding.normal
            level: 3
            
            MouseArea {
                id: subMenuMouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.AllButtons
                onClicked: (mouse) => { mouse.accepted = true; }
                onWheel: (wheel) => { wheel.accepted = true; }
            }
            
            StyledClippingRect {
                anchors.fill: parent
                color: Colours.palette.m3surfaceContainer
                topLeftRadius: 0
                topRightRadius: Appearance.rounding.normal
                bottomLeftRadius: 0
                bottomRightRadius: Appearance.rounding.normal
                
                ColumnLayout {
                    id: subMenuColumn
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.smaller
                    spacing: Appearance.spacing.smaller
                }
            }
        }
    }

    component Separator: StyledRect {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Colours.palette.m3outlineVariant
    }
}
