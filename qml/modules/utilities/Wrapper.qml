pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
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
    readonly property bool shouldBeActive: screenState.sidebar || (screenState.utilities && Config.utilities.enabled && !(screenState.session && Config.session.enabled))
    readonly property real totalPadding: content.anchors.margins + CUtils.clamp(content.anchors.margins - Config.border.thickness, 0, content.anchors.margins)
    readonly property real nonAnimHeight: ((content.item as Content)?.nonAnimHeight ?? 0) + totalPadding
    property real offsetScale: shouldBeActive ? 0 : 1
    property real sidebarLerp

    visible: offsetScale < 1
    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: content.implicitHeight + totalPadding
    implicitWidth: sidebar.width * (1 - sidebar.offsetScale) * horizontalStretch * sidebarLerp + Tokens.sizes.utilities.width * (1 - sidebarLerp)
    opacity: 1 - offsetScale

    states: State {
        name: "attachedToSidebar"
        when: root.screenState.sidebar

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

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Tokens.padding.large

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
