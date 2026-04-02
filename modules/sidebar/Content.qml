pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.config

Item {
    id: root

    required property Props props
    required property DrawerVisibilities visibilities

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Appearance.spacing.normal

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainerLow

            NotifDock {
                props: root.props
                visibilities: root.visibilities
            }
        }

        // Upcoming events
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(upcomingCol.implicitHeight, 300)

            visible: Config.sidebar.showUpcoming && GCalendar.enabled && GCalendar.upcomingSidebar.length > 0
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainerLow

            ColumnLayout {
                id: upcomingHeader

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Appearance.padding.normal

                StyledText {
                    Layout.topMargin: Appearance.padding.small
                    text: qsTr("Upcoming Events")
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.small
                    font.weight: 600
                }
            }

            StyledFlickable {
                id: upcomingView

                clip: true
                anchors.top: upcomingHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Appearance.padding.normal
                anchors.topMargin: Appearance.spacing.small

                flickableDirection: Flickable.VerticalFlick
                contentWidth: width
                contentHeight: upcomingCol.implicitHeight

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: upcomingView
                }

                ColumnLayout {
                    id: upcomingCol

                    width: parent.width
                    spacing: Appearance.spacing.small

                    Repeater {
                        model: GCalendar.upcomingSidebar

                        RowLayout {
                            id: sidebarEventRow

                            required property var modelData

                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            Rectangle {
                                Layout.preferredWidth: 3
                                Layout.fillHeight: true
                                radius: 1.5
                                color: Colours.palette.m3tertiary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: sidebarEventRow.modelData.summary
                                    color: Colours.palette.m3onSurface
                                    font.pointSize: Appearance.font.size.small
                                    font.weight: 500
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: {
                                        let line = GCalendar.formatEventTime(sidebarEventRow.modelData, Config.services.calendar.sidebarUpcomingHours);
                                        if (sidebarEventRow.modelData.location)
                                            line += ` · ${sidebarEventRow.modelData.location}`;
                                        return line;
                                    }
                                    color: Colours.palette.m3onSurfaceVariant
                                    font.pointSize: Appearance.font.size.small * 0.9
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    Item {
                        Layout.preferredHeight: Appearance.padding.small
                    }
                }
            }
        }

        StyledRect {
            Layout.topMargin: Appearance.padding.large - layout.spacing
            Layout.fillWidth: true
            implicitHeight: 1

            color: Colours.tPalette.m3outlineVariant
        }
    }
}
