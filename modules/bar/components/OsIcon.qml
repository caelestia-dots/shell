import qs.components.effects
import qs.services
import qs.config
import qs.utils
import QtQuick
import qs.components

Item {
    id: root

    implicitWidth: Appearance.font.size.large * 1.2
    implicitHeight: Appearance.font.size.large * 1.2

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

    Loader {
        anchors.centerIn: parent
        sourceComponent: SysInfo.isDefaultLogo ? caelestiaLogo : distroIcon
    }

    Component {
        id: caelestiaLogo

        Logo {
            implicitWidth: Appearance.font.size.large * 1.8
            implicitHeight: Appearance.font.size.large * 1.8
        }
    }

    Component {
        id: distroIcon

        ColouredIcon {
            source: SysInfo.osLogo
            implicitSize: Appearance.font.size.large * 1.2
            colour: Colours.palette.m3tertiary
        }
    }
}
