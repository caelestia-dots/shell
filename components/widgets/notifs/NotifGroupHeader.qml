import QtQuick
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import Caelestia.Scheme
import qs.components

Item {
    id: root

    required property string appName
    required property bool single
    required property string timeStr
    required property int count
    required property int urgency
    required property color pillColour
    required property bool expandable
    required property bool expanded
    readonly property alias titleWidth: appName.width

    readonly property color expandBtnTextColour: urgency === NotifData.Critical && !single ? Colours.palette.onError : Colours.palette.onSurfaceVariant

    signal toggle

    implicitHeight: Math.max(appName.implicitHeight, time.implicitHeight, pill.implicitHeight)

    StyledText {
        id: appName

        anchors.left: parent.left
        anchors.right: time.left
        anchors.rightMargin: Tokens.spacing.small
        anchors.verticalCenter: parent.verticalCenter

        opacity: root.single && !root.expanded ? 0 : 1
        text: root.appName
        color: Colours.palette.onSurfaceVariant
        font: Tokens.font.body.small
        elide: Text.ElideRight

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    StyledText {
        id: time

        anchors.right: pill.left
        anchors.rightMargin: Tokens.spacing.small
        anchors.verticalCenter: parent.verticalCenter

        animate: true
        text: Tr.trMarked(root.timeStr)
        color: {
            const col = !root.expanded && root.urgency === NotifData.Critical ? Colours.palette.secondary : Colours.palette.outline;
            return root.expanded && !root.single ? Qt.alpha(col, 0) : col;
        }
        font: Tokens.font.body.small
    }

    StyledRect {
        id: pill

        property real horizontalPadding: root.single ? implicitHeight - expandIcon.implicitWidth : Tokens.padding.large
        property real countSpan: root.single ? 0 : groupCount.implicitWidth + Tokens.spacing.extraSmall
        property real iconInset: root.single ? 0 : Tokens.padding.extraSmall / 2

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        implicitWidth: horizontalPadding + countSpan + (root.expandable ? expandIcon.implicitWidth : 0)
        implicitHeight: groupCount.implicitHeight + Tokens.padding.extraSmall

        color: {
            const c = root.urgency === NotifData.Critical ? Colours.palette.error : root.pillColour;
            return root.single ? Qt.alpha(c, 0) : c;
        }
        radius: Tokens.rounding.full

        StateLayer {
            color: root.expandBtnTextColour
            disabled: !root.expandable
            onClicked: root.toggle()
        }

        Item {
            anchors.left: parent.left
            anchors.leftMargin: pill.horizontalPadding / 2 + pill.iconInset
            anchors.verticalCenter: parent.verticalCenter

            implicitWidth: groupCount.implicitWidth
            implicitHeight: groupCount.implicitHeight
            opacity: root.single ? 0 : 1

            StyledText {
                id: groupCount

                animate: true
                text: root.count
                color: root.expandBtnTextColour
                font: Tokens.font.body.small
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        MaterialIcon {
            id: expandIcon

            anchors.right: parent.right
            anchors.rightMargin: pill.horizontalPadding / 2 - pill.iconInset
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.expanded && !root.single ? -Math.floor(Tokens.padding.extraSmall) / 2 : 0

            visible: root.expandable
            text: "expand_more"
            color: root.expandBtnTextColour
            rotation: root.expanded ? 180 : 0

            Behavior on rotation {
                Anim {}
            }

            Behavior on anchors.verticalCenterOffset {
                Anim {}
            }
        }

        Behavior on horizontalPadding {
            Anim {}
        }

        Behavior on countSpan {
            Anim {}
        }

        Behavior on iconInset {
            Anim {}
        }
    }
}
