pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.launcher.services
import "Model.js" as Model

// Wi-Fi QR share card overlay.
// Adapted from Omarchy's wifiqr panel (MIT License) and themed to Caelestia.
Scope {
    id: root

    property bool opened: false
    property string iface: ""
    property string ssid: ""
    property bool secured: false
    property real pop: 0

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
    readonly property string binPath: `${MenuService.userBinDir}:${MenuService.bundledBinDir}`
    readonly property color onCard: Colours.palette.m3onSurface
    readonly property color onCardDim: Colours.palette.m3onSurfaceVariant
    readonly property color onCardUrgent: Colours.palette.m3error

    signal closeRequested
    signal runAgainRequested

    function open(): void {
        root.ssid = "";
        generate("");
        root.opened = true;
        Qt.callLater(() => {
            if (root.opened)
                keyCatcher.forceActiveFocus();
        });
    }

    function close(): void {
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

    function generate(requestedIface: string): void {
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
        const pathExport = `export PATH="${root.binPath}:$PATH"`;
        qrProc.command = requestedIface !== "" ? ["bash", "-c", `${pathExport}; exec menu-network-qr --meta "$1"`, "menu-network-qr", requestedIface] : ["bash", "-c", `${pathExport}; exec menu-network-qr --meta`];
        qrProc.running = true;
    }

    function updateQr(raw: string): void {
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

    function togglePassword(): void {
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
        const pathExport = `export PATH="${root.binPath}:$PATH"`;
        pwProc.command = ["bash", "-c", `${pathExport}; exec menu-network-password "$1"`, "menu-network-password", iface];
        pwProc.running = true;
    }

    onOpenedChanged: {
        if (opened) {
            pop = 0;
            Qt.callLater(() => {
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
            onStreamFinished: {
                if (!root.expectedStop)
                    root.updateQr(text);
            }
        }

        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (!root.expectedStop)
                    root.error = String(text || "").trim();
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.loading = false;
            if (root.pendingShow) {
                root.pendingShow = false;
                Qt.callLater(() => root.generate(root.pendingIface));
                return;
            }
            if (root.expectedStop)
                return;
            if (exitCode !== 0 || root.qrSize === 0) {
                root.qrSize = 0;
                root.qrRows = [];
                if (root.error === "")
                    root.error = Tr.tr("Could not generate the Wi-Fi QR code");
            }
        }
    }

    Process {
        id: pwProc

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (root.opened && !root.pwExpectedStop)
                    root.password = String(text || "").trim();
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (root.pwExpectedStop || !root.opened)
                return;
            if (exitCode === 0 && root.password !== "")
                root.passwordVisible = true;
            else
                root.passwordError = Tr.tr("Could not read the Wi-Fi password");
        }
    }

    // qmllint disable uncreatable-type
    PanelWindow {
        // qmllint enable uncreatable-type
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

            StyledRect {
                id: card

                radius: Tokens.rounding.extraLarge
                color: Colours.tPalette.m3surfaceContainer
                border.color: Colours.palette.m3outlineVariant
                border.width: 1

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: (root.stackCenter - 0.5) * parent.height

                opacity: root.pop
                scale: root.pop * Math.min(1, (keyCatcher.width - 32) / Math.max(1, card.width), (keyCatcher.height - 32) / Math.max(1, card.height))

                width: content.implicitWidth + 48
                height: content.implicitHeight + 40

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.OutBack
                    }
                }

                Behavior on anchors.verticalCenterOffset {
                    Anim {}
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                ColumnLayout {
                    id: content

                    spacing: Tokens.spacing.large

                    anchors {
                        fill: parent
                        topMargin: 20
                        bottomMargin: 20
                        leftMargin: 24
                        rightMargin: 24
                    }

                    StyledText {
                        text: (root.ssid || Tr.tr("Wi-Fi")).toUpperCase()
                        color: root.onCardDim
                        font: Tokens.font.mono.builders.small.weight(Font.Bold).letterSpacing(2).build()
                        elide: Text.ElideRight
                        Layout.maximumWidth: 320
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        id: qrCanvas

                        readonly property int moduleSize: root.qrSize > 0 ? Math.max(4, Math.floor(240 / root.qrSize)) : 0

                        visible: root.showingQr
                        Layout.preferredWidth: root.qrSize * moduleSize
                        Layout.preferredHeight: root.qrSize * moduleSize
                        color: "white"
                        radius: Tokens.rounding.medium
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

                    StyledText {
                        visible: root.loading
                        text: Tr.tr("Generating QR code…")
                        color: root.onCardDim
                        font: Tokens.font.body.small
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    StyledText {
                        visible: root.error !== ""
                        text: root.error
                        color: root.onCardUrgent
                        font: Tokens.font.body.small
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        Layout.maximumWidth: 320
                        horizontalAlignment: Text.AlignHCenter
                    }

                    StyledText {
                        visible: root.showingQr
                        text: Tr.tr("Scan to join this network")
                        color: root.onCardDim
                        font: Tokens.font.body.small
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    StyledText {
                        visible: root.showingQr && root.secured
                        text: root.passwordError !== "" ? root.passwordError : root.passwordVisible ? root.password : Tr.tr("Click to show password")
                        color: root.passwordError !== "" ? root.onCardUrgent : root.onCard
                        opacity: root.passwordVisible || root.passwordError !== "" ? 1 : 0.65
                        font: Tokens.font.mono.medium
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
}
