pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

ConnectedRect {
    id: root

    property alias label: label.text
    property string subtext
    property alias value: input.text
    property alias placeholderText: input.placeholderText
    property alias errorText: input.errorText
    property alias maximumLength: input.maximumLength
    property alias validate: input.validate
    property int fieldWidth: 200
    property int fieldVerticalPadding: Tokens.padding.small
    readonly property alias field: input

    signal valueEdited(value: string)
    signal editingFinished(value: string)

    function clear(): void {
        input.clear();
    }

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + Tokens.padding.medium + Math.max(0, Tokens.padding.large - fieldVerticalPadding) * 2

    RowLayout {
        id: rowLayout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

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
                Layout.fillWidth: true
                visible: root.subtext
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        StyledTextField {
            id: input

            Layout.preferredWidth: root.fieldWidth
            Layout.alignment: Qt.AlignVCenter
            verticalPadding: root.fieldVerticalPadding

            onTextEdited: root.valueEdited(text)
            onEditingFinished: root.editingFinished(text)
        }
    }
}
