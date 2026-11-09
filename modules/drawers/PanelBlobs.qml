pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.modules.bar as Bar

Item {
    id: root

    required property Panels panels
    required property Bar.BarWrapper bar
    required property color color
    required property real smoothing
    required property real deformScale
    required property real borderThickness
    required property real borderRounding
    required property real sdfBorderOffset

    readonly property alias dashboard: dashBg
    readonly property alias launcher: launcherBg
    readonly property alias session: sessionBg
    readonly property alias sidebar: sidebarBg
    readonly property alias osd: osdBg
    readonly property alias notifications: notifsBg
    readonly property alias utilities: utilsBg
    readonly property alias popouts: popoutBg

    BlobGroup {
        id: blobGroup

        color: root.color
        smoothing: root.smoothing
    }

    BlobInvertedRect {
        anchors.fill: parent
        anchors.margins: -50 // Make border thicker to smooth out bulge from closed drawers
        group: blobGroup
        radius: root.borderRounding
        borderLeft: root.bar.implicitWidth - anchors.margins - root.sdfBorderOffset
        borderRight: root.borderThickness - anchors.margins - root.sdfBorderOffset
        borderTop: root.borderThickness - anchors.margins - root.sdfBorderOffset
        borderBottom: root.borderThickness - anchors.margins - root.sdfBorderOffset
    }

    PanelBg {
        id: dashBg

        panel: root.panels.dashboard
        deformAmount: 0.1
    }

    PanelBg {
        id: launcherBg

        panel: root.panels.launcher
        deformAmount: 0.1
    }

    PanelBg {
        id: sessionBg

        panel: root.panels.sessionWrapper
        deformAmount: 0.2
        x: root.panels.sessionWrapper.x + root.panels.session.x + root.bar.implicitWidth
        implicitWidth: root.panels.session.width
    }

    PanelBg {
        id: sidebarBg

        panel: root.panels.sidebar
        deformAmount: 0.03
        implicitHeight: panel.height * (1 / rawDeformMatrix.m22) + 2
        exclude: root.panels.sidebar.offsetScale > 0.08 ? [] : [utilsBg]
        bottomLeftRadius: Math.max(0, Math.min(1, root.panels.sidebar.offsetScale / 0.3)) * radius
    }

    PanelBg {
        id: osdBg

        panel: root.panels.osdWrapper
        deformAmount: 0.25
        x: root.panels.osdWrapper.x + root.panels.osd.x + root.bar.implicitWidth
        implicitWidth: root.panels.osd.width
    }

    PanelBg {
        id: notifsBg

        panel: root.panels.notifications
    }

    PanelBg {
        id: utilsBg

        panel: root.panels.utilities
        deformAmount: root.panels.sidebar.visible ? 0.1 : 0.15
        exclude: root.panels.sidebar.offsetScale > 0.08 ? [] : [sidebarBg]
        topLeftRadius: Math.max(0, Math.min(1, root.panels.sidebar.offsetScale / 0.3)) * radius
    }

    PanelBg {
        id: popoutBg

        // Extra width to prevent vertical movement deformation partially detaching panel from bar
        property real extraWidth: root.panels.popouts.isDetached ? 0 : 0.2

        panel: root.panels.popoutsWrapper
        deformAmount: root.panels.popouts.isDetached ? 0.05 : root.panels.popouts.hasCurrent ? 0.15 : 0.1
        x: root.panels.popoutsWrapper.x + root.panels.popouts.x + root.bar.implicitWidth - root.panels.popouts.width * extraWidth
        implicitWidth: root.panels.popouts.width * (1 + extraWidth)

        Behavior on extraWidth {
            Anim {}
        }
    }

    component PanelBg: BlobRect {
        required property Item panel
        property real deformAmount: 0.15

        group: blobGroup
        x: panel.x + root.bar.implicitWidth
        y: panel.y + root.borderThickness
        implicitWidth: panel.width
        implicitHeight: panel.height
        radius: Tokens.rounding.extraLarge
        deformScale: (deformAmount * root.deformScale) / 10000
    }
}
