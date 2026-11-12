import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.calendar
import qs.modules.notch
import qs.modules.notch.pages.calendar

NotchPage {
    id: root

    implicitWidth: 960
    implicitHeight: 400

    Component.onDestruction: DayView.close()

    RowLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.medium

        StyledRect {
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            radius: Tokens.rounding.extraLarge
            color: Hallownest.card

            MonthGrid {
                anchors.verticalCenter: parent.verticalCenter
                screenState: root.screenState
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.extraLarge
            color: Hallownest.card
            clip: true

            Week {
                anchors.fill: parent
                opacity: DayView.shown ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            Loader {
                id: dayLoader

                anchors.fill: parent
                active: DayView.shown
                opacity: 0
                sourceComponent: DayEvents {
                    date: DayView.date
                    onClose: DayView.close()
                }

                // Unfold from the top: fade in and slide down on load
                transform: Translate {
                    y: (dayLoader.opacity - 1) * 24
                }

                onLoaded: {
                    opacity = 1;
                    item.forceActiveFocus();
                }
                onActiveChanged: {
                    if (!active) {
                        opacity = 0;
                        // hand the keys back to the notch (page arrows, Escape)
                        root.forceActiveFocus();
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }
    }
}
