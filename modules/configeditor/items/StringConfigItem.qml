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

    // Hidden reference to get exact CustomSpinBox dimensions
    CustomSpinBox {
        id: spinBoxReference
        visible: false
        value: 0
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
