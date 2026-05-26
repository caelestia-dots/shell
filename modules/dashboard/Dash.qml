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

        // Clock + calendar merged zone. Clock rect expands rightward - no stacking.
        Item {
            id: clockCalendarZone
            Layout.row: 1
            Layout.column: 0
            Layout.columnSpan: 4
            Layout.fillWidth: true
            Layout.preferredHeight: calendarLoader.implicitHeight

            // Calendar background - disappears instantly when timer opens
            StyledRect {
                id: calBg
                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.large
                x: Tokens.sizes.dashboard.dateTimeWidth + Tokens.spacing.normal
                y: 0
                width: parent.width - x
                height: parent.height
                opacity: root.dashState.timerPanelOpen ? 0 : 1

                Loader {
                    id: calendarLoader
                    anchors.fill: parent
                    sourceComponent: Calendar {
                        dashState: root.dashState
                    }
                }
            }

            // Clock rect - single rect, expands its right edge to fill the calendar area
            StyledRect {
                id: clockBg
                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.normal
                x: 0
                y: 0
                height: parent.height
                clip: true

                width: root.dashState.timerPanelOpen
                    ? parent.width
                    : Tokens.sizes.dashboard.dateTimeWidth

                Behavior on width { Anim { type: Anim.DefaultSpatial } }

                // Panel fills the full clockBg so content centers in the whole menu
                DashTimerPanel {
                    anchors.fill: parent
                    visible: root.dashState.timerPanelOpen
                    dashState: root.dashState
                }

                // DateTime on top (z:1) so the back button stays visible over the panel
                DateTime {
                    id: dateTime
                    z: 1
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
}
