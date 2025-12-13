import "../"
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

// Reusable property editor that handles all types
Item {
    id: root

    required property var configObject
    required property var propertyData
    required property var sectionPath
    
    property var currentValue: configObject[propertyData.name]
    readonly property var fullPath: [...sectionPath, propertyData.name]
    
    Layout.fillWidth: true
    Layout.preferredHeight: 56
    
    CustomSpinBox {
        id: widthReference
        visible: false
        value: 0
    }
    
    Connections {
        target: ConfigParser
        function onValueChanged(path) {
            if (path.length === root.fullPath.length && 
                path.every((v, i) => v === root.fullPath[i])) {
                root.currentValue = root.configObject[root.propertyData.name];
            }
        }
    }
    
    function updateValue(value) {
        ConfigParser.updateValue(root.fullPath, value);
    }
    
    // Boolean property
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal
        visible: propertyData.type === "bool" && propertyData.writable
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: ConfigParser.formatPropertyName(propertyData.name)
            font.pointSize: Appearance.font.size.normal
            color: Colours.palette.m3onSurface
        }

        StyledSwitch {
            Layout.alignment: Qt.AlignRight
            checked: currentValue ?? false
            onToggled: root.updateValue(checked)
        }
    }

    // String property
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal
        visible: propertyData.type === "string" && propertyData.writable
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: ConfigParser.formatPropertyName(propertyData.name)
            font.pointSize: Appearance.font.size.normal
            color: Colours.palette.m3onSurface
        }

        StyledTextField {
            Layout.alignment: Qt.AlignRight
            text: currentValue ?? ""
            placeholderText: qsTr("Enter value...")
            padding: Appearance.padding.small
            leftPadding: Appearance.padding.normal
            rightPadding: Appearance.padding.normal

            background: StyledRect {
                implicitWidth: widthReference.implicitWidth
                implicitHeight: 36
                radius: Appearance.rounding.small
                color: Colours.tPalette.m3surfaceContainerHigh
            }
            
            onEditingFinished: root.updateValue(text)
        }
    }

    // Integer property
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal
        visible: propertyData.type === "int" && propertyData.writable
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: ConfigParser.formatPropertyName(propertyData.name)
            font.pointSize: Appearance.font.size.normal
            color: Colours.palette.m3onSurface
        }

        CustomSpinBox {
            Layout.alignment: Qt.AlignRight
            value: currentValue ?? 0
            onValueModified: root.updateValue(value)
        }
    }

    // Real property
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal
        visible: propertyData.type === "real" && propertyData.writable
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: ConfigParser.formatPropertyName(propertyData.name)
            font.pointSize: Appearance.font.size.normal
            color: Colours.palette.m3onSurface
        }

        StyledTextField {
            Layout.alignment: Qt.AlignRight
            text: Number(currentValue ?? 0).toFixed(2)
            placeholderText: qsTr("Enter number...")
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            padding: Appearance.padding.small
            leftPadding: Appearance.padding.normal
            rightPadding: Appearance.padding.normal

            background: StyledRect {
                implicitWidth: widthReference.implicitWidth
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
    
    // Separator
    StyledRect {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Colours.palette.m3outlineVariant
        opacity: 0.3
    }
}
