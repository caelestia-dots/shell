pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.bar as Bar
import qs.modules.dashboard as Dashboard
import qs.modules.launcher as Launcher
import qs.modules.notifications as Notifications
import qs.modules.osd as Osd
import qs.modules.session as Session
import qs.modules.sidebar as Sidebar
import qs.modules.utilities as Utilities
import qs.modules.bar.popouts as BarPopouts
import qs.modules.utilities.toasts as Toasts

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property Bar.BarWrapper bar
    required property real borderThickness

    readonly property alias osd: osd
    readonly property alias osdWrapper: osd
    readonly property alias notifications: notifications
    readonly property alias session: session
    readonly property alias sessionWrapper: sessionWrapper
    readonly property alias launcher: launcher
    readonly property alias dashboard: dashboard
    readonly property alias popouts: popoutsWrapper.content
    readonly property alias popoutsWrapper: popoutsWrapper
    readonly property alias utilities: utilities
    readonly property alias toasts: toasts
    readonly property alias sidebar: sidebar

    readonly property string barEdge: Config.bar.alignment
    readonly property bool barIsHorizontal: barEdge === "top" || barEdge === "bottom"
    readonly property real barThickness: barIsHorizontal ? bar.implicitHeight : bar.implicitWidth

    anchors.fill: parent
    anchors.margins: borderThickness
    anchors.topMargin: barEdge === "top" ? barThickness : borderThickness
    anchors.bottomMargin: barEdge === "bottom" ? barThickness : borderThickness
    anchors.leftMargin: barEdge === "left" ? barThickness : borderThickness
    anchors.rightMargin: barEdge === "right" ? barThickness : borderThickness

    Osd.Wrapper {
        id: osd
        screen: root.screen
        screenState: root.screenState
        sidebarOrSessionVisible: sidebar.visible || session.visible
       edgeOffset: edge === "right" ? session.width * (1 - session.offsetScale) : 0
    }

    Notifications.Wrapper {
        id: notifications
        
        width: implicitWidth

        screenState: root.screenState
        sidebarPanel: sidebar
        osdPanel: osd
        sessionPanel: sessionWrapper
        utilitiesPanel: utilities

        anchors.top: parent.top
        x: parent.width - width
    }

    Item {
        id: sessionWrapper
        
        width: implicitWidth

        anchors.verticalCenter: parent.verticalCenter
        x: parent.width - width - (sidebar.onLeft ? 0 : sidebar.width * (1 - sidebar.offsetScale))
        clip: sidebar.visible && !sidebar.onLeft

        implicitWidth: session.visible ? session.implicitWidth * (1 - session.offsetScale) : 0
        implicitHeight: session.implicitHeight

        Session.Wrapper {
            id: session
            
            width: implicitWidth

            screenState: root.screenState
            sidebarVisible: sidebar.visible && !sidebar.onLeft

            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Launcher.Wrapper {
        id: launcher

        screen: root.screen
        screenState: root.screenState
        panels: root
    }

    Dashboard.Wrapper {
        id: dashboard
        screenState: root.screenState
    }

    BarPopouts.ClipWrapper {
        id: popoutsWrapper
        screen: root.screen
        borderThickness: root.borderThickness
    }

    Utilities.Wrapper {
        id: utilities
        screenState: root.screenState
        sidebar: sidebar
        popouts: popoutsWrapper.content
    }

    Toasts.Toasts {
        id: toasts
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: Tokens.padding.medium
    }

    Sidebar.Wrapper {
        id: sidebar
        
        width: implicitWidth

        docked: Config.notifs.connectedToUtilities
        dockedAbove: docked && utilities.edge === "top"

        screenState: root.screenState
        onLeft: docked && (utilities.align === "start" || utilities.align === "left")

        x: onLeft ? (-width - 5) * offsetScale : parent.width - width + (width + 5) * offsetScale

        anchors.top: dockedAbove ? utilities.bottom : notifications.bottom
        anchors.bottom: (docked && !dockedAbove) ? utilities.top : parent.bottom
        
        anchors.topMargin: dockedAbove ? -1 : -notifications.anchors.topMargin
        anchors.bottomMargin: (docked && !dockedAbove) ? -1 : 0
    }
}
