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
    property string value
    property alias placeholderText: input.placeholderText
    property string errorText
    property alias maximumLength: input.maximumLength
    property alias validate: input.validate
    property alias validator: input.validator
    property bool smallField
    readonly property alias field: input

    signal valueEdited(value: string)
    signal editingFinished(value: string)

    function clear(): void {
        input.clear();
    }

    Component.onDestruction: {
        if (value !== input.text)
            editingFinished(input.text);
    }

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + Tokens.padding.medium + Math.max(0, Tokens.padding.large - input.verticalPadding) * 2

    RowLayout {
        id: rowLayout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
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
                text: input.isError && root.errorText ? root.errorText : root.subtext
                color: input.isError && root.errorText ? Colours.palette.m3error : Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
                animate: root.errorText
            }
        }

        StyledTextField {
            id: input

            Layout.preferredWidth: root.smallField ? Tokens.sizes.nexus.smallTextFieldWidth : Tokens.sizes.nexus.textFieldWidth
            Layout.maximumWidth: root.width / 2
            Layout.alignment: Qt.AlignVCenter
            verticalPadding: Tokens.padding.small

            text: root.value

            onTextEdited: root.valueEdited(text)
            onEditingFinished: root.editingFinished(text)
        }
    }
}
