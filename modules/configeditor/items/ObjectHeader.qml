import "../"
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var configObject
    required property var propertyData
    required property var sectionPath

    readonly property var nestedPath: [...sectionPath, propertyData.name]
    readonly property var nestedObject: configObject[propertyData.name]
    readonly property string statePath: nestedPath.join(".")
    property bool expanded: ConfigParser.getExpandedState(statePath)
    
    onExpandedChanged: ConfigParser.setExpandedState(statePath, expanded)

    spacing: 0

    // Header
    StyledRect {
        Layout.fillWidth: true
        implicitHeight: 56

        color: "transparent"
        radius: Appearance.rounding.normal

        StateLayer {
            radius: parent.radius

            function onClicked(): void {
                root.expanded = !root.expanded;
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.padding.normal
            anchors.rightMargin: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: root.expanded ? "expand_more" : "chevron_right"
                color: Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.normal

                Behavior on rotation {
                    Anim {
                        duration: Appearance.anim.durations.small
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: ConfigParser.formatPropertyName(root.propertyData.name)
                font.pointSize: Appearance.font.size.normal
                color: Colours.palette.m3onSurface
            }

            MaterialIcon {
                text: "data_object"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.normal
                opacity: 0.5
            }
        }
    }

    // Nested content
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.expanded
        spacing: 0

        Repeater {
            model: root.expanded ? ConfigParser.getPropertiesForObject(root.nestedObject) : []

            delegate: PropertyEditor {
                required property var modelData
                
                configObject: root.nestedObject
                propertyData: modelData
                sectionPath: root.nestedPath
            }
        }
    }
}
