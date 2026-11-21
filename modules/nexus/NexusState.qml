import QtQuick
import Quickshell
import Quickshell.Bluetooth

QtObject {
    property ShellScreen screen
    property bool isWindow
    property bool animatingContainer
    property int currentPageIdx
    property list<int> subPageIdxStack
    property bool searchOpen

    property string selectedWallpaperCategory
    property BluetoothDevice selectedBtDevice
    property DesktopEntry selectedApp
    property int editingVpnIndex: -1
    property string selectedNetworkSsid
    property string selectedEthernetInterface
    property bool networkDetailsFromSaved
    // Network awaiting a password in the password sub-page (null = closed).
    property var passwordNetwork: null

    signal close
    signal subPageOpened(idx: int)
    signal subPageClosed

    // Opens the password sub-page for a network. Idempotent per SSID: the
    // connection machinery can report needsPassword multiple times (retries),
    // and each report must not stack another copy of the page.
    function openPasswordPage(network: var): void {
        if (!network || (passwordNetwork && passwordNetwork.ssid === network.ssid))
            return;
        passwordNetwork = network;
        openSubPage(7); // Network password sub-page
    }

    function openSubPage(idx: int): void {
        subPageIdxStack.push(idx);
        subPageOpened(idx);
    }

    function closeSubPage(): void {
        subPageClosed();
        subPageIdxStack.pop();
    }

    onCurrentPageIdxChanged: subPageIdxStack.length = 0
}
