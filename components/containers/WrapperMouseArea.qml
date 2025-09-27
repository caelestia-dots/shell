pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    Layout.fillWidth: true

    property alias cursorShape: mouseArea.cursorShape

    signal clicked()

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        onClicked: root.clicked()
    }

    default property alias data: contentItem.data

    Item {
        id: contentItem

        anchors.fill: parent
    }
}
