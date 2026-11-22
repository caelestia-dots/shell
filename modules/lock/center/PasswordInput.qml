pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property real centerScale
    required property int centerWidth
    required property var lock

    function isArrow(key: int): bool {
        return key === Qt.Key_Up || key === Qt.Key_Down || key === Qt.Key_Left || key === Qt.Key_Right;
    }

    implicitWidth: {
        const w = centerWidth * 0.8;
        return lock.pam.buffer ? w : Math.min(w, inputField.placeholderWidth + iconWrapper.implicitWidth + enterButton.implicitWidth + input.spacing * 2 + Tokens.padding.medium * 2);
    }
    implicitHeight: input.implicitHeight + Tokens.padding.small

    color: Hallownest.card
    radius: Tokens.rounding.full
    border.width: 1
    border.color: Hallownest.border

    focus: true
    onActiveFocusChanged: {
        if (!activeFocus)
            forceActiveFocus();
    }

    Keys.onPressed: event => {
        if (root.lock.unlocking)
            return;

        // Arrows never reach the password, so they control the lock screen games
        if (root.isArrow(event.key)) {
            root.lock.gameKey(event.key, true, event.isAutoRepeat);
            return;
        }

        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return)
            inputField.placeholder.animate = false;

        root.lock.pam.handleKey(event);
    }
    Keys.onReleased: event => {
        if (root.isArrow(event.key) && !event.isAutoRepeat)
            root.lock.gameKey(event.key, false, false);
    }

    Behavior on implicitWidth {
        Anim {}
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
            id: iconWrapper

            Layout.fillHeight: true
            implicitWidth: height

            AnimLoader {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: sourceComponent === iconComp ? 1 : 0
                sourceComp: root.lock.pam.passwd.active || root.lock.pam.howdy.active ? loadingComp : iconComp
            }

            Component {
                id: iconComp

                MaterialIcon {
                    animate: true
                    text: {
                        if (inputField.showPassword)
                            return "visibility";
                        if (root.lock.pam.fprint.tries >= GlobalConfig.lock.maxFprintTries) {
                            if (root.lock.pam.howdy.canAttempt)
                                return "face";
                            return "fingerprint_off";
                        }
                        if (root.lock.pam.fprint.active)
                            return "fingerprint";
                        if (root.lock.pam.howdy.canAttempt)
                            return "face";
                        return "lock";
                    }
                    color: !root.lock.pam.howdy.canAttempt && root.lock.pam.fprint.tries >= GlobalConfig.lock.maxFprintTries ? Hallownest.grimm : Hallownest.subtext
                    fontStyle: Tokens.font.icon.builders.medium.scale(root.centerScale).build()
                    fill: text === "face" || text === "visibility"

                    StateLayer {
                        anchors.fill: undefined
                        anchors.centerIn: parent
                        implicitWidth: {
                            const w = parent.implicitHeight + Tokens.padding.small * 2;
                            return w + (w % 2);
                        }
                        implicitHeight: implicitWidth
                        radius: Tokens.rounding.full

                        onClicked: {
                            parent.animate = false;
                            inputField.showPassword = !inputField.showPassword;
                            parent.animate = true;
                        }
                    }
                }
            }

            Component {
                id: loadingComp

                LoadingIndicator {
                    implicitSize: iconWrapper.height - Tokens.padding.small * 2
                }
            }
        }

        InputField {
            id: inputField

            Layout.fillWidth: true
            Layout.fillHeight: true

            centerScale: root.centerScale
            pam: root.lock.pam
        }

        Item {
            id: enterButton

            implicitWidth: implicitHeight
            implicitHeight: {
                const h = enterIcon.implicitHeight + Tokens.padding.extraSmall * 2;
                return h % 2 === 0 ? h : h + 1;
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4

                radius: 6
                color: root.lock.pam.buffer ? Hallownest.soul : Hallownest.button
                border.width: 1
                border.color: root.lock.pam.buffer ? Hallownest.soul : Hallownest.border
                scale: mouse.pressed ? 0.85 : mouse.containsMouse ? 1.05 : 1
                rotation: 45

                Behavior on scale {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }

                Behavior on color {
                    CAnim {}
                }

                MouseArea {
                    id: mouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: root.lock.pam.buffer ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.lock.pam.buffer && root.lock.pam.passwd.start()
                }
            }

            MaterialIcon {
                id: enterIcon

                anchors.centerIn: parent
                text: "arrow_forward"
                color: root.lock.pam.buffer ? Hallownest.void_ : Hallownest.subtext
                fontStyle: Tokens.font.icon.builders.medium.scale(root.centerScale).build()

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }
    }
}
