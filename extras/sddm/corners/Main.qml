// qmllint disable unqualified
// qmllint disable unused-imports

import "./components"
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

Rectangle {
    id: root

    height: Screen.height
    width: Screen.width

    Image {
        anchors {
            fill: parent
        }

        source: config.BgSource
        fillMode: Image.PreserveAspectCrop
        clip: true
    }

    Item {
        anchors {
            fill: parent
            margins: config.Padding
        }

        LoginPanel {
            anchors {
                fill: parent
            }
        }
    }
}
