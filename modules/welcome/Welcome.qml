import QtQuick.Layouts
import qs.components
import qs.services

StyledRect {
    id: root

    property int currentPage: 0

    readonly property var pages: [
        { name: "Welcome", icon: "waving_hand" },
    ]

    color: Colours.palette.m3background

    RowLayout {
        anchors.fill: parent
        spacing: 0
    }
}