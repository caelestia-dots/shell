pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.services
import qs.modules.nexus.common

ConnectedRect {
    id: root

    required property FileDialog filePicker

    property alias label: label.text
    property alias value: value.text
    property string icon
    property color iconColour: Colours.palette.m3onSurfaceVariant
    property Component leadingComponent: icon ? iconComp : null
    property bool disabled: false

    property real textOpacity: disabled ? 0.5 : 1

    signal resetRequested

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2

    Component {
        id: iconComp

        MaterialIcon {
            text: root.icon
            color: root.iconColour
            fontStyle: Tokens.font.icon.small
            opacity: root.textOpacity
        }
    }

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.large

        Loader {
            visible: root.leadingComponent
            active: root.leadingComponent
            sourceComponent: root.leadingComponent
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: label

                Layout.fillWidth: true
                font: Tokens.font.body.small
                elide: Text.ElideRight
                opacity: root.textOpacity
            }

            StyledText {
                id: value

                Layout.fillWidth: true
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
                opacity: root.textOpacity
            }
        }

        IconTextButton {
            id: resetBtn

            type: IconTextButton.Tonal

            icon: "refresh"
            text: qsTr("Reset")
            isRound: true
            opacity: root.textOpacity

            onClicked: {
                if (root.disabled)
                    return;
                root.resetRequested();
            }
        }

        IconTextButton {
            Layout.preferredHeight: resetBtn.implicitHeight
            text: qsTr("Pick file")
            icon: "folder"
            opacity: root.textOpacity

            isRound: true

            onClicked: {
                if (root.disabled)
                    return;
                filePicker.open();
            }
        }
    }
}
