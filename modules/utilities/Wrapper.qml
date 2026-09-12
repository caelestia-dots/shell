pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.sidebar as Sidebar
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ScreenState screenState
    required property Sidebar.Wrapper sidebar
    required property BarPopouts.Wrapper popouts

    property real horizontalStretch
    property matrix4x4 deformMatrix

    //
    // Phone browser state.
    //
    property bool browserOpen: false
    property string browserDeviceId: ""
    property string browserDeviceName: ""
    property string browserRootPath: ""

    signal browserOpened()

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

    //
    // Keep the original Utilities dimensions.
    // The browser does not change the panel size.
    //
    implicitHeight: content.implicitHeight + totalPadding

    implicitWidth: sidebar.width * (1 - sidebar.offsetScale) * horizontalStretch * sidebarLerp + Tokens.sizes.utilities.width * (1 - sidebarLerp)

    opacity: 1 - offsetScale

    function openForDevice(deviceId: string, deviceName: string, rootPath: string): void {
        if (!deviceId || !rootPath)
            return;

        root.screenState.launcher = false;
        root.screenState.session = false;
        root.screenState.dashboard = false;
        root.screenState.sidebar = false;

        //
        // Utilities stays open.
        //
        root.screenState.utilities = true;

        root.browserDeviceId = deviceId;
        root.browserDeviceName = deviceName;
        root.browserRootPath = rootPath;

        root.browserOpen = true;
        root.browserOpened();
    }

    function closeBrowser(): void {
        root.browserOpen = false;
        root.screenState.utilities = true;
    }

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

    //
    // If Utilities itself closes, next open starts
    // on the normal Utilities page.
    //
    Connections {
        target: root.screenState

        function onUtilitiesChanged() {
            if (!root.screenState.utilities)
                root.browserOpen = false;
        }

        function onSidebarChanged() {
            if (root.screenState.sidebar)
                root.browserOpen = false;
        }

        function onLauncherChanged() {
            if (root.screenState.launcher)
                root.browserOpen = false;
        }

        function onSessionChanged() {
            if (root.screenState.session)
                root.browserOpen = false;
        }

        function onDashboardChanged() {
            if (root.screenState.dashboard)
                root.browserOpen = false;
        }
    }

    //
    // Phone lifecycle.
    //
    Connections {
        target: KdeConnect

        function onMountsChanged() {
            if (!root.browserOpen || !root.browserDeviceId) {
                return;
            }

            if (!KdeConnect.isMounted(root.browserDeviceId)) {
                root.browserOpen = false;
                root.screenState.utilities = false;
            }
        }

        function onDevicesChanged() {
            if (!root.browserOpen || !root.browserDeviceId) {
                return;
            }

            const connected = KdeConnect.devices.some(device => device.id === root.browserDeviceId);

            if (!connected) {
                root.browserOpen = false;
                root.screenState.utilities = false;
            }
        }
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

            wrapper: root
        }
    }
}
