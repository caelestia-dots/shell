pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.services

// Menu of a tray app drawn in place; submenus replace the list and Back pops them
ColumnLayout {
    id: root

    required property SystemTrayItem item
    property var stack: []
    readonly property QsMenuHandle current: stack.length ? stack[stack.length - 1] : item.menu

    signal done

    spacing: 8

    QsMenuOpener {
        id: opener

        menu: root.current
    }

    HkButton {
        visible: root.stack.length > 0
        icon: "chevron_left"
        text: Tr.trCtx("Back", "button")
        onClicked: root.stack = root.stack.slice(0, -1)
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: opener.children

            Rectangle {
                id: entry

                required property QsMenuEntry modelData

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                visible: !modelData.isSeparator
                implicitHeight: 38
                radius: 10
                color: area.containsMouse && modelData.enabled ? Hallownest.raise(Hallownest.card, 1.6) : Hallownest.card
                border.width: 1
                border.color: Hallownest.border
                opacity: modelData.enabled ? 1 : 0.45

                IconImage {
                    id: entryIcon

                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    visible: entry.modelData.icon !== ""
                    implicitSize: 16
                    source: entry.modelData.icon
                }

                MaterialIcon {
                    id: checkIcon

                    anchors.left: entryIcon.visible ? entryIcon.right : parent.left
                    anchors.leftMargin: entryIcon.visible ? 8 : 12
                    anchors.verticalCenter: parent.verticalCenter
                    visible: entry.modelData.buttonType !== QsMenuButtonType.None
                    text: entry.modelData.buttonType === QsMenuButtonType.RadioButton ? (entry.modelData.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked") : (entry.modelData.checkState === Qt.Checked ? "check_box" : "check_box_outline_blank")
                    color: entry.modelData.checkState === Qt.Checked ? Hallownest.soul : Hallownest.subtext
                }

                StyledText {
                    anchors.left: checkIcon.visible ? checkIcon.right : entryIcon.visible ? entryIcon.right : parent.left
                    anchors.leftMargin: checkIcon.visible || entryIcon.visible ? 8 : 12
                    anchors.right: chevron.visible ? chevron.left : parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    // dbusmenu marks mnemonics with "_"; "__" is a literal underscore
                    text: entry.modelData.text.replace(/_(.)/g, "$1")
                    color: Hallownest.text
                    font.pointSize: 10
                    elide: Text.ElideRight
                }

                MaterialIcon {
                    id: chevron

                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    visible: entry.modelData.hasChildren
                    text: "chevron_right"
                    color: Hallownest.subtext
                }

                MouseArea {
                    id: area

                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: entry.modelData.enabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (entry.modelData.hasChildren) {
                            root.stack = root.stack.concat([entry.modelData]);
                        } else {
                            entry.modelData.triggered();
                            root.done();
                        }
                    }
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: opener.children.values.every(e => e.isSeparator)
        horizontalAlignment: Text.AlignHCenter
        text: Tr.tr("This app has no menu")
        color: Hallownest.faint
        font.pointSize: 10
    }
}
