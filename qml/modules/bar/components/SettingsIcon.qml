import QtQuick
import qs.components
import qs.services
import qs.config
import qs.modules.controlcenter

Item {
    id: root

    implicitWidth: icon.implicitHeight + Appearance.padding.small * 2
    implicitHeight: icon.implicitHeight

    StateLayer {
        // Cursed workaround to make the height larger than the parent
        function onClicked(): void {
            WindowFactory.create(null, {
                active: "network"
            });
        }

        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Appearance.padding.small * 2
        radius: Appearance.rounding.full
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
