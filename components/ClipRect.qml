import QtQuick
import Caelestia.Components

Item {
    id: root

    property real radius
    property color color: "transparent"
    default property alias contentData: contentItem.data

    Item {
        id: contentItem

        anchors.fill: parent
    }

    ShaderEffectSource {
        id: source

        hideSource: true
        sourceItem: contentItem
    }

    RoundedMask {
        anchors.fill: parent
        source: source
        radius: root.radius
        color: root.color
    }

    Behavior on color {
        CAnim {}
    }
}
