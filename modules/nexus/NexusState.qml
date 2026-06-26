import QtQuick
import Quickshell
import Quickshell.Bluetooth

QtObject {
    property ShellScreen screen
    property bool isWindow
    property bool animatingContainer
    property int currentPageIdx
    property list<int> subPageIdxStack
    property list<int> _pendingSubPath
    property bool searchOpen
    property string searchText
    property string searchAnchor
    property string _lastAnchor

    property string selectedWallpaperCategory
    property BluetoothDevice selectedBtDevice
    property DesktopEntry selectedApp
    property string selectedEthernetInterface

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

    // Jump straight to a setting from search: open the page, then any sub-pages
    // along subPath, then let the page scroll to the anchor. subPageIdxStack is
    // filled directly so a freshly loaded StackPage opens the whole chain at
    // once (see StackPage.Component.onCompleted), which avoids the half-open
    // state that firing openSubPage signals one by one would cause.
    function jumpToSetting(pageIdx: int, subPath: var, anchor: string): void {
        const samePage = currentPageIdx === pageIdx;
        const sameSub = subPageIdxStack.length === subPath.length && subPath.every((v, i) => subPageIdxStack[i] === v);
        if (samePage && sameSub && anchor === _lastAnchor) {
            // Re-clicking the exact same setting: flash it again, don't scroll.
            highlightSetting(anchor);
            return;
        }
        _lastAnchor = anchor;
        if (samePage && sameSub) {
            // Same page, different setting: just scroll to it.
            searchAnchor = "";
            searchAnchor = anchor;
            return;
        }
        if (samePage) {
            // Same page, different sub-page: rebuild the sub-page chain first,
            // then set the anchor so the now-current page picks it up.
            while (subPageIdxStack.length > 0)
                closeSubPage();
            for (let i = 0; i < subPath.length; i++)
                openSubPage(subPath[i]);
            searchAnchor = "";
            searchAnchor = anchor;
        } else {
            searchAnchor = anchor;
            _pendingSubPath = subPath.slice();
            currentPageIdx = pageIdx;
        }
    }

    onCurrentPageIdxChanged: {
        subPageIdxStack = _pendingSubPath;
        _pendingSubPath = [];
    }
}
