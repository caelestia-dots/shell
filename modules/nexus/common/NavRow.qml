pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

ConnectedRect {
    id: root

    property alias icon: icon.text
    property alias label: label.text
    property alias status: status.text

    signal clicked

    Layout.fillWidth: true
    implicitHeight: navLayout.implicitHeight + navLayout.anchors.margins * 2

    StateLayer {
        onClicked: root.clicked()
    }

    RowLayout {
        id: navLayout

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        MaterialIcon {
            id: icon

            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.icon.medium
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: label

                Layout.fillWidth: true
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                id: status

                Layout.fillWidth: true
                visible: text
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
                animate: true
            }
        }

        MaterialIcon {
            text: "chevron_right"
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.icon.medium
        }
    }
}
