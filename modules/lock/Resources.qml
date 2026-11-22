pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.widgets
import qs.components.hallownest
import qs.services
import qs.utils

StyledRect {
    id: root

    readonly property bool sessionControlsShown: GlobalConfig.lock.enableSessionControls && hover.hovered
    readonly property real fontScale: {
        const diff = width / 391 - 1; // 391 is the width at 1080 height screen
        return 1 + Math.pow(Math.abs(diff), 0.8) * Math.sign(diff);
    }

    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.extraLarge
    color: Hallownest.card
    border.width: 1
    border.color: Hallownest.border

    ServiceRef {
        service: Cpu
    }

    ServiceRef {
        service: Memory
    }

    ServiceRef {
        service: Storage
    }

    HoverHandler {
        id: hover

        enabled: GlobalConfig.lock.enableSessionControls
    }

    Item {
        anchors.fill: parent
        clip: true

        Item {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large

            Translate {
                id: resourcesTranslate

                y: root.sessionControlsShown ? root.height : 0

                Behavior on y {
                    Anim {}
                }
            }

            Translate {
                id: buttonsTranslate

                y: root.sessionControlsShown ? 0 : -root.height

                Behavior on y {
                    Anim {}
                }
            }

            RowLayout {
                id: layout

                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Tokens.spacing.large

                transform: resourcesTranslate
                opacity: root.sessionControlsShown ? 0 : 1

                Behavior on opacity {
                    Anim {}
                }

                Resource {
                    icon: "memory"
                    value: Strings.percentOne(Cpu.percentage)
                    fillValue: Cpu.percentage
                    colour: Hallownest.lifeblood
                    badge: Units.formatSensorTemp(Cpu.temperature)
                    badgeAlert: Cpu.temperature > 90
                }

                Resource {
                    icon: "memory_alt"
                    value: Strings.percentOne(Memory.percentage)
                    fillValue: Memory.percentage
                    colour: Hallownest.gold
                }

                Resource {
                    icon: "hard_disk"
                    value: Strings.percentOne(Storage.percentage)
                    fillValue: Storage.percentage
                    colour: Hallownest.unn
                }
            }

            RowLayout {
                id: buttonsLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.large

                transform: buttonsTranslate
                opacity: root.sessionControlsShown ? 1 : 0

                Behavior on opacity {
                    Anim {}
                }

                SessionButton {
                    icon: Config.session.icons.logout
                    command: Config.session.commands.logout
                }
                SessionButton {
                    icon: Config.session.icons.shutdown
                    command: Config.session.commands.shutdown
                }
                SessionButton {
                    icon: Config.session.icons.hibernate
                    command: Config.session.commands.hibernate
                }
                SessionButton {
                    icon: Config.session.icons.reboot
                    command: Config.session.commands.reboot
                }
            }
        }
    }

    component SessionButton: IconButton {
        id: button

        required property list<string> command

        function exec(): void {
            if (!SessionManager.exec(command))
                Quickshell.execDetached(command);
        }

        Layout.fillWidth: true
        Layout.preferredHeight: width

        inactiveColour: activeFocus ? Qt.alpha(Hallownest.soul, 0.16) : Hallownest.button
        inactiveOnColour: activeFocus ? Hallownest.soul : Hallownest.text
        radius: pressed ? Tokens.rounding.medium : activeFocus ? Tokens.rounding.extraLarge : Tokens.rounding.largeIncreased
        font: Tokens.font.icon.builders.large.scale(root.fontScale * 1.3).build()
        onClicked: exec()
    }

    component Resource: Item {
        id: res

        required property string icon
        required property string value
        required property color colour
        property real fillValue: -1
        property string badge
        property bool badgeAlert

        Layout.fillWidth: true
        implicitHeight: width

        SoulVessel {
            anchors.fill: parent
            anchors.margins: 8
            level: Math.max(0, res.fillValue)
            colour: Qt.alpha(res.colour, 0.85)
            running: res.visible
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: -Tokens.spacing.extraSmall

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: res.icon
                color: Hallownest.soul
                style: Text.Outline
                styleColor: Hallownest.void_
                fontStyle: Tokens.font.icon.builders.medium.scale(root.fontScale).build()
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: res.value
                color: Hallownest.soul
                style: Text.Outline
                styleColor: Hallownest.void_
                font.family: Hallownest.mono
                font.pointSize: Tokens.font.headline.large.pointSize * root.fontScale * 0.72
                font.weight: Font.Bold
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            visible: res.badge !== ""
            implicitWidth: badgeText.implicitWidth + 14
            implicitHeight: badgeText.implicitHeight + 6
            radius: height / 2
            color: res.badgeAlert ? Qt.alpha(Hallownest.grimm, 0.25) : Hallownest.button
            border.width: 1
            border.color: res.badgeAlert ? Hallownest.grimm : Hallownest.border

            StyledText {
                id: badgeText

                anchors.centerIn: parent
                text: res.badge
                color: res.badgeAlert ? Hallownest.grimm : Hallownest.text
                font.family: Hallownest.mono
                font.pointSize: 9 * root.fontScale
                font.weight: Font.Bold
            }
        }

        Behavior on fillValue {
            Anim {}
        }
    }
}
