import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import Caelestia.Scheme
import qs.components

RowLayout {
    id: root

    required property string appName
    required property string timeStr
    required property int count
    required property int urgency
    required property color pillColour
    required property bool expandable
    required property bool expanded

    signal toggle

    spacing: Tokens.spacing.small

    StyledText {
        Layout.fillWidth: true
        text: root.appName
        color: Colours.palette.onSurfaceVariant
        font: Tokens.font.body.small
        elide: Text.ElideRight
    }

    StyledText {
        animate: true
        text: Tr.trMarked(root.timeStr)
        color: Colours.palette.outline
        font: Tokens.font.body.small
    }

    StyledRect {
        implicitWidth: pill.implicitWidth + Tokens.padding.large
        implicitHeight: groupCount.implicitHeight + Tokens.padding.extraSmall

        color: root.urgency === NotifData.Critical ? Colours.palette.error : root.pillColour
        radius: Tokens.rounding.full

        StateLayer {
            color: root.urgency === NotifData.Critical ? Colours.palette.onError : Colours.palette.onSurface
            disabled: !root.expandable
            onClicked: root.toggle()
        }

        RowLayout {
            id: pill

            anchors.centerIn: parent
            spacing: Tokens.spacing.extraSmall

            StyledText {
                id: groupCount

                Layout.leftMargin: Tokens.padding.extraSmall / 2
                Layout.rightMargin: root.expandable ? 0 : Tokens.padding.extraSmall / 2
                animate: true
                text: root.count
                color: root.urgency === NotifData.Critical ? Colours.palette.onError : Colours.palette.onSurfaceVariant
                font: Tokens.font.body.small
            }

            MaterialIcon {
                Layout.rightMargin: -Tokens.padding.extraSmall / 2
                Layout.topMargin: root.expanded ? -Math.floor(Tokens.padding.extraSmall) : 0
                visible: root.expandable
                text: "expand_more"
                color: root.urgency === NotifData.Critical ? Colours.palette.onError : Colours.palette.onSurfaceVariant
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    Anim {}
                }

                Behavior on Layout.topMargin {
                    Anim {}
                }
            }
        }
    }
}
