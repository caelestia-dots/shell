import qs.components.effects
import qs.services
import qs.config
import qs.utils
import QtQuick

Item {
    id: root
    
    Component.onCompleted: Tour.register("bar-launcher", root)
    Component.onDestruction: Tour.unregister("bar-launcher")

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const visibilities = Visibilities.getForActive();
            visibilities.launcher = !visibilities.launcher;
        }
    }

    ColouredIcon {
        anchors.centerIn: parent
        source: SysInfo.osLogo
        implicitSize: Appearance.font.size.large * 1.2
        colour: Colours.palette.m3tertiary
    }

    implicitWidth: Appearance.font.size.large * 1.2
    implicitHeight: Appearance.font.size.large * 1.2
}
