pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Column {
    id: root

    required property ScreenState screenState

    padding: Tokens.padding.large
    rightPadding: CUtils.clamp(padding - Config.border.thickness, 0, padding)
    spacing: Tokens.spacing.large

    SessionButton {
        id: logout

        icon: Config.session.icons.logout
        command: Config.session.commands.logout
        label: Tr.tr("Logout")

        KeyNavigation.down: shutdown

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onLauncherChanged(): void {
                if (!root.screenState.launcher)
                    logout.forceActiveFocus();
            }

            target: root.screenState
        }
    }

    SessionButton {
        id: shutdown

        icon: Config.session.icons.shutdown
        command: Config.session.commands.shutdown
        label: Tr.tr("Shutdown")
        accent: Hallownest.grimm

        KeyNavigation.up: logout
        KeyNavigation.down: hibernate
    }

    SessionButton {
        id: hibernate

        icon: Config.session.icons.hibernate
        command: Config.session.commands.hibernate
        label: Tr.tr("Hibernate")
        accent: Hallownest.lifeblood

        KeyNavigation.up: shutdown
        KeyNavigation.down: reboot
    }

    SessionButton {
        id: reboot

        icon: Config.session.icons.reboot
        command: Config.session.commands.reboot
        label: Tr.tr("Reboot")
        accent: Hallownest.gold

        KeyNavigation.up: hibernate
    }

    component SessionButton: Item {
        id: button

        required property string icon
        required property list<string> command
        property string label
        property color accent: Hallownest.soul
        readonly property bool lit: activeFocus || area.containsMouse

        function exec(): void {
            if (!SessionManager.exec(command))
                Quickshell.execDetached(command);
        }

        implicitWidth: Tokens.sizes.session.button
        implicitHeight: Tokens.sizes.session.button
        activeFocusOnTab: true

        Keys.onEnterPressed: exec()

        Keys.onReturnPressed: exec()

        Keys.onEscapePressed: root.screenState.session = false

        Keys.onPressed: event => {
            if (!Config.session.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if ((event.key === Qt.Key_J || event.key === Qt.Key_N) && KeyNavigation.down) {
                    KeyNavigation.down.focus = true;
                    event.accepted = true;
                } else if ((event.key === Qt.Key_K || event.key === Qt.Key_P) && KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab && KeyNavigation.down) {
                KeyNavigation.down.focus = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                if (KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: button.lit ? 22 : 18
            color: button.lit ? Qt.alpha(button.accent, area.pressed ? 0.22 : 0.13) : Hallownest.card
            border.width: 1
            border.color: button.lit ? Qt.alpha(button.accent, 0.6) : Hallownest.border
            scale: area.pressed ? 0.95 : 1

            Behavior on radius {
                Anim {}
            }

            Behavior on color {
                CAnim {}
            }

            Behavior on scale {
                Anim {
                    type: Anim.FastSpatial
                }
            }

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -7
                text: button.icon
                color: button.lit ? button.accent : Hallownest.subtext
                fill: button.lit ? 1 : 0
                fontStyle: Tokens.font.icon.builders.large.scale(1.2).build()
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 9
                text: button.label
                color: button.lit ? Hallownest.soul : Hallownest.faint
                font.pointSize: 8
                font.weight: Font.DemiBold
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
            }
        }

        Item {
            anchors.right: parent.left
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            opacity: button.activeFocus ? 1 : 0
            layer.enabled: opacity > 0
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: button.accent
                shadowBlur: 0.7
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
                blurMax: 10
            }

            Rectangle {
                anchors.centerIn: parent
                width: 7
                height: 7
                rotation: 45
                color: button.accent
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: button.forceActiveFocus()
            onClicked: button.exec()
        }
    }
}
