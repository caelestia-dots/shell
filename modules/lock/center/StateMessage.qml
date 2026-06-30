pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.lock

Item {
    id: root

    required property Pam pam

    readonly property string msg: {
        // Errors
        if (pam.fprint.state === Pam.Error)
            return qsTr("FP ERROR: %1").arg(pam.fprint.message);
        if (pam.howdy.state === Pam.Error)
            return qsTr("FACE ERROR: %1").arg(pam.howdy.message);
        if (pam.state === Pam.Error)
            return qsTr("PW ERROR: %1").arg(pam.passwd.message);

        // Fprint/howdy fail
        if (pam.state !== Pam.MaxTries) {
            if (pam.fprint.state === Pam.Failed)
                return qsTr("Fingerprint not recognized (%1/%2). Please try again or use password.").arg(pam.fprint.tries).arg(GlobalConfig.lock.maxFprintTries);
            if (pam.howdy.state === Pam.Failed)
                return qsTr("Face not recognized (%1/%2). Please try again or use password.").arg(pam.howdy.tries).arg(GlobalConfig.lock.maxHowdyTries);
        } else {
            if (pam.fprint.state === Pam.Failed)
                return qsTr("Fingerprint not recognized (%1/%2). Please try again.").arg(pam.fprint.tries).arg(GlobalConfig.lock.maxFprintTries);
            if (pam.howdy.state === Pam.Failed)
                return qsTr("Face not recognized (%1/%2). Please try again.").arg(pam.howdy.tries).arg(GlobalConfig.lock.maxHowdyTries);
        }

        if (pam.lockMessage) // Password max tries message
            return pam.lockMessage;

        // Password fail
        if (pam.state === Pam.Failed) {
            if (pam.fprint.available && pam.fprint.state !== Pam.MaxTries)
                return qsTr("Incorrect password. Please try again or use fingerprint.");
            if (pam.howdy.available && pam.howdy.state !== Pam.MaxTries)
                return qsTr("Incorrect password. Please try again or use face.");
            return qsTr("Incorrect password. Please try again.");
        }

        // Maxed out
        if (pam.state === Pam.MaxTries) {
            if (pam.fprint.available && pam.fprint.state !== Pam.MaxTries)
                return qsTr("Maximum password attempts reached. Please use fingerprint.");
            if (pam.howdy.available && pam.howdy.state !== Pam.MaxTries)
                return qsTr("Maximum password attempts reached. Please use face.");
            if (pam.fprint.available || pam.howdy.available)
                return qsTr("Maximum attempts for all authentication methods reached.");
            return qsTr("Maximum password attempts reached.");
        }
        if (pam.fprint.state === Pam.MaxTries)
            return qsTr("Maximum fingerprint attempts reached. Please use password.");
        if (pam.howdy.state === Pam.MaxTries)
            return qsTr("Maximum face attempts reached. Please use password.");

        return "";
    }

    readonly property string stateMsg: {
        if (Hypr.kbLayout !== Hypr.defaultKbLayout) {
            if (Hypr.capsLock && Hypr.numLock)
                return qsTr("Caps lock and Num lock are ON.\nKeyboard layout: %1").arg(Hypr.kbLayoutFull);
            if (Hypr.capsLock)
                return qsTr("Caps lock is ON. Kb layout: %1").arg(Hypr.kbLayoutFull);
            if (Hypr.numLock)
                return qsTr("Num lock is ON. Kb layout: %1").arg(Hypr.kbLayoutFull);
            return qsTr("Keyboard layout: %1").arg(Hypr.kbLayoutFull);
        }

        if (Hypr.capsLock && Hypr.numLock)
            return qsTr("Caps lock and Num lock are ON.");
        if (Hypr.capsLock)
            return qsTr("Caps lock is ON.");
        if (Hypr.numLock)
            return qsTr("Num lock is ON.");

        return "";
    }

    property bool stateMsgShouldBeVisible

    onMsgChanged: {
        if (msg) {
            if (message.opacity > 0) {
                message.animate = true;
                message.text = msg;
                message.animate = false;

                exitAnim.stop();
                if (message.scale < 1)
                    appearAnim.restart();
                else
                    flashAnim.restart();
            } else {
                message.text = msg;
                exitAnim.stop();
                appearAnim.restart();
            }
        } else {
            appearAnim.stop();
            flashAnim.stop();
            exitAnim.start();
        }
    }

    onStateMsgChanged: {
        if (stateMsg) {
            if (stateMessage.opacity > 0) {
                stateMessage.animate = true;
                stateMessage.text = stateMsg;
                stateMessage.animate = false;
            } else {
                stateMessage.text = stateMsg;
            }
            stateMsgShouldBeVisible = true;
        } else {
            stateMsgShouldBeVisible = false;
        }
    }

    implicitHeight: Math.max(message.implicitHeight, stateMessage.implicitHeight)

    Behavior on implicitHeight {
        Anim {}
    }

    StyledText {
        id: stateMessage

        anchors.left: parent.left
        anchors.right: parent.right

        scale: root.stateMsgShouldBeVisible && !root.msg ? 1 : 0.7
        opacity: root.stateMsgShouldBeVisible && !root.msg ? 1 : 0
        color: Colours.palette.m3onSurfaceVariant

        font: Tokens.font.body.small
        horizontalAlignment: Qt.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        lineHeight: 1.2

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    StyledText {
        id: message

        anchors.left: parent.left
        anchors.right: parent.right

        scale: 0.7
        opacity: 0
        color: Colours.palette.m3error

        font: Tokens.font.body.small
        horizontalAlignment: Qt.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

        Connections {
            function onFlashMsg(): void {
                exitAnim.stop();
                if (message.scale < 1)
                    appearAnim.restart();
                else
                    flashAnim.restart();
            }

            target: root.pam
        }

        Anim {
            id: appearAnim

            type: Anim.DefaultEffects
            target: message
            properties: "scale,opacity"
            to: 1
            onFinished: flashAnim.restart()
        }

        SequentialAnimation {
            id: flashAnim

            loops: 2

            FlashAnim {
                to: 0.3
            }
            FlashAnim {
                to: 1
            }
        }

        ParallelAnimation {
            id: exitAnim

            Anim {
                target: message
                property: "scale"
                to: 0.7
                type: Anim.StandardLarge
            }
            Anim {
                target: message
                property: "opacity"
                to: 0
                type: Anim.StandardLarge
            }
        }
    }

    component FlashAnim: NumberAnimation {
        target: message
        property: "opacity"
        duration: Tokens.anim.durations.small
        easing.type: Easing.Linear
    }
}
