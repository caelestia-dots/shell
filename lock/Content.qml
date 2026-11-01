import QtQuick

Item {
    id: root

    required property Pam pam

    property string error

    Connections {
        function onFailed(message: string): void {
            root.error = message;
            input.text = "";
            input.forceActiveFocus();
        }

        target: root.pam
    }

    Rectangle {
        anchors.fill: parent
        color: "#101014"
    }

    Column {
        anchors.centerIn: parent
        spacing: 16

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#eeeeee"
            font.pixelSize: 28
            text: "Caelestia"
        }

        TextInput {
            id: input

            width: 320
            height: 48
            color: "#eeeeee"
            echoMode: TextInput.Password
            focus: true
            font.pixelSize: 20
            horizontalAlignment: TextInput.AlignHCenter
            selectionColor: "#4a90d9"

            Component.onCompleted: forceActiveFocus()

            onAccepted: {
                if (text.length === 0)
                    return;
                root.pam.submit(text);
                text = "";
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -8
                border.color: "#555555"
                border.width: 1
                color: "transparent"
                radius: 8
                z: -1
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#ff6b6b"
            font.pixelSize: 13
            text: root.error
            visible: text.length > 0
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#888888"
            font.pixelSize: 12
            text: "Press Enter to unlock"
        }
    }
}
