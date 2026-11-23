import QtQuick
import Caelestia.Components

Item {
    id: root

    property real radius
    property real topLeftRadius: radius
    property real topRightRadius: radius
    property real bottomRightRadius: radius
    property real bottomLeftRadius: radius
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
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomRightRadius: root.bottomRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        color: root.color
    }

    Behavior on color {
        CAnim {}
    }
}
