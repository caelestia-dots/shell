import Quickshell.Bluetooth
import QtQuick

QtObject {
    readonly property list<string> panes: ["network", "bluetooth"]

    property string active
    property int activeIndex

    readonly property Bt bt: Bt {}

    onActiveChanged: activeIndex = panes.indexOf(active)
    onActiveIndexChanged: active = panes[activeIndex]

    component Bt: QtObject {
        property BluetoothDevice active
        property BluetoothAdapter currentAdapter: Bluetooth.defaultAdapter
        property bool editingAdapterName
    }
}
