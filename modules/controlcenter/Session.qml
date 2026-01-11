import QtQuick
import "./state"
import qs.modules.controlcenter

QtObject {
    readonly property list<string> panes: PaneRegistry.labels

    required property var root
    property bool floating: false
    property string active: "network"
    property int activeIndex: 0
    property bool navExpanded: false

    readonly property BluetoothState bt: BluetoothState {}
    readonly property NetworkState network: NetworkState {}
    readonly property EthernetState ethernet: EthernetState {}
    readonly property LauncherState launcher: LauncherState {}

    onActiveChanged: activeIndex = panes.indexOf(active)
    onActiveIndexChanged: active = panes[activeIndex]
}
