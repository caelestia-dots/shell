import "."
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    property string activeSection: "appearance"

    color: Colours.tPalette.m3surfaceContainer
    topLeftRadius: 0
    bottomLeftRadius: 0
    topRightRadius: 0
    bottomRightRadius: 0

    implicitWidth: 250

    component NavItem: StyledRect {
        id: navItem

        required property var sectionData
        property bool active: false

        signal clicked()

        implicitHeight: 48
        radius: Appearance.rounding.normal
        color: active ? Colours.palette.m3secondaryContainer : "transparent"

        StateLayer {
            radius: parent.radius

            function onClicked(): void {
                navItem.clicked();
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.padding.larger
            anchors.rightMargin: Appearance.padding.larger
            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: navItem.sectionData.icon
                color: navItem.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.large
            }

            StyledText {
                Layout.fillWidth: true

                text: navItem.sectionData.title
                color: navItem.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.normal
                elide: Text.ElideRight
            }
        }

        Behavior on color {
            CAnim {}
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.padding.normal
        spacing: Appearance.spacing.small

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.padding.normal
            Layout.bottomMargin: Appearance.padding.normal
            Layout.leftMargin: Appearance.padding.normal

            text: qsTr("Configuration")
            font.pointSize: Appearance.font.size.large
            font.bold: true
            color: Colours.palette.m3onSurface
        }

        StyledFlickable {
            id: navFlickable

            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: navList.implicitHeight
            clip: true

            ColumnLayout {
                id: navList

                width: parent.width
                spacing: Appearance.spacing.small

                Repeater {
                    model: ConfigParser.configSections

                    delegate: Item {
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: navItem.implicitHeight

                        NavItem {
                            id: navItem

                            anchors.fill: parent
                            sectionData: parent.modelData
                            active: root.activeSection === parent.modelData.name

                            onClicked: root.activeSection = parent.modelData.name
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
