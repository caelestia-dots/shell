import qs.components
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    default property alias content: contentColumn.data
    property real contentSpacing: Appearance.spacing.larger

    Layout.fillWidth: true
    implicitHeight: contentColumn.implicitHeight + Appearance.padding.large * 2

    radius: Appearance.rounding.normal
    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

    ColumnLayout {
        id: contentColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Appearance.padding.large

        spacing: root.contentSpacing
    }
}

