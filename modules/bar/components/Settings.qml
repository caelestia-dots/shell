import qs.components
import qs.modules.controlcenter
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
            WindowFactory.create(null, {
                active: "network"
            });
        }
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -1

        text: "settings"
        color: Colours.palette.m3onSurface
        font.bold: true
        font.pointSize: Appearance.font.size.normal
    }
}



