pragma ComponentBehavior: Bound

import qs.components
import qs.components.filedialog
import qs.services
import qs.config
import "dash"
import Quickshell
import QtQuick
import QtQuick.Layouts

GridLayout {
    id: root

    required property PersistentProperties visibilities
    required property PersistentProperties state
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
            state: root.state
            facePicker: root.facePicker
        }
    }

    Rect {
        Layout.row: 0
        Layout.columnSpan: 2
        Layout.preferredWidth: Config.dashboard.sizes.weatherWidth
        Layout.fillHeight: true

        radius: Appearance.rounding.large * 1.5

        Weather {}
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

            state: root.state
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
        Layout.rowSpan: GCalendar.upcoming.length > 0 ? 3 : 2
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

        visible: GCalendar.upcoming.length > 0
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
                model: GCalendar.upcoming

                RowLayout {
                    id: eventRow

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    Rectangle {
                        width: 3
                        Layout.fillHeight: true
                        radius: 1.5
                        color: Colours.palette.m3tertiary
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
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                let line = GCalendar.formatEventTime(eventRow.modelData);
                                if (eventRow.modelData.location)
                                    line += ` · ${eventRow.modelData.location}`;
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

    component Rect: StyledRect {
        color: Colours.tPalette.m3surfaceContainer
    }
}
