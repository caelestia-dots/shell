import QtQuick
import Caelestia.Config
import qs.components
import qs.components.misc
import qs.services

Row {
    id: root

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    padding: Tokens.padding.large
    spacing: Tokens.spacing.normal

    Ref {
        service: SystemUsage
    }

    Resource {
        icon: "memory"
        value: SystemUsage.cpuPerc
        colour: Colours.palette.m3primary
    }

    Resource {
        icon: "memory_alt"
        value: SystemUsage.memPerc
        colour: Colours.palette.m3secondary
    }

    Resource {
        icon: "hard_disk"
        value: SystemUsage.storagePerc
        colour: Colours.palette.m3tertiary
    }

    component Resource: Item {
        id: res

        required property string icon
        required property real value
        required property color colour

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.large
        implicitWidth: icon.implicitWidth

        StyledRect {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: icon.top
            anchors.bottomMargin: Tokens.spacing.small

            implicitWidth: Tokens.sizes.dashboard.resourceProgressThickness

            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
            radius: Tokens.rounding.full

            StyledRect {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                implicitHeight: res.value * parent.height

                color: res.colour
                radius: Tokens.rounding.full
            }
        }

        MaterialIcon {
            id: icon

            anchors.bottom: parent.bottom

            text: res.icon
            color: res.colour
        }

        Behavior on value {
            Anim {
                type: Anim.StandardLarge
            }
        }
    }
}
