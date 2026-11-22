import QtQuick
import qs.services

Rectangle {
    id: root

    property bool ornate
    property real filigreeDrawn: 1

    radius: 14
    color: Hallownest.card
    border.width: 1
    border.color: Hallownest.border

    HkGrain {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        visible: root.ornate
    }

    // Subtle top rim highlight, as if pale light falls from above
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.radius
        anchors.rightMargin: root.radius
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: 0.5
                color: Qt.alpha(Hallownest.soul, Hallownest.light ? 0.16 : 0.1)
            }
            GradientStop {
                position: 1
                color: "transparent"
            }
        }
    }

    // Fine inset hairline frame on ornate cards
    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        visible: root.ornate
        radius: Math.max(2, root.radius - 4)
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Hallownest.steel, 0.09)
    }

    Filigree {
        anchors.fill: parent
        radius: root.radius
        inset: 5
        drawn: root.filigreeDrawn
        opacity: root.ornate ? 0.3 : 0
    }
}
