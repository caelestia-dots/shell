import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property int centerWidth
    required property var lock

    implicitWidth: centerWidth * 0.8
    implicitHeight: input.implicitHeight + Tokens.padding.small

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

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
        onClicked: parent.forceActiveFocus()
    }

    RowLayout {
        id: input

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall
        spacing: Tokens.spacing.medium

        Item {
            Layout.fillHeight: true
            implicitWidth: height

            MaterialIcon {
                id: fprintIcon

                anchors.centerIn: parent
                animate: true
                text: {
                    if (root.lock.pam.fprint.tries >= GlobalConfig.lock.maxFprintTries)
                        return "fingerprint_off";
                    if (root.lock.pam.fprint.active)
                        return "fingerprint";
                    return "lock";
                }
                color: root.lock.pam.fprint.tries >= GlobalConfig.lock.maxFprintTries ? Colours.palette.m3error : Colours.palette.m3onSurface
                opacity: root.lock.pam.passwd.active ? 0 : 1

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            Loader {
                anchors.fill: parent
                anchors.margins: Tokens.padding.small

                active: opacity > 0
                opacity: root.lock.pam.passwd.active ? 1 : 0

                sourceComponent: LoadingIndicator {}

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }

        InputField {
            id: inputField

            Layout.fillWidth: true
            Layout.fillHeight: true

            pam: root.lock.pam
        }

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: enterIcon.implicitHeight + Tokens.padding.small

            color: root.lock.pam.buffer ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
            radius: Tokens.rounding.full

            StateLayer {
                color: root.lock.pam.buffer ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                onClicked: root.lock.pam.passwd.start()
            }

            MaterialIcon {
                id: enterIcon

                anchors.centerIn: parent
                text: "arrow_forward"
                color: root.lock.pam.buffer ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                fontStyle: Tokens.font.icon.size(Tokens.font.icon.large.pointSize).weight(Font.Medium).build()
            }
        }
    }
}
