pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import qs.components
import qs.services
import qs.config

Item {
    id: root

    required property var modelData
    required property PersistentProperties visibilities

    StyledRect {
        id: rect

        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: {
            if (mouse.containsMouse)
                return Qt.alpha(Colours.palette.m3onSurface, 0.08);
            if (GridView.isCurrentItem)
                return Qt.alpha(Colours.palette.m3onSurface, 0.08);
            return "transparent";
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                Emojis.copyEmoji(root.modelData); // qmllint disable missing-property
                root.visibilities.launcher = false;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.smaller / 2
            spacing: Appearance.spacing.smaller

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                text: root.modelData.emoji
                font.pointSize: Appearance.font.size.extraLarge * 1.2
                horizontalAlignment: Text.AlignHCenter
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.maximumWidth: rect.width - Appearance.padding.small * 2
                text: root.modelData.name
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.NoWrap
            }
        }
    }
}
