pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes
import Caelestia
import Caelestia.Config
import Caelestia.Multimedia
import Caelestia.Scheme
import qs.components
import qs.components.effects
import qs.utils

Item {
    id: root

    required property int centerWidth
    readonly property color bgColour: Colours.tPalette.surfaceContainerHighest

    implicitWidth: Math.round(centerWidth * 0.7)
    implicitHeight: {
        CUtils.dependency(shape.height); // Force update when shape height changes
        return shape.pathBounds().height;
    }

    MaterialShape {
        id: shape

        anchors.centerIn: parent
        implicitSize: root.implicitWidth

        shape: MaterialShape.ClamShell
        color: Qt.alpha(root.bgColour, 1)
        opacity: root.bgColour.a
        layer.enabled: true
    }

    MaterialIcon {
        anchors.centerIn: parent

        text: "person"
        color: Colours.palette.onSurfaceVariant
        fontStyle: Tokens.font.icon.size(root.centerWidth / 4).build()
        visible: !pfp.ready
    }

    Visual {
        id: pfp

        anchors.fill: shape
        source: `${Paths.home}/.face`

        layer.enabled: true
        layer.effect: Mask {
            maskSource: shape
        }
    }
}
