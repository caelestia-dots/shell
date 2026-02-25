import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    implicitHeight: layout.implicitHeight + Appearance.padding.large * 2
    Layout.fillWidth: true
    radius: Appearance.rounding.normal
    color: Colours.tPalette.m3surfaceContainer
    clip: true

    ColumnLayout {
        id: layout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        // --- Master Row: Primary Toggle ---
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            StyledRect {
                implicitWidth: 40; implicitHeight: 40; radius: Appearance.rounding.full
                color: Sunset.active ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer
                MaterialIcon {
                    anchors.centerIn: parent
                    text: Sunset.active ? "moon_stars" : "partly_cloudy_night"
                    color: Sunset.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                }
            }

            ColumnLayout {
                spacing: 0
                StyledText { text: qsTr("Night Light") }
                StyledText {
                    text: Sunset.active ? qsTr("%1K").arg(Sunset.temperature) : qsTr("Disabled")
                    color: Colours.palette.m3onSurfaceVariant; font.pointSize: Appearance.font.size.small
                }
            }

            Item { Layout.fillWidth: true }

            StyledSwitch {
                checked: Sunset.enabled
                onToggled: Sunset.enabled = checked
            }
        }
        //Slider for temp.
        ColumnLayout {
            id: extraControls
            Layout.fillWidth: true
            visible: Sunset.active
            opacity: Sunset.active ? 1 : 0
            spacing: Appearance.spacing.small

            Behavior on opacity { NumberAnimation { duration: 200 } }

            RowLayout {
                StyledText {
                    text: "Warm"
                    font.pointSize: Appearance.font.size.smaller
                    color: Colours.palette.m3onSurfaceVariant
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: "Cool"
                    font.pointSize: Appearance.font.size.smaller
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            StyledSlider {
                Layout.fillWidth: true
                implicitHeight: 26
                from: 2000; to: 7500; stepSize: 100
                value: Sunset.temperature
                onMoved: Sunset.temperature = value
            }
        }
    }

    Behavior on implicitHeight {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }
}
