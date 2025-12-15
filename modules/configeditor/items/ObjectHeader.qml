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
    readonly property int nestingLevel: sectionPath.length - 1
    readonly property int leftIndent: nestingLevel * Appearance.padding.larger
    property bool expanded: ConfigParser.getExpandedState(statePath)
    
    onExpandedChanged: ConfigParser.setExpandedState(statePath, expanded)

    spacing: 0

    // Header
    StyledRect {
        Layout.fillWidth: true
        Layout.leftMargin: root.leftIndent
        implicitHeight: 56

        color: root.expanded ? Qt.rgba(
            Colours.palette.m3secondaryContainer.r,
            Colours.palette.m3secondaryContainer.g,
            Colours.palette.m3secondaryContainer.b,
            0.3
        ) : "transparent"
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

            // Visual depth indicator
            Rectangle {
                visible: root.nestingLevel > 1
                Layout.preferredWidth: 3
                Layout.fillHeight: true
                Layout.topMargin: Appearance.padding.small
                Layout.bottomMargin: Appearance.padding.small
                color: Colours.palette.m3primary
                opacity: 0.3
                radius: 2
            }

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
                font.weight: root.nestingLevel > 1 ? Font.Medium : Font.Normal
                color: Colours.palette.m3onSurface
            }

            // Nesting level badge
            StyledRect {
                visible: root.nestingLevel > 1
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                color: Colours.palette.m3secondaryContainer
                radius: 12

                StyledText {
                    anchors.centerIn: parent
                    text: root.nestingLevel.toString()
                    font.pointSize: Appearance.font.size.small - 1
                    color: Colours.palette.m3onSecondaryContainer
                }
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
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: root.leftIndent + Appearance.padding.normal
        Layout.preferredHeight: nestedColumn.implicitHeight
        visible: root.expanded

        // Left border line for nested content
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: Appearance.padding.small
            width: 2
            color: Colours.palette.m3primary
            opacity: 0.2
            radius: 1
        }

        ColumnLayout {
            id: nestedColumn
            anchors.fill: parent
            anchors.leftMargin: Appearance.padding.normal
            spacing: 0

            Repeater {
                model: root.expanded ? ConfigParser.getPropertiesForObject(root.nestedObject, root.nestedPath) : []

                delegate: PropertyEditor {
                    required property var modelData
                    required property int index
                    
                    configObject: root.nestedObject
                    propertyData: modelData
                    sectionPath: root.nestedPath

                    // Separator between nested items
                    StyledRect {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: Colours.palette.m3outlineVariant
                        opacity: 0.2
                        visible: index < (root.expanded ? ConfigParser.getPropertiesForObject(root.nestedObject, root.nestedPath).length : 0) - 1
                    }
                }
            }
        }
    }
}
