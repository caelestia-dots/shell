import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.services

QtObject {
    id: state

    property ShellScreen screen
    property bool isWindow
    property bool animatingContainer
    property int currentPageIdx
    property list<int> subPageIdxStack
    property bool searchOpen

    property string selectedWallpaperCategory
    property BluetoothDevice selectedBtDevice
    property DesktopEntry selectedApp
    property string selectedEthernetInterface
    property var selectedMonitor
    property Connections monitorsConnection: Connections {
        function onMonitorsChanged(): void {
            if (state.selectedMonitor) {
                for (let i = 0; i < Hyprctl.monitors.length; i++) {
                    if (Hyprctl.monitors[i].name === state.selectedMonitor.name) {
                        state.selectedMonitor = Hyprctl.monitors[i];
                        return;
                    }
                }
                state.selectedMonitor = null;
            }
        }

        target: Hyprctl
    }

    signal close
    signal subPageOpened(idx: int)
    signal subPageClosed

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
