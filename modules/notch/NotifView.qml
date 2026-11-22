pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.services
import qs.utils

// Notification or shell toast shown inside the collapsed notch
Item {
    id: root

    property NotifData notif
    property Toast toast
    property int pending

    readonly property bool critical: notif ? notif.urgency === NotificationUrgency.Critical : toast?.type === Toast.Error
    readonly property color accent: {
        if (critical)
            return Hallownest.grimm;
        if (!toast)
            return Hallownest.soul;
        if (toast.type === Toast.Success)
            return Hallownest.unn;
        if (toast.type === Toast.Warning)
            return Hallownest.gold;
        return Hallownest.soul;
    }
    readonly property string title: notif?.summary ?? (toast ? Tr.trMarked(toast.title) : "")
    readonly property string message: notif?.body ?? (toast ? Tr.trMarked(toast.message) : "")
    readonly property bool hasImage: (notif?.image.length ?? 0) > 0
    readonly property bool hasAppIcon: (notif?.appIcon.length ?? 0) > 0
    // Like an NPC: the app (or the shell) is the speaker, its words are typed out
    readonly property string speaker: notif ? (notif.appName || title) : "PaleShell"
    readonly property string speech: {
        const body = message.replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
        if (!notif)
            return body ? `${title} · ${body}` : title;
        return body && title !== speaker ? `${title} · ${body}` : body || title;
    }
    property int typed

    function dismiss(): void {
        if (notif)
            notif.popup = false;
        else
            toast?.close();
    }

    implicitWidth: Math.min(480, Math.max(340, dialog.implicitWidth))
    implicitHeight: dialog.implicitHeight

    Component.onCompleted: typeAnim.restart()
    onSpeechChanged: typeAnim.restart()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onEntered: root.notif?.timer.stop()
        onExited: root.notif?.timer.start()
        onClicked: event => {
            if (event.button === Qt.MiddleButton) {
                if (root.notif)
                    root.notif.close();
                else
                    root.dismiss();
                return;
            }
            const actions = root.notif?.actions ?? [];
            if (actions.length === 1)
                actions[0].invoke();
            root.dismiss();
        }
    }

    // A Timer, not an animation: animations only advance when the compositor asks the notch for frames
    Timer {
        id: typeAnim

        function restart(): void {
            if (!NotchSettings.values.animTyping) {
                stop();
                root.typed = root.speech.length;
                return;
            }
            root.typed = 0;
            start();
        }

        interval: Math.max(8, Math.min(22, 1200 / Math.max(1, root.speech.length)))
        repeat: true
        onTriggered: {
            root.typed += 1;
            if (root.typed >= root.speech.length)
                stop();
        }
    }

    ColumnLayout {
        id: dialog

        anchors.fill: parent
        spacing: 4

        Ornament {
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Rectangle {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                radius: 9
                color: Qt.alpha(root.accent, 0.12)
                clip: true

                Image {
                    anchors.fill: parent
                    visible: root.hasImage
                    source: root.hasImage ? Qt.resolvedUrl(root.notif.image) : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 36
                    sourceSize.height: 36
                    asynchronous: true
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 14
                    visible: !root.hasImage && root.hasAppIcon
                    source: root.hasAppIcon ? Icons.iconPath(root.notif.appIcon) : ""
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: !root.hasImage && !root.hasAppIcon
                    text: root.notif ? Icons.getNotifIcon(root.notif.summary, root.notif.urgency) : (root.toast?.icon || "info")
                    color: root.accent
                    fontStyle: Tokens.font.icon.small
                }
            }

            StyledText {
                text: root.speaker
                color: root.accent
                font.family: Hallownest.serif
                font.pointSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1
            }

            StyledText {
                visible: root.pending > 0
                text: `+${root.pending}`
                color: Hallownest.subtext
                font.family: Hallownest.mono
                font.pointSize: 8
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 400
            horizontalAlignment: Text.AlignHCenter
            text: root.speech.slice(0, root.typed)
            color: root.critical ? Hallownest.grimm : Hallownest.text
            font.family: Hallownest.bodySerif
            font.pointSize: 9.5
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            visible: (root.notif?.actions.length ?? 0) > 0
            spacing: Tokens.spacing.small

            Repeater {
                model: (root.notif?.actions ?? []).slice(0, 3)

                HkButton {
                    required property var modelData

                    text: modelData.text
                    tinted: true
                    accent: root.accent
                    onClicked: {
                        modelData.invoke();
                        root.dismiss();
                    }
                }
            }
        }

        Ornament {
            Layout.fillWidth: true
            lower: true
        }
    }

    MaterialIcon {
        anchors.top: parent.top
        anchors.right: parent.right
        text: "close"
        color: closeArea.containsMouse ? Hallownest.soul : Hallownest.faint
        fontStyle: Tokens.font.icon.small

        MouseArea {
            id: closeArea

            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.dismiss()
        }
    }

    // Dialogue-box border: fading lines around a diamond; the bottom one has the bobbing "continue" arrow
    component Ornament: Item {
        id: ornament

        property bool lower

        implicitHeight: 10

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: diamond.left
            anchors.rightMargin: 4
            width: parent.width * 0.36
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: "transparent"
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(root.accent, 0.6)
                }
            }
        }

        Rectangle {
            id: diamond

            anchors.centerIn: parent
            width: 6
            height: 6
            rotation: 45
            color: ornament.lower ? "transparent" : Qt.alpha(root.accent, 0.8)
            border.width: 1
            border.color: root.accent
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: diamond.right
            anchors.leftMargin: 4
            width: parent.width * 0.36
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: Qt.alpha(root.accent, 0.6)
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }
        }

        MaterialIcon {
            id: arrow

            property real bob

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: bob * 2
            visible: ornament.lower && root.typed >= root.speech.length
            text: "arrow_drop_down"
            color: root.accent
            fontStyle: Tokens.font.icon.medium

            SequentialAnimation on bob {
                running: arrow.visible
                loops: Animation.Infinite

                NumberAnimation {
                    to: 1
                    duration: 450
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: -1
                    duration: 450
                    easing.type: Easing.InOutSine
                }
            }
        }
    }
}
