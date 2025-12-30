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
    readonly property int nestingLevel: sectionPath.length - 1

    // Hidden reference to get exact CustomSpinBox dimensions
    CustomSpinBox {
        id: spinBoxReference
        visible: false
        value: 0
    }

    // Subtle background for nested items
    Rectangle {
        anchors.fill: parent
        color: nestingLevel > 1 ? Qt.rgba(
            Colours.palette.m3surfaceContainerHighest.r,
            Colours.palette.m3surfaceContainerHighest.g,
            Colours.palette.m3surfaceContainerHighest.b,
            0.15 * (nestingLevel - 1)
        ) : "transparent"
        radius: Appearance.rounding.small
    }

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
            // textFieldHeight: 36
        }

        Item {
            visible: !root.isInteger
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: spinBoxReference.implicitWidth
            Layout.preferredHeight: spinBoxReference.implicitHeight

            StyledTextField {
                anchors.fill: parent
                text: Number(root.currentValue ?? 0).toFixed(2)
                placeholderText: qsTr("Enter number...")
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                padding: Appearance.padding.small
                leftPadding: Appearance.padding.normal
                rightPadding: Appearance.padding.normal
                verticalAlignment: TextInput.AlignVCenter
                

                background: StyledRect {
                    radius: Appearance.rounding.small
                    color: Colours.tPalette.m3surfaceContainerHigh
                    implicitHeight: 36
                }

                onEditingFinished: {
                    const num = parseFloat(text);
                    if (!isNaN(num)) root.updateValue(num);
                }
            }
        }
    }
}
