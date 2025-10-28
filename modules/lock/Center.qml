pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.images
import qs.services
import qs.config
import qs.utils
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var lock
    readonly property list<string> timeComponents: Time.format(Config.services.useTwelveHourClock ? "hh:mm:A" : "hh:mm").split(":")
    readonly property real centerScale: Math.min(1, (lock.screen?.height ?? 1440) / 1440)
    readonly property int centerWidth: Config.lock.sizes.centerWidth * centerScale

    Layout.preferredWidth: centerWidth
    Layout.fillWidth: false
    Layout.fillHeight: true

    spacing: Appearance.spacing.large * 2

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Appearance.spacing.small

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: root.timeComponents[0]
            color: Colours.palette.m3secondary
            font.pointSize: Math.floor(Appearance.font.size.extraLarge * 3 * root.centerScale)
            font.family: Appearance.font.family.clock
            font.bold: true
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: ":"
            color: Colours.palette.m3primary
            font.pointSize: Math.floor(Appearance.font.size.extraLarge * 3 * root.centerScale)
            font.family: Appearance.font.family.clock
            font.bold: true
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: root.timeComponents[1]
            color: Colours.palette.m3secondary
            font.pointSize: Math.floor(Appearance.font.size.extraLarge * 3 * root.centerScale)
            font.family: Appearance.font.family.clock
            font.bold: true
        }

        Loader {
            Layout.leftMargin: Appearance.spacing.small
            Layout.alignment: Qt.AlignVCenter

            asynchronous: true
            active: Config.services.useTwelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: root.timeComponents[2] ?? ""
                color: Colours.palette.m3primary
                font.pointSize: Math.floor(Appearance.font.size.extraLarge * 2 * root.centerScale)
                font.family: Appearance.font.family.clock
                font.bold: true
            }
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: -Appearance.padding.large * 2

        text: Time.format("dddd, d MMMM yyyy")
        color: Colours.palette.m3tertiary
        font.pointSize: Math.floor(Appearance.font.size.extraLarge * root.centerScale)
        font.family: Appearance.font.family.mono
        font.bold: true
    }

    StyledClippingRect {
        Layout.topMargin: Appearance.spacing.large * 2
        Layout.alignment: Qt.AlignHCenter

        implicitWidth: root.centerWidth / 2
        implicitHeight: root.centerWidth / 2

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.full

        MaterialIcon {
            anchors.centerIn: parent

            text: "person"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Math.floor(root.centerWidth / 4)
        }

        CachingImage {
            id: pfp

            anchors.fill: parent
            path: `${Paths.home}/.face`
        }
    }

    StyledRect {
        Layout.alignment: Qt.AlignHCenter

        implicitWidth: root.centerWidth * 0.8
        implicitHeight: input.implicitHeight + Appearance.padding.small * 2

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.full

        focus: true
        onActiveFocusChanged: {
            if (!activeFocus)
                forceActiveFocus();
        }

        Keys.onPressed: event => {
            if (root.lock.unlocking)
                return;

            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return)
                inputField.placeholder.animate = false;

            root.lock.pam.handleKey(event);
        }

        StateLayer {
            hoverEnabled: false
            cursorShape: Qt.IBeamCursor

            function onClicked(): void {
                parent.forceActiveFocus();
            }
        }

        RowLayout {
            id: input

            anchors.fill: parent
            anchors.margins: Appearance.padding.small
            spacing: Appearance.spacing.normal

            Item {
                implicitWidth: implicitHeight
                implicitHeight: fprintIcon.implicitHeight + Appearance.padding.small * 2

                MaterialIcon {
                    id: fprintIcon

                    anchors.centerIn: parent
                    animate: true
                    text: {
                        if (root.lock.pam.fprint.tries >= Config.lock.maxFprintTries)
                            return "fingerprint_off";
                        if (root.lock.pam.fprint.active)
                            return "fingerprint";
                        return "lock";
                    }
                    color: root.lock.pam.fprint.tries >= Config.lock.maxFprintTries ? Colours.palette.m3error : Colours.palette.m3onSurface
                    opacity: root.lock.pam.passwd.active ? 0 : 1

                    Behavior on opacity {
                        Anim {}
                    }
                }

                CircularIndicator {
                    anchors.fill: parent
                    running: root.lock.pam.passwd.active
                }
            }

            InputField {
                id: inputField

                pam: root.lock.pam
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: enterIcon.implicitHeight + Appearance.padding.small * 2

                color: root.lock.pam.buffer ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                radius: Appearance.rounding.full

                StateLayer {
                    color: root.lock.pam.buffer ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                    function onClicked(): void {
                        root.lock.pam.passwd.start();
                    }
                }

                MaterialIcon {
                    id: enterIcon

                    anchors.centerIn: parent
                    text: "arrow_forward"
                    color: root.lock.pam.buffer ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    font.weight: 500
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.topMargin: -Appearance.spacing.large

        implicitHeight: Math.max(message.implicitHeight, stateMessage.implicitHeight)

        Behavior on implicitHeight {
            Anim {}
        }

        StyledText {
            id: stateMessage

            readonly property string msg: {
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

            property bool shouldBeVisible

            onMsgChanged: {
                if (msg) {
                    if (opacity > 0) {
                        animate = true;
                        text = msg;
                        animate = false;
                    } else {
                        text = msg;
                    }
                    shouldBeVisible = true;
                } else {
                    shouldBeVisible = false;
                }
            }

            anchors.left: parent.left
            anchors.right: parent.right

            scale: shouldBeVisible && !message.msg ? 1 : 0.7
            opacity: shouldBeVisible && !message.msg ? 1 : 0
            color: Colours.palette.m3onSurfaceVariant
            animateProp: "opacity"

            font.family: Appearance.font.family.mono
            horizontalAlignment: Qt.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            lineHeight: 1.2

            Behavior on scale {
                Anim {}
            }

            Behavior on opacity {
                Anim {}
            }
        }

        StyledText {
            id: message

            readonly property Pam pam: root.lock.pam
            readonly property string msg: {
                if (pam.fprintState === "error")
                    return qsTr("FP ERROR: %1").arg(pam.fprint.message);
                if (pam.state === "error")
                    return qsTr("PW ERROR: %1").arg(pam.passwd.message);

                if (pam.lockMessage)
                    return pam.lockMessage;

                if (pam.state === "max" && pam.fprintState === "max")
                    return qsTr("Maximum password and fingerprint attempts reached.");
                if (pam.state === "max") {
                    if (pam.fprint.available)
                        return qsTr("Maximum password attempts reached. Please use fingerprint.");
                    return qsTr("Maximum password attempts reached.");
                }
                if (pam.fprintState === "max")
                    return qsTr("Maximum fingerprint attempts reached. Please use password.");

                if (pam.state === "fail") {
                    if (pam.fprint.available)
                        return qsTr("Incorrect password. Please try again or use fingerprint.");
                    return qsTr("Incorrect password. Please try again.");
                }
                if (pam.fprintState === "fail")
                    return qsTr("Fingerprint not recognized (%1/%2). Please try again or use password.").arg(pam.fprint.tries).arg(Config.lock.maxFprintTries);

                return "";
            }

            anchors.left: parent.left
            anchors.right: parent.right

            scale: 0.7
            opacity: 0
            color: Colours.palette.m3error

            font.pointSize: Appearance.font.size.small
            font.family: Appearance.font.family.mono
            horizontalAlignment: Qt.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            onMsgChanged: {
                if (msg) {
                    if (opacity > 0) {
                        animate = true;
                        text = msg;
                        animate = false;

                        exitAnim.stop();
                        if (scale < 1)
                            appearAnim.restart();
                        else
                            flashAnim.restart();
                    } else {
                        text = msg;
                        exitAnim.stop();
                        appearAnim.restart();
                    }
                } else {
                    appearAnim.stop();
                    flashAnim.stop();
                    exitAnim.start();
                }
            }

            Connections {
                target: root.lock.pam

                function onFlashMsg(): void {
                    exitAnim.stop();
                    if (message.scale < 1)
                        appearAnim.restart();
                    else
                        flashAnim.restart();
                }
            }

            Anim {
                id: appearAnim

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
                    duration: Appearance.anim.durations.large
                }
                Anim {
                    target: message
                    property: "opacity"
                    to: 0
                    duration: Appearance.anim.durations.large
                }
            }
        }
    }

    component FlashAnim: NumberAnimation {
        target: message
        property: "opacity"
        duration: Appearance.anim.durations.small
        easing.type: Easing.Linear
    }
}
