pragma ComponentBehavior: Bound

import "dash"
import QtQuick.Layouts
import qs.components
import qs.components.filedialog
import qs.services
import qs.config

GridLayout {
    id: root

    required property DrawerVisibilities visibilities
    required property DashboardState dashState
    required property FileDialog facePicker

    rowSpacing: Appearance.spacing.normal
    columnSpacing: Appearance.spacing.normal

    Rect {
        Layout.column: 2
        Layout.columnSpan: 3
        Layout.preferredWidth: user.implicitWidth
        Layout.preferredHeight: user.implicitHeight

        radius: Appearance.rounding.large

        User {
            id: user

            visibilities: root.visibilities
            facePicker: root.facePicker
        }
    }

    Rect {
        Layout.row: 0
        Layout.columnSpan: 2
        Layout.preferredWidth: Config.dashboard.sizes.weatherWidth
        Layout.fillHeight: true

        radius: Appearance.rounding.large * 1.5

        SmallWeather {}
    }

    Rect {
        Layout.row: 1
        Layout.preferredWidth: dateTime.implicitWidth
        Layout.fillHeight: true

        radius: Appearance.rounding.normal

        DateTime {
            id: dateTime
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 1
        Layout.columnSpan: 3
        Layout.fillWidth: true
        Layout.preferredHeight: calendar.implicitHeight

        radius: Appearance.rounding.large

        Calendar {
            id: calendar

            dashState: root.dashState
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 4
        Layout.preferredWidth: resources.implicitWidth
        Layout.fillHeight: true

        radius: Appearance.rounding.normal

        Resources {
            id: resources
        }
    }

    Rect {
        Layout.row: 0
        Layout.column: 5
        Layout.rowSpan: Config.dashboard.showUpcoming && GCalendar.upcomingDash.length > 0 ? 3 : 2
        Layout.preferredWidth: media.implicitWidth
        Layout.fillHeight: true

        radius: Appearance.rounding.large * 2

        Media {
            id: media
        }
    }

    // Upcoming events
    Rect {
        Layout.row: 2
        Layout.column: 0
        Layout.columnSpan: 5
        Layout.fillWidth: true
        Layout.preferredHeight: eventsCol.implicitHeight

        visible: Config.dashboard.showUpcoming && GCalendar.upcomingDash.length > 0
        radius: Appearance.rounding.large

        ColumnLayout {
            id: eventsCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.small

            StyledText {
                Layout.topMargin: Appearance.padding.small
                text: qsTr("Upcoming")
                color: Colours.palette.m3primary
                font.pointSize: Appearance.font.size.small
                font.weight: 600
            }

            Repeater {
                model: GCalendar.upcomingDash // qmllint disable missing-property

                RowLayout { // qmllint disable missing-property
                    id: eventRow

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    Rectangle {
                        Layout.preferredWidth: 3
                        Layout.fillHeight: true
                        radius: 1.5 // qmllint disable missing-property
                        color: Colours.palette.m3tertiary // qmllint disable missing-property
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: eventRow.modelData.summary
                            color: Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.small
                            font.weight: 500
                            elide: Text.ElideRight // qmllint disable unqualified
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                let line = GCalendar.formatEventTime(eventRow.modelData, Config.services.calendar.dashUpcomingHours);
                                if (eventRow.modelData.location)
                                    line += ` · ${eventRow.modelData.location}`;
                                return line;
                            }
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Appearance.font.size.small * 0.9
                            elide: Text.ElideRight // qmllint disable unqualified
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: Appearance.padding.small
            }
        }
    }

    component Rect: StyledRect {
        color: Colours.tPalette.m3surfaceContainer
    }
}
