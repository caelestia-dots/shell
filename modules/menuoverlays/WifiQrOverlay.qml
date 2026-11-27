pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.launcher.services
import "Model.js" as Model

// Ported from omarchy's wifiqr_Panel.qml: the Wi-Fi QR code floats on its own
// dark translucent card. Two surfaces keep the blur scoped to the card only:
// a fullscreen catcher takes the keyboard and outside clicks (never blurred),
// while the card itself is its own layer surface, so the blur rule can only
// ever apply behind it. Each summon regenerates the code via
// menu-network-qr --meta.
Item {
    id: root

    property bool opened: false
    property string iface: ""
    property string ssid: ""
    property bool secured: false

    // Card entrance: 0 -> 1 on open, so each card fades and pops into its
    // slot rather than sliding in from off-screen.
    property real pop: 0

    // Stacking: how many overlays are open in total and this card's vertical
    // rank (0 = top). The coordinator in MenuOverlays supplies these, and also
    // a ready-made vertical-center fraction that keeps the cards apart.
    property int stackCount: 1
    property int stackRank: 0
    property real stackCenter: 0.5

    property var qrRows: []
    property int qrSize: 0
    property string error: ""
    property bool loading: false
    property bool expectedStop: false
    property bool pendingShow: false
    property string pendingIface: ""
    property string password: ""
    property bool passwordVisible: false
    property string passwordError: ""
    property bool pwExpectedStop: false

    readonly property bool showingQr: qrSize > 0 && !loading && error === ""
    readonly property color onScrim: "white"
    readonly property color onScrimDim: Qt.rgba(1, 1, 1, 0.55)
    readonly property color onScrimUrgent: "#ff6b6b"
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string binPath: `${MenuService.userBinDir}:${MenuService.bundledBinDir}`

    // Emitted when the user dismisses this overlay; the coordinator in
    // MenuOverlays closes every open overlay so one Esc exits them all.
    signal closeRequested

    // Emitted on Enter so the coordinator can restart any open speed test,
    // even when this card (with the keyboard focus) is on top.
    signal runAgainRequested

    function open() {
        root.ssid = "";
        generate("");
        root.opened = true;
        Qt.callLater(function () {
            if (root.opened)
                keyCatcher.forceActiveFocus();
        });
    }

    function close() {
        root.opened = false;
        root.pendingShow = false;
        if (qrProc.running) {
            root.expectedStop = true;
            qrProc.running = false;
        }
        if (pwProc.running)
            pwProc.running = false;
        root.qrSize = 0;
        root.qrRows = [];
        root.error = "";
        root.loading = false;
        root.iface = "";
        root.ssid = "";
        root.secured = false;
        root.password = "";
        root.passwordVisible = false;
        root.passwordError = "";
    }

    function generate(requestedIface) {
        if (qrProc.running) {
            pendingShow = true;
            pendingIface = requestedIface;
            if (!expectedStop) {
                expectedStop = true;
                qrProc.running = false;
            }
            return;
        }
        qrSize = 0;
        qrRows = [];
        error = "";
        loading = true;
        expectedStop = false;
        iface = "";
        secured = false;
        password = "";
        passwordVisible = false;
        passwordError = "";
        if (pwProc.running) {
            pwExpectedStop = true;
            pwProc.running = false;
        }
        qrProc.command = requestedIface !== "" ? ["bash", "-c", `export PATH="${binPath}:$PATH"; exec menu-network-qr --meta "$1"`, "menu-network-qr", requestedIface] : ["bash", "-c", `export PATH="${binPath}:$PATH"; exec menu-network-qr --meta`];
        qrProc.running = true;
    }

    function updateQr(raw) {
        const parsed = Model.parseQrOutput(raw);
        qrRows = parsed.matrix.rows;
        qrSize = parsed.matrix.size;
        if (parsed.meta.ssid !== "")
            ssid = parsed.meta.ssid;
        if (parsed.meta.iface !== "")
            iface = parsed.meta.iface;
        secured = parsed.meta.security !== "" && parsed.meta.security !== "nopass";
        if (qrSize > 0)
            error = "";
    }

    function togglePassword() {
        if (passwordVisible) {
            passwordVisible = false;
            return;
        }
        if (password !== "") {
            passwordVisible = true;
            return;
        }
        if (pwProc.running || !iface)
            return;
        passwordError = "";
        pwExpectedStop = false;
        pwProc.command = ["bash", "-c", `export PATH="${binPath}:$PATH"; exec menu-network-password "$1"`, "menu-network-password", iface];
        pwProc.running = true;
    }

    onOpenedChanged: {
        if (opened) {
            pop = 0;
            Qt.callLater(function () {
                if (!root.opened)
                    return;
                pop = 1;
            });
        }
    }

    Process {
        id: qrProc

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (!root.expectedStop)
                root.updateQr(text)
        }

        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (!root.expectedStop)
                root.error = String(text || "").trim()
        }

        onExited: (exitCode, exitStatus) => {
            root.loading = false;
            if (root.pendingShow) {
                root.pendingShow = false;
                Qt.callLater(function () {
                    root.generate(root.pendingIface);
                });
                return;
            }
            if (root.expectedStop)
                return;
            if (exitCode !== 0 || root.qrSize === 0) {
                root.qrSize = 0;
                root.qrRows = [];
                if (root.error === "")
                    root.error = "Could not generate the Wi-Fi QR code";
            }
        }
    }

    Process {
        id: pwProc

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (root.opened && !root.pwExpectedStop)
                root.password = String(text || "").trim()
        }

        onExited: (exitCode, exitStatus) => {
            if (root.pwExpectedStop)
                return;
            if (!root.opened)
                return;
            if (exitCode === 0 && root.password !== "")
                root.passwordVisible = true;
            else
                root.passwordError = "Could not read the Wi-Fi password";
        }
    }

    // qmllint disable uncreatable-type
    PanelWindow {
        // qmllint enable uncreatable-type
        id: catcher

        visible: root.opened
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "caelestia-menu-network-qr"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Item {
            id: keyCatcher

            anchors.fill: parent
            focus: true

            Keys.onEscapePressed: root.closeRequested()
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Q)
                    root.closeRequested();
            }
            Keys.onReturnPressed: root.runAgainRequested()
            Keys.onEnterPressed: root.runAgainRequested()

            MouseArea {
                anchors.fill: parent
                onClicked: root.closeRequested()
            }
        }
    }

    // qmllint disable uncreatable-type
    PanelWindow {
        // qmllint enable uncreatable-type
        id: cardWindow

        visible: root.opened
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "caelestia-menu-network-qr-card"
        WlrLayershell.layer: WlrLayer.Overlay

        // Anchoring only the top and left edges keeps the surface at the
        // requested card size (anchoring opposite edges would stretch it to
        // fill the screen minus margins). The margins then place the card and
        // pack it toward the top/bottom of the center as other overlay cards
        // open or close.
        anchors {
            top: true
            left: true
        }

        implicitWidth: card.width
        implicitHeight: card.height

        margins.left: Math.max(0, Math.round((screen.width - card.width) / 2))
        margins.top: Math.max(0, Math.round((screen.height - card.height) / 2 + (root.stackCenter - 0.5) * screen.height))

        Behavior on margins.top {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: card

            radius: 20
            color: Qt.rgba(0.15, 0.15, 0.17, 0.6)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            opacity: root.pop
            scale: root.pop

            width: content.implicitWidth + 48
            height: content.implicitHeight + 40

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutBack
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                id: content

                spacing: 16

                anchors {
                    fill: parent
                    topMargin: 20
                    bottomMargin: 20
                    leftMargin: 24
                    rightMargin: 24
                }

                Text {
                    text: (root.ssid || "Wi-Fi").toUpperCase()
                    color: root.onScrimDim
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 2
                    elide: Text.ElideRight
                    Layout.maximumWidth: 320
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    id: qrCanvas

                    readonly property int moduleSize: root.qrSize > 0 ? Math.max(4, Math.floor(240 / root.qrSize)) : 0
                    readonly property int side: root.qrSize * moduleSize

                    visible: root.showingQr
                    implicitWidth: side
                    implicitHeight: side
                    Layout.preferredWidth: side
                    Layout.preferredHeight: side
                    color: "white"
                    radius: 12
                    Layout.alignment: Qt.AlignHCenter

                    Grid {
                        anchors.fill: parent
                        columns: root.qrSize

                        Repeater {
                            model: root.qrSize * root.qrSize

                            Rectangle {
                                required property int index

                                readonly property int matrixRow: Math.floor(index / root.qrSize)
                                readonly property int matrixColumn: index % root.qrSize

                                width: qrCanvas.moduleSize
                                height: qrCanvas.moduleSize
                                color: root.qrRows[matrixRow].charAt(matrixColumn) === "1" ? "#111111" : "transparent"
                            }
                        }
                    }
                }

                Text {
                    visible: root.loading
                    text: "Generating QR code…"
                    color: root.onScrimDim
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    visible: root.error !== ""
                    text: root.error
                    color: root.onScrimUrgent
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    Layout.maximumWidth: 320
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    visible: root.showingQr
                    text: "Scan to join this network"
                    color: root.onScrimDim
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    visible: root.showingQr && root.secured
                    text: root.passwordError !== "" ? root.passwordError : root.passwordVisible ? root.password : "Click to show password"
                    color: root.passwordError !== "" ? root.onScrimUrgent : root.onScrim
                    opacity: root.passwordVisible || root.passwordError !== "" ? 1 : 0.6
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    wrapMode: Text.WrapAnywhere
                    Layout.fillWidth: true
                    Layout.maximumWidth: 320
                    horizontalAlignment: Text.AlignHCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.togglePassword()
                    }
                }
            }
        }
    }
}
