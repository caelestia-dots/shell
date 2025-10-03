pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Handlers

Item {
    id: root

    // allow using Layout attached props at call sites
    Layout.fillWidth: true

    // expose a cursor shape like MouseArea
    property alias cursorShape: hover.cursorShape

    signal clicked()

    // Use pointer handlers so child controls remain interactive
    HoverHandler { id: hover; cursorShape: Qt.ArrowCursor }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.clicked()
    }

    // forward arbitrary children into this content item
    default property alias data: contentItem.data

    Item {
        id: contentItem
        anchors.fill: parent
    }
}
