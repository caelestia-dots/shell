import "../"
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

BaseConfigItem {
    id: root

    readonly property bool isInteger: propertyData.type === "int"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: ConfigParser.formatPropertyName(root.propertyData.name)
            font.pointSize: Appearance.font.size.normal
            color: Colours.palette.m3onSurface
        }

        CustomSpinBox {
            visible: root.isInteger
            Layout.alignment: Qt.AlignRight
            value: root.currentValue ?? 0
            onValueModified: root.updateValue(value)
        }

        StyledTextField {
            visible: !root.isInteger
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 150
            text: Number(root.currentValue ?? 0).toFixed(2)
            placeholderText: qsTr("Enter number...")
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            padding: Appearance.padding.small
            leftPadding: Appearance.padding.normal
            rightPadding: Appearance.padding.normal

            background: StyledRect {
                implicitWidth: 150
                implicitHeight: 36
                radius: Appearance.rounding.small
                color: Colours.tPalette.m3surfaceContainerHigh
            }

            onEditingFinished: {
                const num = parseFloat(text);
                if (!isNaN(num)) root.updateValue(num);
            }
        }
    }
}
