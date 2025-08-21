import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    implicitWidth: icon.implicitHeight + Appearance.padding.small * 2
    implicitHeight: icon.implicitHeight

    StateLayer {
        // Cursed workaround to make the height larger than the parent
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Appearance.padding.small * 2

        radius: Appearance.rounding.full

        function onClicked(): void {
            IdleInhibitor.enabled = !IdleInhibitor.enabled; 
        }
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -1

        text: IdleInhibitor.enabled ? "visibility" : "visibility_off"
        color: Colours.palette.m3error
        font.bold: true
        font.pointSize: Appearance.font.size.normal
    }
}
