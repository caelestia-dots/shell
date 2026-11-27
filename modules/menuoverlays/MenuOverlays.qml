import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.services
import qs.modules.launcher.services

// Hosts the menu's standalone overlays (network/disk speed tests, Wi-Fi QR)
// and exposes IPC endpoints under the "menu" target.
Scope {
    id: root

    readonly property bool netOpen: networkSpeedTest.opened
    readonly property bool diskOpen: diskSpeedTest.opened
    readonly property bool qrOpen: wifiQrOverlay.opened
    readonly property int openTotal: (netOpen ? 1 : 0) + (diskOpen ? 1 : 0) + (qrOpen ? 1 : 0)
    readonly property int netRank: netOpen ? (qrOpen ? 1 : 0) + (diskOpen ? 1 : 0) : -1
    readonly property int diskRank: diskOpen ? (qrOpen ? 1 : 0) : -1
    readonly property int qrRank: qrOpen ? 0 : -1

    function closeAll(): void {
        networkSpeedTest.close();
        diskSpeedTest.close();
        wifiQrOverlay.close();
    }

    function runOpenSpeedTests(): void {
        if (root.netOpen)
            networkSpeedTest.runSpeedTest();
        if (root.diskOpen)
            diskSpeedTest.runTest();
    }

    function stackCenterFor(type: string): real {
        const n = root.netOpen;
        const d = root.diskOpen;
        const q = root.qrOpen;
        const total = (n ? 1 : 0) + (d ? 1 : 0) + (q ? 1 : 0);
        if (total <= 1)
            return 0.5;
        if (n && d && q)
            return type === "qr" ? 0.20 : type === "disk" ? 0.50 : 0.76;
        if (n && d && !q)
            return type === "net" ? 0.63 : 0.37;
        if ((n || d) && q)
            return type === "qr" ? 0.35 : 0.65;
        return 0.5;
    }

    NetworkSpeedTest {
        id: networkSpeedTest

        stackCount: root.openTotal
        stackRank: root.netRank
        stackCenter: root.stackCenterFor("net")
    }

    DiskSpeedTest {
        id: diskSpeedTest

        stackCount: root.openTotal
        stackRank: root.diskRank
        stackCenter: root.stackCenterFor("disk")
    }

    WifiQrOverlay {
        id: wifiQrOverlay

        stackCount: root.openTotal
        stackRank: root.qrRank
        stackCenter: root.stackCenterFor("qr")
    }

    Connections {
        function onCloseRequested(): void {
            root.closeAll();
        }

        function onRunAgainRequested(): void {
            root.runOpenSpeedTests();
        }

        target: networkSpeedTest.overlay
    }

    Connections {
        function onCloseRequested(): void {
            root.closeAll();
        }

        function onRunAgainRequested(): void {
            root.runOpenSpeedTests();
        }

        target: diskSpeedTest.overlay
    }

    Connections {
        function onCloseRequested(): void {
            root.closeAll();
        }

        function onRunAgainRequested(): void {
            root.runOpenSpeedTests();
        }

        target: wifiQrOverlay
    }

    Connections {
        function onOverlayRequested(name: string): void {
            if (name === "speedtest")
                networkSpeedTest.open();
            else if (name === "disktest")
                diskSpeedTest.open();
            else if (name === "wifiqr")
                wifiQrOverlay.open();
        }

        target: MenuService
    }

    IpcHandler {
        function open(route: string): string {
            if (!GlobalConfig.launcher.menu.enabled)
                return "disabled";
            MenuService.openRoute(route);
            MenuService.pendingOpen = true;
            const screenState = ShellState.forActive();
            if (screenState && !screenState.launcher)
                screenState.launcher = true;
            return "ok";
        }

        function toggle(): string {
            if (!GlobalConfig.launcher.menu.enabled)
                return "disabled";
            const screenState = ShellState.forActive();
            if (!screenState)
                return "error";
            if (screenState.launcher) {
                screenState.launcher = false;
            } else {
                MenuService.openRoute("");
                MenuService.pendingOpen = true;
                screenState.launcher = true;
            }
            return "ok";
        }

        function speedtest(): string {
            networkSpeedTest.open();
            return "ok";
        }

        function disktest(): string {
            diskSpeedTest.open();
            return "ok";
        }

        function wifiqr(): string {
            wifiQrOverlay.open();
            return "ok";
        }

        function refresh(): string {
            MenuService.evalConds(true);
            return "ok";
        }

        target: "menu"
    }
}
