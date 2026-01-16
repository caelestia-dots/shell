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
    property bool showAbove: false  // Position menu above or below the item

    visible: false
    enabled: app !== null
    
    implicitWidth: menuContainer.width
    implicitHeight: menuContainer.height

    signal closed()

    function toggle(): void {
        if (!root.app) {
            console.warn("Cannot toggle context menu without an app");
            return;
        }
        
        root.visible = !root.visible;
        if (root.visible) {
            root.forceActiveFocus();
        }
    }

    function hide(): void {
        root.visible = false;
        root.app = null;
        root.closed();
    }
    
    function show(): void {
        if (!root.app) {
            return;
        }
        
        root.visible = true;
        root.forceActiveFocus();
    }

    onActiveFocusChanged: {
        if (!activeFocus && visible) {
            hide();
        }
    }

    // Block mouse events from passing through
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

        Separator {}

        MenuItem {
            text: (root.app && Strings.testRegexList(Config.launcher.favoriteApps, root.app.id)) ? qsTr("Remove from Favorites") : qsTr("Add to Favorites")
            icon: "favorite"
            onTriggered: {
                if (!root.app || !root.app.id) {
                    root.hide();
                    return;
                }
                
                try {
                    const appId = root.app.id;
                    const favorites = Config.launcher.favoriteApps.slice();
                    const index = favorites.indexOf(appId);
                    
                    if (index > -1) {
                        favorites.splice(index, 1);
                    } else {
                        favorites.push(appId);
                    }
                    
                    Config.launcher.favoriteApps = favorites;
                    Config.save();
                } catch (error) {
                    console.error("Failed to toggle favorite:", error);
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
            text: qsTr("Copy App ID")
            icon: "content_copy"
            onTriggered: {
                if (root.app && root.app.id) {
                    try {
                        Quickshell.clipboard = root.app.id;
                    } catch (error) {
                        console.error("Failed to copy app ID:", error);
                    }
                }
                root.hide();
            }
        }

        MenuItem {
            text: qsTr("Open .desktop File")
            icon: "description"
            onTriggered: {
                if (root.app && root.app.path) {
                    try {
                        Quickshell.execDetached({
                            command: ["xdg-open", root.app.path]
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

        signal triggered()

        Layout.fillWidth: true
        Layout.preferredWidth: 220
        implicitHeight: itemRow.implicitHeight + Appearance.padding.small * 2

        radius: Appearance.rounding.small
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            
            onClicked: menuItem.triggered()
            
            onEntered: menuItem.color = Qt.alpha(Colours.palette.m3onSurface, 0.08)
            onExited: menuItem.color = "transparent"
            onPressed: menuItem.color = Qt.alpha(Colours.palette.m3onSurface, 0.12)
            onReleased: menuItem.color = containsMouse ? Qt.alpha(Colours.palette.m3onSurface, 0.08) : "transparent"
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
                Layout.fillWidth: true
                text: menuItem.text
                color: Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.normal
                font.weight: menuItem.bold ? Font.DemiBold : Font.Normal
            }
        }
    }

    component Separator: StyledRect {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Colours.palette.m3outlineVariant
    }
}
