import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property var deviceDetails

    spacing: Tokens.spacing.extraSmall

    StyledText {
        text: qsTr("IP Address")
    }

    StyledText {
        text: root.deviceDetails?.ipAddress || qsTr("Not available")
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
    }

    StyledText {
        Layout.topMargin: Tokens.spacing.medium
        text: qsTr("Subnet Mask")
    }

    StyledText {
        text: root.deviceDetails?.subnet || qsTr("Not available")
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
    }

    StyledText {
        Layout.topMargin: Tokens.spacing.medium
        text: qsTr("Gateway")
    }

    StyledText {
        text: root.deviceDetails?.gateway || qsTr("Not available")
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
    }

    StyledText {
        Layout.topMargin: Tokens.spacing.medium
        text: qsTr("DNS Servers")
    }

    StyledText {
        text: (root.deviceDetails && root.deviceDetails.dns && root.deviceDetails.dns.length > 0) ? root.deviceDetails.dns.join(", ") : qsTr("Not available")
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
        wrapMode: Text.Wrap
        Layout.maximumWidth: parent.width
    }
}
