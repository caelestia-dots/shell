import qs.components
import qs.components.images
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property WlSessionLockSurface lock
    required property bool fprint
    property int maxFprintTries: 3

    property string passwordBuffer

    spacing: Appearance.spacing.large * 2

    onLockChanged: {
        if (lock && fprint) {
            pamFprint.start();
        }
        if (!lock) {
            pamFprint.abort();
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Appearance.padding.large * 3
        Layout.maximumWidth: Config.lock.sizes.inputWidth - Appearance.rounding.large * 2

        spacing: Appearance.spacing.large

        StyledClippingRect {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: Config.lock.sizes.faceSize
            implicitHeight: Config.lock.sizes.faceSize

            radius: Appearance.rounding.large
            color: Colours.tPalette.m3surfaceContainer

            MaterialIcon {
                anchors.centerIn: parent

                text: "person"
                fill: 1
                grade: 200
                font.pointSize: Config.lock.sizes.faceSize / 2
            }

            CachingImage {
                anchors.fill: parent
                path: `${Paths.stringify(Paths.home)}/.face`
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Welcome back, %1").arg(Quickshell.env("USER"))
                font.pointSize: Appearance.font.size.extraLarge
                font.weight: 500
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Logging in to %1").arg(Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP"))
                color: Colours.palette.m3tertiary
                font.pointSize: Appearance.font.size.large
                elide: Text.ElideRight
            }
        }
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.preferredWidth: charList.implicitWidth + Appearance.padding.large * 2
        Layout.preferredHeight: Appearance.font.size.normal + Appearance.padding.large * 2

        focus: true
        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.small
        clip: true

        onFocusChanged: {
            if (!focus)
                focus = true;
        }

        Keys.onPressed: event => {
            if (pamPwd.active)
                return;

            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                placeholder.animate = false;
                pamPwd.start();
            } else if (event.key === Qt.Key_Backspace) {
                if (event.modifiers & Qt.ControlModifier) {
                    charList.implicitWidth = charList.implicitWidth; // Break binding
                    root.passwordBuffer = "";
                } else {
                    root.passwordBuffer = root.passwordBuffer.slice(0, -1);
                }
            } else if (" abcdefghijklmnopqrstuvwxyz1234567890`~!@#$%^&*()-_=+[{]}\\|;:'\",<.>/?".includes(event.text.toLowerCase())) {
                charList.bindImWidth();
                root.passwordBuffer += event.text;
            }
        }

        PamContext {
            id: pamFprint

            active: true
            property int nbTries: 0

            config: "caelestia"
            // to use fingerptint connection, your `caelestia` file should contains:
            // auth required pam_fprintd.so max-tries=1

            onCompleted: res => {
                if (res === PamResult.Success) {
                    return root.lock.unlock();
                }
                if (res === PamResult.Error) {
                    start();
                    return;
                }
                if (res === PamResult.Failed) {
                    placeholder.pamState = "fail";
                    return;
                }
                if (res === PamResult.MaxTries) {
                    // as pam doesn't trigger the result until all tries are done, we put only one in the config.
                    // Then, when the max tries is reached (here 3 but arbitrary), we dont restart this pam context
                    nbTries += 1;
                    if (nbTries < root.maxFprintTries)
                        start();
                    if (nbTries >= root.maxFprintTries)
                        placeholder.pamState = "maxFprint";
                    icon.color = Colours.palette.m3error;
                }
            }
        }
        Timer {
            id: iconColorTrigger
            running: icon.color === Colours.palette.m3error
            interval: 250
            repeat: false
            onTriggered: {
                icon.animate = true;
                icon.color = Colours.palette.m3outline;
                icon.animate = false;
            }
        }

        PamContext {
            id: pamPwd

            config: "login" // default

            onResponseRequiredChanged: {
                if (!responseRequired)
                    return;

                respond(root.passwordBuffer);
                charList.implicitWidth = charList.implicitWidth; // Break binding
                root.passwordBuffer = "";
                placeholder.animate = true;
            }

            onCompleted: res => {
                if (res === PamResult.Success)
                    return root.lock.unlock();

                if (res === PamResult.Error)
                    placeholder.pamState = "error";
                else if (res === PamResult.MaxTries)
                    placeholder.pamState = "maxPwd";
                else if (res === PamResult.Failed)
                    placeholder.pamState = "fail";

                placeholderDelay.restart();
            }
        }

        Timer {
            id: placeholderDelay

            interval: 3000
            onTriggered: placeholder.pamState = ""
        }

        StyledText {
            id: placeholder

            property string pamState

            anchors.centerIn: parent

            text: {
                if (pamPwd.active) {
                    return qsTr("Loading...");
                }
                if (pamState === "error")
                    return qsTr("An error occured");
                if (pamState === "maxPwd")
                    return qsTr("You have reached the maximum number of tries");
                if (pamState === "maxFprint")
                    return qsTr("Fingerprint failed, try using password");
                if (pamState === "fail")
                    return qsTr("Incorrect password");
                return qsTr("Enter your password");
            }

            animate: true
            color: pamPwd.active ? Colours.palette.m3secondary : pamState ? Colours.palette.m3error : Colours.palette.m3outline
            font.pointSize: Appearance.font.size.larger

            opacity: root.passwordBuffer ? 0 : 1

            Behavior on opacity {
                Anim {}
            }
        }

        ListView {
            id: charList

            function bindImWidth(): void {
                imWidthBehavior.enabled = false;
                implicitWidth = Qt.binding(() => Math.min(count * (Appearance.font.size.normal + spacing) - spacing, Config.lock.sizes.inputWidth - Appearance.rounding.large * 2 - Appearance.padding.large * 5));
                imWidthBehavior.enabled = true;
            }

            anchors.centerIn: parent

            implicitWidth: Math.min(count * (Appearance.font.size.normal + spacing) - spacing, Config.lock.sizes.inputWidth - Appearance.rounding.large * 2 - Appearance.padding.large * 5)
            implicitHeight: Appearance.font.size.normal

            orientation: Qt.Horizontal
            spacing: Appearance.spacing.small / 2
            interactive: false

            model: ScriptModel {
                values: root.passwordBuffer.split("")
            }

            delegate: StyledRect {
                id: ch

                implicitWidth: Appearance.font.size.normal
                implicitHeight: Appearance.font.size.normal

                color: Colours.palette.m3onSurface
                radius: Appearance.rounding.full

                opacity: 0
                scale: 0.5
                Component.onCompleted: {
                    opacity = 1;
                    scale = 1;
                }
                ListView.onRemove: removeAnim.start()

                SequentialAnimation {
                    id: removeAnim

                    PropertyAction {
                        target: ch
                        property: "ListView.delayRemove"
                        value: true
                    }
                    ParallelAnimation {
                        Anim {
                            target: ch
                            property: "opacity"
                            to: 0
                        }
                        Anim {
                            target: ch
                            property: "scale"
                            to: 0.5
                        }
                    }
                    PropertyAction {
                        target: ch
                        property: "ListView.delayRemove"
                        value: false
                    }
                }

                Behavior on opacity {
                    Anim {}
                }

                Behavior on scale {
                    Anim {}
                }
            }

            Behavior on implicitWidth {
                id: imWidthBehavior

                Anim {}
            }
        }

        MaterialIcon {
            id: icon

            text: root.fprint && pamFprint.active ? 'fingerprint' : !root.lock.locked ? 'lock_open_right' : 'password'

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 12

            color: Colours.palette.m3outline
            font.pointSize: Appearance.font.size.larger

            animate: false
            animateProp: 'color'
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
