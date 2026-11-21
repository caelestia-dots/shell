import QtQuick
import Quickshell
import Quickshell.Bluetooth

QtObject {
    property ShellScreen screen
    property bool isWindow
    property bool animatingContainer
    property int currentPageIdx
    property list<int> subPageIdxStack
    property list<int> pendingSubPath
    property bool searchOpen
    property string searchText
    property string searchAnchor
    property string lastAnchor

    property string selectedWallpaperCategory
    property BluetoothDevice selectedBtDevice
    property DesktopEntry selectedApp
    property int editingVpnIndex: -1
    property string selectedNetworkSsid
    property string selectedEthernetInterface
    property bool networkDetailsFromSaved

    signal close
    signal subPageOpened(idx: int)
    signal subPageClosed
    signal highlightSetting(anchor: string)

    function openSubPage(idx: int): void {
        subPageIdxStack.push(idx);
        subPageOpened(idx);
    }

    function closeSubPage(): void {
        subPageClosed();
        subPageIdxStack.pop();
    }

    function jumpToSetting(pageIdx: int, subPath: var, anchor: string): void {
        const samePage = currentPageIdx === pageIdx;
        const sameSub = subPageIdxStack.length === subPath.length && subPath.every((v, i) => subPageIdxStack[i] === v);
        if (samePage && sameSub && anchor === lastAnchor) {
            highlightSetting(anchor);
            return;
        }
        lastAnchor = anchor;
        if (samePage && sameSub) {
            searchAnchor = "";
            searchAnchor = anchor;
            return;
        }
        searchAnchor = anchor;
        if (!samePage) {
            pendingSubPath = subPath.slice();
            currentPageIdx = pageIdx;
        } else {
            let shared = 0;
            while (shared < subPath.length && shared < subPageIdxStack.length && subPageIdxStack[shared] === subPath[shared])
                shared++;
            while (subPageIdxStack.length > shared)
                closeSubPage();
            for (let i = shared; i < subPath.length; i++)
                openSubPage(subPath[i]);
        }
    }

    // Set before the new page is created, so its StackPage opens the whole chain at once
    onCurrentPageIdxChanged: {
        subPageIdxStack = pendingSubPath;
        pendingSubPath = [];
    }
}
