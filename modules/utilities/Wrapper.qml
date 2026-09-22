pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.utils
import qs.modules.sidebar as Sidebar
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ScreenState screenState
    required property Sidebar.Wrapper sidebar
    required property BarPopouts.Wrapper popouts
    property real horizontalStretch
    property matrix4x4 deformMatrix

    readonly property PersistentProperties props: PersistentProperties {
        property bool recordingListExpanded: false
        property string recordingConfirmDelete
        property string recordingMode

        reloadableId: "utilities"
    }

    readonly property bool shouldBeActive: (Config.notifs.connectedToUtilities && screenState.sidebar) || (screenState.utilities && Config.utilities.enabled && !(screenState.session && Config.session.enabled))

    readonly property bool onLeft: align === "start" || align === "left"

    readonly property real padding: Tokens.padding.large
    readonly property real clampedPadding: CUtils.clamp(padding - Config.border.thickness, 0, padding)
    readonly property real totalPadding: padding + clampedPadding

    readonly property real nonAnimHeight: ((content.item as Content)?.nonAnimHeight ?? 0) + totalPadding
    property real offsetScale: shouldBeActive ? 0 : 1
    property real sidebarLerp

    readonly property var validCorners: ["top-left", "top-right", "bottom-left", "bottom-right"]
    readonly property string configuredPlacement: root.validCorners.includes((Config.utilities.placement ?? "").toLowerCase()) ? Config.utilities.placement.toLowerCase() : "bottom-right"
    readonly property string placement: configuredPlacement
    readonly property string edge: Placement.edge(placement)
    readonly property string align: Placement.align(placement)

    readonly property bool flattenTop: sidebar.docked && !sidebar.dockedAbove
    readonly property bool flattenBottom: sidebar.docked && sidebar.dockedAbove

    readonly property real offsetX: Placement.offsetX(placement, implicitWidth, offsetScale)
    readonly property real offsetY: Placement.offsetY(placement, implicitHeight, offsetScale)

    readonly property real baseX: Placement.baseX(placement, parent.width, implicitWidth)
    readonly property real baseY: Placement.baseY(placement, parent.height, implicitHeight)

    x: baseX + offsetX
    y: baseY + offsetY

    visible: offsetScale < 1
    implicitHeight: content.implicitHeight + totalPadding
    implicitWidth: sidebar.width * (1 - sidebar.offsetScale) * horizontalStretch * sidebarLerp + Tokens.sizes.utilities.width * (1 - sidebarLerp)
    opacity: 1 - offsetScale

    states: State {
        name: "attachedToSidebar"
        when: GlobalConfig.notifs.connectedToUtilities && root.screenState.sidebar

        PropertyChanges {
            root.sidebarLerp: 1
        }
    }

    transitions: [
        Transition {
            from: ""

            Anim {
                property: "sidebarLerp"
                duration: Tokens.anim.durations.expressiveDefaultSpatial / 2
                easing: Tokens.anim.standardAccel
            }
        },
        Transition {
            to: ""

            Anim {
                property: "sidebarLerp"
                duration: Tokens.anim.durations.expressiveDefaultSpatial / 2
                easing: Tokens.anim.standardDecel
            }
        }
    ]

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        width: implicitWidth
        anchors.top: parent.top

        x: root.onLeft ? root.clampedPadding : root.padding
        anchors.topMargin: root.edge === "top" ? root.clampedPadding : root.padding
        anchors.bottomMargin: root.edge === "top" ? root.padding : root.clampedPadding

        asynchronous: true
        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            implicitWidth: root.implicitWidth - root.totalPadding
            props: root.props
            screenState: root.screenState
            popouts: root.popouts
            deformMatrix: root.deformMatrix
        }
    }
}
