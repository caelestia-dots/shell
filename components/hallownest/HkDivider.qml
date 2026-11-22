import QtQuick
import qs.services

Item {
    id: root

    property color colour: Hallownest.steel
    property bool filled: true
    property real lineRatio: 0.42

    implicitWidth: 200
    implicitHeight: 10

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: diamond.left
        anchors.rightMargin: 6
        width: Math.max(0, parent.width * root.lineRatio - 6)
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: 1
                color: Qt.alpha(root.colour, 0.5)
            }
        }
    }

    Rectangle {
        id: diamond

        anchors.centerIn: parent
        width: 6
        height: 6
        rotation: 45
        color: root.filled ? Qt.alpha(root.colour, 0.75) : "transparent"
        border.width: 1
        border.color: Qt.alpha(root.colour, 0.8)
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: diamond.right
        anchors.leftMargin: 6
        width: Math.max(0, parent.width * root.lineRatio - 6)
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: Qt.alpha(root.colour, 0.5)
            }
            GradientStop {
                position: 1
                color: "transparent"
            }
        }
    }
}
