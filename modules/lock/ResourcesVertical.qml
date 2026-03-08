import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

GridLayout {
    id: root

    anchors.fill: parent
    anchors.margins: Appearance.padding.small

    rowSpacing: Appearance.spacing.small
    columnSpacing: Appearance.spacing.small

    rows: 1
    columns: 4

    Ref { service: SystemUsage }

    Resource { icon: "memory"; value: SystemUsage.cpuPerc; colour: Colours.palette.m3primary }
    Resource { icon: "thermostat"; value: Math.min(1, SystemUsage.cpuTemp / 90); colour: Colours.palette.m3secondary }
    Resource { icon: "memory_alt"; value: SystemUsage.memPerc; colour: Colours.palette.m3secondary }
    Resource { icon: "hard_disk"; value: SystemUsage.storagePerc; colour: Colours.palette.m3tertiary }

    component Resource: StyledRect {
        id: res

        required property string icon
        required property real value
        required property color colour

        Layout.fillWidth: true
        implicitHeight: Math.round(width * 0.95)

        color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
        radius: Appearance.rounding.large

        Item {
            id: square
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height)
            height: width

            CircularProgress {
                id: circ
                anchors.fill: parent
                value: res.value
                padding: Appearance.padding.large * 1.2
                fgColour: res.colour
                bgColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 3)
                strokeWidth: width < 200 ? Appearance.padding.smaller : Appearance.padding.normal
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: res.icon
                color: res.colour
                font.pointSize: (circ.arcRadius * 1.0) || 1
                font.weight: 600
            }
        }

        Behavior on value { Anim { duration: Appearance.anim.durations.large } }
    }
}
