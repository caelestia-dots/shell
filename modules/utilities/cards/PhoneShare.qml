pragma ComponentBehavior: Bound

import ".." as Utilities
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils

StyledRect {
    id: root

    required property ScreenState screenState

    property bool browserOpen
    property string browserDeviceId
    property string browserDeviceName
    property string browserRootPath
    // Device whose storage is being checked before its browser opens
    property string pendingBrowseDevice
    // Unmounting or losing the device leaves nothing to browse
    readonly property bool browserDeviceMounted: KdeConnect.isMounted(browserDeviceId)

    // The browser keeps a fixed height and scrolls its file list inside it
    readonly property real browserHeight: Tokens.sizes.utilities.width * 0.8
    readonly property real compactHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased
    readonly property real nonAnimHeight: browserOpen ? browserHeight : compactHeight
    // Translate is not an Item, so it cannot resolve Tokens for the screen itself
    readonly property real slideDistance: Tokens.padding.large
    // 0 shows the device list, 1 the browser
    property real browserProgress: browserOpen ? 1 : 0

    function browse(deviceId: string): void {
        const rootPath = KdeConnect.storageRoot(deviceId);
        if (!rootPath || pendingBrowseDevice)
            return;

        // The browser reads the storage on the UI thread, which would hang on a dead mount
        pendingBrowseDevice = deviceId;
        KdeConnect.checkMount(deviceId, rootPath);
    }

    function openBrowser(deviceId: string, rootPath: string): void {
        const device = KdeConnect.devices.find(d => d.id === deviceId);
        if (!device)
            return;

        browserDeviceId = deviceId;
        browserDeviceName = device.name;
        browserRootPath = rootPath;
        browserOpen = true;
        browser.reset();
    }

    implicitHeight: compactHeight
    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer
    clip: true

    // Utilities just opened, so find mounts which died while it was closed and
    // phones plugged in over USB since
    Component.onCompleted: {
        for (const device of KdeConnect.devices)
            if (KdeConnect.isMounted(device.id))
                KdeConnect.checkMount(device.id, KdeConnect.storageRoot(device.id));

        Scrcpy.refresh();
        Scrcpy.watch();
    }
    Component.onDestruction: Scrcpy.unwatch()

    onBrowserDeviceMountedChanged: {
        if (!browserDeviceMounted)
            browserOpen = false;
    }

    // Only animate opening and closing the browser. A Behavior would also animate
    // the height settling when the card is created, making its contents jump.
    states: State {
        name: "browsing"
        when: root.browserOpen

        PropertyChanges {
            root.implicitHeight: root.browserHeight
        }
    }

    transitions: Transition {
        Anim {
            property: "implicitHeight"
        }
    }

    // Close the browser as soon as utilities starts hiding or another panel takes
    // over. The panel keeps its last height until the card is recreated, so a card
    // destroyed with the browser open would reopen at the browser height.
    Connections {
        function onUtilitiesChanged(): void {
            if (!root.screenState.utilities)
                root.browserOpen = false;
        }

        function onSidebarChanged(): void {
            if (root.screenState.sidebar)
                root.browserOpen = false;
        }

        function onLauncherChanged(): void {
            if (root.screenState.launcher)
                root.browserOpen = false;
        }

        function onSessionChanged(): void {
            if (root.screenState.session)
                root.browserOpen = false;
        }

        function onDashboardChanged(): void {
            if (root.screenState.dashboard)
                root.browserOpen = false;
        }

        target: root.screenState
    }

    // The panel's window normally takes no keyboard input, so allow it while a
    // pairing code can be typed, like the Wi-Fi password popout does
    Binding {
        when: Scrcpy.pairing !== null

        target: root.QsWindow.window
        property: "WlrLayershell.keyboardFocus"
        value: WlrKeyboardFocus.OnDemand
    }

    // USB connections are not announced, so look for them while the card is shown
    Timer {
        running: Scrcpy.available
        repeat: true
        interval: 5000
        onTriggered: Scrcpy.refresh()
    }

    Connections {
        function onMountChecked(device: string, path: string, reachable: bool): void {
            if (device !== root.pendingBrowseDevice)
                return;

            root.pendingBrowseDevice = "";
            if (reachable && KdeConnect.isMounted(device) && path === KdeConnect.storageRoot(device))
                root.openBrowser(device, path);
        }

        target: KdeConnect
    }

    ColumnLayout {
        id: layout

        // Slides with the margins, as qmllint reads a Translate on a layout as
        // positioning an item managed by a layout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Tokens.padding.large
        anchors.leftMargin: Tokens.padding.large - root.slideDistance * root.browserProgress
        anchors.rightMargin: Tokens.padding.large + root.slideDistance * root.browserProgress
        spacing: Tokens.spacing.small

        enabled: !root.browserOpen
        opacity: root.browserOpen ? 0 : 1

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: icon.implicitHeight + Tokens.padding.large

                radius: Tokens.rounding.full
                color: Colours.palette.m3secondaryContainer

                MaterialIcon {
                    id: icon

                    anchors.centerIn: parent
                    text: "send_to_mobile"
                    color: Colours.palette.m3onSecondaryContainer
                    fontStyle: Tokens.font.icon.large
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Send to phone")
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        if (!KdeConnect.available)
                            return Tr.tr("KDE Connect is not running");
                        if (KdeConnect.devices.length === 0)
                            return KdeConnect.unpairedDevices.length > 0 ? Tr.tr("Pair a device to share files") : Tr.tr("No phone connected");
                        if (KdeConnect.downloading)
                            // TRANSLATORS: %1 = download progress percentage
                            return Tr.tr("Downloading… %1%").arg(Math.round(KdeConnect.downloadProgress * 100));
                        return Tr.tr("Drop files on a device");
                    }
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }

            // Same enter/exit as the keep awake card's active chip
            Loader {
                asynchronous: true
                visible: active
                opacity: KdeConnect.downloading ? 1 : 0
                scale: KdeConnect.downloading ? 1 : 0.5

                Component.onCompleted: active = Qt.binding(() => opacity > 0)

                sourceComponent: LoadingIndicator {
                    implicitSize: Math.round(Tokens.font.icon.medium.pointSize * 1.3)
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.StandardSmall
                    }
                }

                Behavior on scale {
                    Anim {}
                }
            }
        }

        Repeater {
            // Keyed by id, so rows survive updates such as battery changes
            model: ScriptModel {
                values: KdeConnect.devices.map(d => d.id)
            }

            StyledRect {
                id: device

                required property string modelData

                readonly property string deviceId: modelData
                readonly property var info: KdeConnect.devices.find(d => d.id === deviceId) ?? ({})
                readonly property int batteryCharge: info.batteryCharge ?? -1
                readonly property bool batteryCharging: info.batteryCharging ?? false
                readonly property bool mounted: KdeConnect.isMounted(deviceId)
                readonly property bool mountBusy: KdeConnect.isMountBusy(deviceId)
                readonly property bool downloadingHere: KdeConnect.downloading && KdeConnect.downloadDevice === deviceId
                readonly property bool mirroring: Scrcpy.isRunning(deviceId)
                readonly property bool mirrorBusy: Scrcpy.isBusy(deviceId)
                readonly property var pairing: Scrcpy.pairing?.deviceId === deviceId ? Scrcpy.pairing : null
                // Briefly shows the outcome of the last share: "", "sent" or "failed"
                property string shareResult
                // Shown under the row for a few seconds after mirroring fails
                property string mirrorError
                // Whether to start mirroring once pairing finishes
                property bool pendingStart

                function cancelPairing(): void {
                    pendingStart = false;
                    Scrcpy.cancelPairing();
                }

                function startMirroring(): void {
                    mirrorError = "";
                    pendingStart = true;
                    Scrcpy.start(deviceId);
                }

                Layout.fillWidth: true
                implicitHeight: deviceColumn.implicitHeight + Tokens.padding.small * 2

                radius: Tokens.rounding.medium
                color: dropArea.containsDrag ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                Behavior on color {
                    CAnim {}
                }

                Connections {
                    function onShared(deviceId: string): void {
                        if (deviceId === device.deviceId) {
                            device.shareResult = "sent";
                            shareResultTimer.restart();
                        }
                    }

                    function onShareFailed(deviceId: string): void {
                        if (deviceId === device.deviceId) {
                            device.shareResult = "failed";
                            shareResultTimer.restart();
                        }
                    }

                    target: KdeConnect
                }

                Connections {
                    function onFailed(deviceId: string, error: string): void {
                        if (deviceId !== device.deviceId || Scrcpy.pairing?.deviceId === deviceId)
                            return;

                        device.pendingStart = false;
                        device.mirrorError = error;
                        mirrorErrorTimer.restart();
                    }

                    function onPairingRequired(deviceId: string): void {
                        if (deviceId !== device.deviceId)
                            return;

                        Scrcpy.startPairing(deviceId);
                    }

                    function onPairingChanged(): void {
                        // Pairing finished and connected, so start what was asked for
                        if (!Scrcpy.pairing && device.pendingStart && Scrcpy.hasLink(device.deviceId) && !Scrcpy.isRunning(device.deviceId))
                            device.startMirroring();
                    }

                    function onSessionsChanged(): void {
                        if (Scrcpy.isRunning(device.deviceId))
                            device.pendingStart = false;
                    }

                    target: Scrcpy
                }

                Timer {
                    id: shareResultTimer

                    interval: 2000
                    onTriggered: device.shareResult = ""
                }

                Timer {
                    id: mirrorErrorTimer

                    interval: 5000
                    onTriggered: device.mirrorError = ""
                }

                ColumnLayout {
                    id: deviceColumn

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: Tokens.padding.small
                    anchors.leftMargin: Tokens.padding.medium
                    anchors.rightMargin: Tokens.padding.small
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: {
                                if (dropArea.containsDrag)
                                    return "file_download";
                                if (device.shareResult === "sent")
                                    return "check";
                                if (device.shareResult === "failed")
                                    return "error";
                                return "smartphone";
                            }
                            color: {
                                if (dropArea.containsDrag)
                                    return Colours.palette.m3onPrimaryContainer;
                                if (device.shareResult === "failed")
                                    return Colours.palette.m3error;
                                return Colours.palette.m3onSurfaceVariant;
                            }
                            fontStyle: Tokens.font.icon.medium
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: device.info.name ?? ""
                            color: dropArea.containsDrag ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            visible: device.batteryCharge >= 0
                            spacing: 0

                            MaterialIcon {
                                text: Icons.getBatteryIcon(device.batteryCharge / 100, device.batteryCharging)
                                color: {
                                    if (dropArea.containsDrag)
                                        return Colours.palette.m3onPrimaryContainer;
                                    if (device.batteryCharge < 20 && !device.batteryCharging)
                                        return Colours.palette.m3error;
                                    return Colours.palette.m3onSurfaceVariant;
                                }
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                // TRANSLATORS: %1 = battery charge percentage of the phone
                                text: Tr.tr("%1%").arg(device.batteryCharge)
                                color: dropArea.containsDrag ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.small
                            }
                        }

                        IconButton {
                            visible: device.mounted
                            type: IconButton.Text
                            icon: root.pendingBrowseDevice === device.deviceId ? "hourglass_top" : "folder_open"
                            disabled: device.mountBusy || root.pendingBrowseDevice !== ""
                            onClicked: root.browse(device.deviceId)
                        }

                        IconButton {
                            visible: Scrcpy.available
                            type: IconButton.Text
                            icon: {
                                if (device.mirrorBusy || device.pairing)
                                    return "hourglass_top";
                                return device.mirroring ? "stop_screen_share" : "screen_share";
                            }
                            disabled: device.mirrorBusy || device.pairing !== null
                            onClicked: {
                                if (device.mirroring)
                                    Scrcpy.stop(device.deviceId);
                                else
                                    device.startMirroring();
                            }
                        }

                        IconButton {
                            id: moreButton

                            type: IconButton.Text
                            icon: "more_vert"
                            onClicked: actionsMenu.expanded = !actionsMenu.expanded
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: {
                            if (device.mirrorError)
                                return device.mirrorError;
                            if (device.mirroring)
                                return Tr.tr("Mirroring the screen");
                            if (Scrcpy.unauthorizedUsb && device.pendingStart)
                                return Tr.tr("Allow USB debugging on the phone");
                            return "";
                        }
                        color: device.mirrorError ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        wrapMode: Text.WordWrap
                    }

                    // Pairing for wireless debugging, shown until the phone connects
                    ColumnLayout {
                        id: pairingView

                        // A code can only be typed once the phone's pairing screen is open
                        readonly property bool codeEntry: device.pairing !== null && (device.pairing.status === "waiting" || device.pairing.status === "failed") && Scrcpy.pairingService !== null

                        Layout.fillWidth: true
                        visible: device.pairing !== null
                        spacing: Tokens.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledText {
                                Layout.fillWidth: true
                                text: {
                                    switch (device.pairing?.status) {
                                    case "pairing":
                                        return Tr.tr("Pairing…");
                                    case "connecting":
                                        return Tr.tr("Paired, connecting…");
                                    case "failed":
                                        return device.pairing.error;
                                    default:
                                        return Scrcpy.pairingService ? Tr.tr("Enter the code shown on the phone") : Tr.tr("On the phone, open Wireless debugging and pick Pair device with pairing code");
                                    }
                                }
                                color: device.pairing?.status === "failed" ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.small
                                wrapMode: Text.WordWrap
                            }

                            // Next to the text while there is nothing to type yet
                            TextButton {
                                visible: !pairingView.codeEntry
                                type: TextButton.Text
                                text: Tr.trCtx("Cancel", "button")
                                onClicked: device.cancelPairing()
                            }
                        }

                        StyledTextField {
                            id: codeField

                            readonly property bool canSubmit: Scrcpy.pairingService !== null && text.length === 6

                            Layout.fillWidth: true
                            visible: pairingView.codeEntry
                            verticalPadding: Tokens.padding.medium
                            placeholderText: Tr.tr("Pairing code")
                            leadingIcon: "password"
                            maximumLength: 6
                            validate: /^\d{0,6}$/
                            inputMethodHints: Qt.ImhDigitsOnly

                            onVisibleChanged: {
                                if (visible) {
                                    text = "";
                                    forceActiveFocus();
                                }
                            }
                            onAccepted: {
                                if (canSubmit)
                                    Scrcpy.submitPairingCode(text);
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            visible: pairingView.codeEntry
                            spacing: Tokens.spacing.small

                            TextButton {
                                type: TextButton.Text
                                text: Tr.trCtx("Cancel", "button")
                                onClicked: device.cancelPairing()
                            }

                            TextButton {
                                type: TextButton.Tonal
                                text: Tr.tr("Pair")
                                disabled: !codeField.canSubmit
                                onClicked: Scrcpy.submitPairingCode(codeField.text)
                            }
                        }
                    }
                }

                Menu {
                    id: actionsMenu

                    // The panel sits at the bottom of the screen, so open upwards
                    attachTo: moreButton
                    attachSideY: Menu.Top
                    thisSideY: Menu.Bottom
                    marginY: -Tokens.spacing.small
                    active: null
                    items: [mountItem, unpairItem]

                    // Actions, not a choice, so never keep one highlighted
                    onExpandedChanged: {
                        if (!expanded)
                            active = null;
                    }
                }

                MenuItem {
                    id: mountItem

                    text: device.mounted ? Tr.tr("Unmount storage") : Tr.tr("Mount storage")
                    icon: device.mounted ? "eject" : "hard_drive"

                    onClicked: {
                        if (device.mountBusy || device.downloadingHere)
                            return;
                        if (device.mounted)
                            KdeConnect.unmount(device.deviceId);
                        else
                            KdeConnect.mount(device.deviceId);
                    }
                }

                MenuItem {
                    id: unpairItem

                    text: Tr.tr("Unpair")
                    icon: "link_off"

                    onClicked: {
                        if (!device.mountBusy)
                            KdeConnect.unpair(device.deviceId);
                    }
                }

                Connections {
                    function onUtilitiesChanged(): void {
                        // The menu lives in the window, so close it along with the panel
                        if (!root.screenState.utilities)
                            actionsMenu.expanded = false;
                    }

                    target: root.screenState
                }

                DropArea {
                    id: dropArea

                    anchors.fill: parent
                    keys: ["text/uri-list"]

                    onDropped: drop => {
                        if (!drop.hasUrls)
                            return;

                        KdeConnect.share(device.deviceId, drop.urls);
                        drop.acceptProposedAction();
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            Layout.leftMargin: Tokens.padding.small
            visible: KdeConnect.unpairedDevices.length > 0
            text: Tr.tr("Available devices")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
        }

        Repeater {
            // Keyed by id, so a pairing error survives the pair state change that follows it
            model: ScriptModel {
                values: KdeConnect.unpairedDevices.map(d => d.id)
            }

            StyledRect {
                id: unpaired

                required property string modelData

                readonly property string deviceId: modelData
                readonly property var info: KdeConnect.unpairedDevices.find(d => d.id === deviceId) ?? ({})
                readonly property int pairState: info.pairState ?? KdeConnect.pairNotPaired
                // Shown in place of the status for a few seconds after a failure
                property string pairError

                Layout.fillWidth: true
                implicitHeight: unpairedLayout.implicitHeight + Tokens.padding.small * 2

                radius: Tokens.rounding.medium
                color: Colours.tPalette.m3surfaceContainerHigh

                Connections {
                    function onPairingFailed(deviceId: string, error: string): void {
                        if (deviceId === unpaired.deviceId) {
                            unpaired.pairError = error;
                            pairErrorTimer.restart();
                        }
                    }

                    target: KdeConnect
                }

                Timer {
                    id: pairErrorTimer

                    interval: 4000
                    onTriggered: unpaired.pairError = ""
                }

                RowLayout {
                    id: unpairedLayout

                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.medium
                    anchors.rightMargin: Tokens.padding.small
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: unpaired.pairError ? "error" : "phonelink"
                        color: unpaired.pairError ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: unpaired.info.name ?? ""
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: {
                                if (unpaired.pairError)
                                    return unpaired.pairError;
                                if (unpaired.pairState === KdeConnect.pairRequested)
                                    return Tr.tr("Waiting for the device to accept");
                                if (unpaired.pairState === KdeConnect.pairRequestedByPeer)
                                    // TRANSLATORS: %1 = the key both devices show, which should match
                                    return Tr.tr("Key: %1").arg(unpaired.info.verificationKey ?? "");
                                return "";
                            }
                            color: unpaired.pairError ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }
                    }

                    TextButton {
                        visible: unpaired.pairState === KdeConnect.pairNotPaired
                        type: TextButton.Tonal
                        text: Tr.tr("Pair")
                        onClicked: KdeConnect.requestPairing(unpaired.deviceId)
                    }

                    TextButton {
                        visible: unpaired.pairState === KdeConnect.pairRequested
                        type: TextButton.Text
                        text: Tr.trCtx("Cancel", "button")
                        onClicked: KdeConnect.cancelPairing(unpaired.deviceId)
                    }

                    TextButton {
                        visible: unpaired.pairState === KdeConnect.pairRequestedByPeer
                        type: TextButton.Text
                        text: Tr.tr("Reject")
                        onClicked: KdeConnect.cancelPairing(unpaired.deviceId)
                    }

                    TextButton {
                        visible: unpaired.pairState === KdeConnect.pairRequestedByPeer
                        type: TextButton.Tonal
                        text: Tr.tr("Accept")
                        onClicked: KdeConnect.acceptPairing(unpaired.deviceId)
                    }
                }
            }
        }

        Behavior on opacity {
            Anim {}
        }
    }

    Utilities.PhoneBrowser {
        id: browser

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium

        deviceId: root.browserDeviceId
        deviceName: root.browserDeviceName
        rootPath: root.browserRootPath
        open: root.browserOpen
        enabled: root.browserOpen
        opacity: root.browserOpen ? 1 : 0

        onCloseRequested: root.browserOpen = false

        transform: Translate {
            x: root.slideDistance * (1 - root.browserProgress)
        }

        Behavior on opacity {
            Anim {}
        }
    }

    Behavior on browserProgress {
        Anim {}
    }
}
