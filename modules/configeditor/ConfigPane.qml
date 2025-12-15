import "."
import "./items"
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string activeSection: "appearance"
    readonly property var sectionPath: [activeSection]
    readonly property var currentSectionData: ConfigParser.configSections.find(s => s.name === activeSection) ?? null
    readonly property var configObject: ConfigParser.getSectionData(activeSection)
    readonly property var properties: (ConfigParser.loaded && configObject) ? ConfigParser.getPropertiesForObject(configObject, [activeSection]) : []

    opacity: 0
    Component.onCompleted: opacity = 1

    Behavior on opacity {
        Anim { duration: Appearance.anim.durations.normal }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            Layout.leftMargin: Appearance.padding.larger
            Layout.rightMargin: Appearance.padding.larger
            Layout.topMargin: Appearance.padding.normal

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: Appearance.padding.normal
                spacing: Appearance.spacing.small

                StyledText {
                    text: root.currentSectionData?.title ?? qsTr("Configuration")
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: 600
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    text: qsTr("%1 settings").arg(root.properties.length)
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        StyledFlickable {
            id: flickable

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Appearance.padding.larger
            Layout.rightMargin: Appearance.padding.larger

            contentWidth: width
            contentHeight: contentColumn.implicitHeight + Appearance.padding.larger
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contentColumn

                width: parent.width - Appearance.padding.normal
                spacing: 0

                Repeater {
                    model: root.properties

                    delegate: PropertyEditor {
                        required property var modelData
                        required property int index
                        
                        configObject: root.configObject
                        propertyData: modelData
                        sectionPath: root.sectionPath

                        // Separator
                        StyledRect {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Colours.palette.m3outlineVariant
                            opacity: 0.3
                            visible: index < root.properties.length - 1
                        }
                    }
                }
            }

            StyledScrollBar {
                flickable: parent
            }
        }
    }

}
