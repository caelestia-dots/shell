pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    required property int centerWidth
    readonly property color bgColour: Colours.tPalette.m3surfaceContainerHighest

    function resolveShape(name: string): int {
        if (typeof MaterialShape[name] === "number" && MaterialShape[name] >= 0)
            return MaterialShape[name];

        console.warn(lc, `Unknown shape "${name}" for pfpShape; falling back to "ClamShell"`);
        return MaterialShape.ClamShell;
    }

    implicitWidth: Math.round(centerWidth * 0.7)
    implicitHeight: {
        // Force update when the shape or its height changes
        shape.height;
        shape.shape;
        shape.morphProgress;
        return shape.pathBounds().height;
    }

    MaterialShape {
        id: shape

        anchors.centerIn: parent
        implicitSize: root.implicitWidth

        shape: root.resolveShape(Config.lock.pfpShape)
        color: Qt.alpha(root.bgColour, 1)
        opacity: root.bgColour.a
        layer.enabled: true
    }

    MaterialIcon {
        anchors.centerIn: parent

        text: "person"
        color: Colours.palette.m3onSurfaceVariant
        fontStyle: Tokens.font.icon.size(root.centerWidth / 4).build()
        visible: pfp.status !== Image.Ready
    }

    CachingImage {
        id: pfp

        anchors.fill: shape
        path: `${Paths.home}/.face`

        layer.enabled: true
        layer.effect: Mask {
            maskSource: shape
        }
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.lock"
        defaultLogLevel: LoggingCategory.Info
    }
}
