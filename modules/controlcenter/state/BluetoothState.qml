import Quickshell.Bluetooth
import QtQuick

QtObject {
    id: root

    property BluetoothDevice active: null
    property BluetoothAdapter currentAdapter: Bluetooth.defaultAdapter
    property bool editingAdapterName: false
    property bool fabMenuOpen: false
    property bool editingDeviceName: false
}

