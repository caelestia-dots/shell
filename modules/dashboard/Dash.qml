import "dash"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.services

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property DashboardState dashState
    required property FileDialog facePicker

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    GridLayout {
        id: grid
        anchors.fill: parent

        rowSpacing: Tokens.spacing.normal
        columnSpacing: Tokens.spacing.normal

        Rect {
            Layout.column: 2
            Layout.columnSpan: 3
            Layout.preferredWidth: user.implicitWidth
            Layout.preferredHeight: user.implicitHeight

            radius: Tokens.rounding.large

            User {
                id: user

                visibilities: root.visibilities
                facePicker: root.facePicker
            }
        }

        Rect {
            Layout.row: 0
            Layout.columnSpan: 2
            Layout.preferredWidth: Tokens.sizes.dashboard.weatherWidth
            Layout.fillHeight: true

            radius: Tokens.rounding.large * 1.5

            SmallWeather {}
        }

        Rect {
            id: dateTimeRect
            Layout.row: 1
            Layout.preferredWidth: dateTime.implicitWidth
            Layout.fillHeight: true
            radius: Tokens.rounding.normal

            DateTime {
                id: dateTime
                dashState: root.dashState
            }
        }

        Rect {
            id: calendarRect
            Layout.row: 1
            Layout.column: 1
            Layout.columnSpan: 3
            Layout.fillWidth: true
            Layout.preferredHeight: calendarLoader.implicitHeight
            radius: Tokens.rounding.large
            opacity: root.dashState.timerPanelOpen ? 0 : 1

            Loader {
                id: calendarLoader
                anchors.fill: parent
                sourceComponent: Calendar {
                    dashState: root.dashState
                }
            }
        }

        Rect {
            Layout.row: 1
            Layout.column: 4
            Layout.preferredWidth: resources.implicitWidth
            Layout.fillHeight: true

            radius: Tokens.rounding.normal

            Resources {
                id: resources
            }
        }

        Rect {
            Layout.row: 0
            Layout.column: 5
            Layout.rowSpan: 2
            Layout.preferredWidth: media.implicitWidth
            Layout.fillHeight: true

            radius: Tokens.rounding.large * 2

            Media {
                id: media
            }
        }

        component Rect: StyledRect {
            color: Colours.tPalette.m3surfaceContainer
        }
    }

    // Overlay: expands rightward starting from the RIGHT edge of the clock block.
    // Only covers the calendar area - clock stays fully visible.
    StyledRect {
        id: timerOverlay
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.large
        z: 1
        clip: true

        x: calendarRect.x
        y: calendarRect.y
        height: calendarRect.height

        width: root.dashState.timerPanelOpen ? calendarRect.width : 0

        Behavior on width { Anim { type: Anim.DefaultSpatial } }

        DashTimerPanel {
            anchors.fill: parent
            dashState: root.dashState
        }
    }
}
