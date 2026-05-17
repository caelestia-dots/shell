pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus
import qs.modules.nexus.components

Item {
    id: root

    required property ShellScreen screen

    readonly property int rounding: floating ? 0 : Tokens.rounding.normal
    readonly property int borderPad: 50

    property bool floating: false
    property alias active: session.activeCategory
    property alias sidebarCollapsed: session.sidebarCollapsed

    readonly property NexusSession session: NexusSession {
        id: session

        nexusRoot: root
    }

    readonly property bool flyoutOverlapsPopout: flyout.open && unifiedPopout.open && flyout.y < unifiedPopout.y + unifiedPopout.drawerHeight && flyout.y + flyout.drawerHeight > unifiedPopout.y

    signal close

    implicitWidth: implicitHeight * 1.67
    implicitHeight: Math.min(1000, screen.height * 0.85)

    ContentArea {
        anchors.left: sidebar.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        clip: true
        session: root.session
    }

    Item {
        id: blobLayer

        anchors.fill: parent
        opacity: Colours.tPalette.m3surfaceContainer.a
        layer.enabled: true // So children don't opacity stack

        Behavior on opacity {
            Anim {}
        }

        BlobGroup {
            id: blobGroup

            color: Qt.alpha(Colours.tPalette.m3surfaceContainer, 1)
            smoothing: 28

            Behavior on color {
                CAnim {}
            }
        }

        // Border frame
        BlobInvertedRect {
            anchors.fill: parent
            anchors.margins: -root.borderPad
            group: blobGroup
            radius: Tokens.rounding.small
            borderLeft: sidebar.width + 10 + root.borderPad
            borderTop: 10 + root.borderPad
            borderRight: 10 + root.borderPad
            borderBottom: 10 + root.borderPad
        }

        BlobRect {
            id: notchBlob

            anchors.right: parent.right
            group: blobGroup
            implicitWidth: windowControls.width + windowControls.anchors.rightMargin * 2
            implicitHeight: windowControls.height + windowControls.anchors.topMargin * 2
            bottomLeftRadius: Tokens.rounding.normal
            deformScale: 0
        }

        BlobRect {
            id: flyoutBlob

            group: blobGroup
            x: flyout.x
            y: flyout.y
            implicitWidth: flyout.drawerWidth
            implicitHeight: flyout.drawerHeight
            radius: Tokens.rounding.small
            // topLeftRadius: 0
            // bottomLeftRadius: 0
            // topRightRadius: flyout.y <= 0 ? 0 : Tokens.rounding.small
            deformScale: 0.00001
            stiffness: 200
            damping: 16
        }

        BlobRect {
            id: popoutBlob

            group: blobGroup
            x: unifiedPopout.x
            y: unifiedPopout.y
            implicitWidth: unifiedPopout.drawerWidth
            implicitHeight: unifiedPopout.drawerHeight
            visible: session.sidebarCollapsed
            radius: Tokens.rounding.normal
            // topLeftRadius: 0
            // topRightRadius: 0
            // bottomLeftRadius: 0
            deformScale: 0.00001
            stiffness: 200
            damping: 16
        }
    }

    Sidebar {
        id: sidebar

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: session.sidebarCollapsed ? 100 : 250

        session: root.session

        Behavior on implicitWidth {
            Anim {
                type: Anim.DefaultSpatial
            }
        }
    }

    RowLayout {
        id: windowControls

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Tokens.padding.smaller
        anchors.rightMargin: Tokens.padding.normal
        spacing: 0

        IconButton {
            type: IconButton.Text
            icon: root.floating ? "pip" : "pip_exit" // Yes, I know this looks reversed but it really isn't
            label.fill: 0
            inactiveOnColour: Colours.palette.m3onSurfaceVariant
            onClicked: {
                Hyprland.dispatch("togglefloating");
                root.floating = !root.floating;
            }
        }

        IconButton {
            type: IconButton.Text
            icon: "close"
            inactiveOnColour: Colours.palette.m3onSurfaceVariant
            onClicked: root.close()
        }
    }

    SidebarFlyout {
        id: flyout

        session: root.session
        flyoutCategory: sidebar.flyoutCategory
        open: session.sidebarCollapsed && sidebar.flyoutCategory !== ""

        x: sidebar.width
        y: sidebar.flyoutTop

        onHoverEntered: sidebar.cancelFlyoutClose()
        onHoverExited: sidebar.scheduleFlyoutClose()
        onChildClicked: id => session.setCategory(id)

        Behavior on y {
            enabled: flyout.open

            Anim {
                type: Anim.DefaultSpatial
            }
        }
    }

    Component {
        id: searchComponent

        SearchEngine {
            session: root.session // qmllint disable incompatible-type
        }
    }

    Component {
        id: configComponent

        ConfigSwitcher {
            session: root.session // qmllint disable incompatible-type
        }
    }

    SidebarPopout {
        id: unifiedPopout

        x: sidebar.width
        y: 0
        visible: session.sidebarCollapsed
        touchingTop: true
        extraLeftMargin: root.flyoutOverlapsPopout ? flyout.drawerWidth : 0
        flyoutDrawerWidth: flyout.drawerWidth
        flyoutOpen: flyout.open

        open: session.searchPopoutOpen || session.configPopoutOpen
        popoutType: session.searchPopoutOpen ? "search" : session.configPopoutOpen ? "config" : ""
        popoutWidth: popoutType === "search" ? 280 : 275

        Component.onCompleted: {
            setComponents(searchComponent, configComponent);
        }
    }

    MouseArea {
        x: sidebar.width
        y: 0
        width: parent.width - sidebar.width
        height: parent.height
        z: -1
        visible: session.sidebarCollapsed && (session.searchPopoutOpen || session.configPopoutOpen)

        onClicked: {
            session.searchPopoutOpen = false;
            session.configPopoutOpen = false;
        }
    }
}
