// qmllint disable unqualified

import QtQuick 2.15
import QtQuick.Window 2.15

Item {
    id: loginRoot

    property string user: userPanel.username
    property string password: passwordField.text
    property int session: sessionPanel.session
    property double inputHeight: 52 * config.Scale
    property double contentWidth: Math.min(620 * config.Scale, parent.width - 48)
    property double inputWidth: Math.min(360 * config.Scale, contentWidth)

    function login() {
        if (user !== "" && password !== "")
            sddm.login(user, password, session);
    }

    Row {
        spacing: 12
        anchors {
            bottom: parent.bottom
            left: parent.left
            margins: 24 * config.Scale
        }

        PowerPanel {}
        SessionPanel {
            id: sessionPanel
        }
    }

    // Mirror Caelestia's lockscreen hierarchy: time, date, then credentials.
    Column {
        id: lockContent

        width: contentWidth
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: Math.max(32 * config.Scale, parent.height * 0.10)
        }
        spacing: 14 * config.Scale

        DateTimePanel {
            id: clock

            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item {
            width: 1
            height: Math.max(22 * config.Scale, loginRoot.height * 0.07)
        }

        UserPanel {
            id: userPanel

            width: inputWidth
            anchors.horizontalCenter: parent.horizontalCenter
        }

        PasswordPanel {
            id: passwordField

            height: inputHeight
            width: inputWidth
            anchors.horizontalCenter: parent.horizontalCenter
            canSubmit: user !== "" && text !== ""
            submit: loginRoot.login
            onAccepted: loginRoot.login()
        }
    }
}
