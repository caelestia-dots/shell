import qs.components.effects
import qs.services
import qs.config
import qs.utils
import QtQuick
import "../../../components"

Item {
    id: root
    
    Component.onCompleted: Tour.register("bar-launcher", root)
    Component.onDestruction: Tour.unregister("bar-launcher")

    implicitWidth: Appearance.font.size.large * 1.2
    implicitHeight: Appearance.font.size.large * 1.2

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
            width: Appearance.font.size.large * 1.5
            height: Appearance.font.size.large * 1.5
            lightTheme: Colours.currentLight
            accentColor: Colours.palette.m3primary
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
