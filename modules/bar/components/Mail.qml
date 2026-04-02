pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.components.misc
import qs.services
import qs.config
import qs.utils

StyledRect {
    id: root

    property color colour: Colours.palette.m3secondary
    readonly property alias items: mailColumn

    color: Colours.tPalette.m3surfaceContainer
    radius: Appearance.rounding.full

    clip: true
    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: mailColumn.implicitHeight + Appearance.padding.normal * 2
 
    visible: Config.bar.mail.enabled
    enabled: Config.bar.mail.enabled

    StateLayer {
        // Cursed workaround to make the height larger than the parent
        function onClicked(): void {
            Quickshell.execDetached(Config.bar.mail.clickCommand);
        }

        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight
        radius: Appearance.rounding.full
    }

    ColumnLayout {
        id: mailColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Appearance.padding.normal

        spacing: 0

        WrappedLoader {
            name: "mail"
            active: root.visible

            sourceComponent: MaterialIcon {
                animate: true
                text: Icons.getMailIcon(MailService.unreadEmails.length)
                color: root.colour
            }
        }

        StyledText {
            id: mailText

            visible: Config.bar.mail.showNumber

            Layout.alignment: Qt.AlignHCenter

            text: qsTr("%1").arg(MailService.unreadEmails.length)
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono
            color: Colours.palette.m3tertiary
        }
    }

    component WrappedLoader: Loader {
        required property string name

        asynchronous: true
        Layout.alignment: Qt.AlignHCenter
        visible: active
    }
}

// Item {
//     id: root
//
//     readonly property int padding: Appearance.padding.small
//
//     implicitWidth: Config.bar.sizes.innerWidth
//     // implicitHeight: Config.bar.mail.enabled ? icon.implicitHeight + mailText.implicitHeight : 0
//     implicitHeight: layout.implicitHeight + root.padding * 2
//     // implicitWidth: Config.bar.sizes.innerWidth
//     // implicitHeight: layout.implicitHeight + root.padding * 2
//     visible: Config.bar.mail.enabled
//     enabled: Config.bar.mail.enabled
//
//     StateLayer {
//         // Cursed workaround to make the height larger than the parent
//         function onClicked(): void {
//             Quickshell.execDetached(Config.bar.mail.clickCommand);
//         }
//
//         anchors.fill: undefined
//         anchors.centerIn: parent
//         implicitWidth: root.implicitWidth + Appearance.padding.small * 2
//         implicitHeight: icon.implicitHeight + Appearance.padding.small * 2
//
//         radius: Appearance.rounding.full
//     }
//
//     Column {
//         id: layout
//
//         spacing: Appearance.spacing.small
//         anchors.horizontalCenter: parent.horizontalCenter
//
//         Ref {
//             service: MailService
//         }
//
//         Loader {
//             asynchronous: true
//             anchors.horizontalCenter: parent.horizontalCenter
//
//             active: true
//             visible: active
//
//             sourceComponent: MaterialIcon {
//                 text: "mail"
//                 color: root.colour
//             }
//         }
//         //
//         // MaterialIcon {
//         //     id: icon
//         //
//         //     animate: true
//         //
//         //     text: "mail"
//         //     color: Colours.palette.m3tertiary
//         //
//         //     anchors.horizontalCenter: parent.horizontalCenter
//         // }
//
//         StyledText {
//             id: mailText
//
//             anchors.horizontalCenter: parent.horizontalCenter
//
//             horizontalAlignment: StyledText.AlignHCenter
//             text: qsTr("%1").arg(MailService.unreadEmails.length)
//             font.pointSize: Appearance.font.size.smaller
//             font.family: Appearance.font.family.mono
//             color: Colours.palette.m3tertiary
//         }
//     }
// }
