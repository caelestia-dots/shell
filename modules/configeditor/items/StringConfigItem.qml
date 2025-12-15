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

        Item {
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: spinBoxReference.implicitWidth
            Layout.preferredHeight: spinBoxReference.implicitHeight

            StyledTextField {
                anchors.fill: parent
                text: root.currentValue ?? ""
                placeholderText: qsTr("Enter value...")
                padding: Appearance.padding.small
                leftPadding: Appearance.padding.normal
                rightPadding: Appearance.padding.normal
                verticalAlignment: TextInput.AlignVCenter

                background: StyledRect {
                    radius: Appearance.rounding.small
                    color: Colours.tPalette.m3surfaceContainerHigh
                }

                onEditingFinished: root.updateValue(text)
            }
        }
    }
}
