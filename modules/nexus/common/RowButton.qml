pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ConnectedRect {
    id: root

    property alias icon: iconLabel.text
    property alias text: label.text
    property string trailingIcon
    property alias disabled: stateLayer.disabled

    signal clicked(event: MouseEvent)

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Tokens.padding.medium * 2

    StateLayer {
        id: stateLayer

        onClicked: e => root.clicked(e)
    }

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.largeIncreased

        spacing: Tokens.spacing.medium
        opacity: root.disabled ? 0.5 : 1

        Behavior on opacity {
            Anim {}
        }

        MaterialIcon {
            id: iconLabel

            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
            fill: 1
        }

        StyledText {
            id: label

            Layout.fillWidth: true
            font: Tokens.font.body.small
            elide: Text.ElideRight
        }

        Loader {
            asynchronous: true
            active: root.trailingIcon
            visible: active

            sourceComponent: MaterialIcon {
                text: root.trailingIcon
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }
        }
    }
}
