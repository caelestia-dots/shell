import Quickshell.Bluetooth
import QtQuick

QtObject {
    readonly property list<string> panes: ["network", "bluetooth", "audio"]

    required property var root
    property bool floating: false
    property string active: panes[0]
    property int activeIndex: 0
    property bool navExpanded: false

    readonly property Bt bt: Bt {}

    onActiveChanged: activeIndex = panes.indexOf(active)
    onActiveIndexChanged: active = panes[activeIndex]

    component Bt: QtObject {
        property BluetoothDevice active
        property BluetoothAdapter currentAdapter: Bluetooth.defaultAdapter
        property bool editingAdapterName
        property bool fabMenuOpen
        property bool editingDeviceName
    }
}
