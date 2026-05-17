pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    readonly property var timeouts: GlobalConfig.general.idle?.timeouts || []
    property bool _selfWriting: false

    function _syncFromConfig(): void {
        timeoutsModel.clear();
        const list = root.timeouts || [];
        for (const t of list) {
            timeoutsModel.append({
                timeout: t.timeout ?? 300,
                idleAction: typeof t.idleAction === "string" ? t.idleAction : JSON.stringify(t.idleAction),
                returnAction: t.returnAction ?? ""
            });
        }
    }

    function _serialize(): var {
        const out = [];
        for (let i = 0; i < timeoutsModel.count; i++) {
            const it = timeoutsModel.get(i);
            let action;
            try {
                action = JSON.parse(it.idleAction);
            } catch (e) {
                action = it.idleAction;
            }
            out.push({
                timeout: it.timeout,
                idleAction: action,
                returnAction: it.returnAction
            });
        }
        return out;
    }

    function _commit(): void {
        _selfWriting = true;
        GlobalConfig.general.idle.timeouts = JSON.parse(JSON.stringify(_serialize()));
        Qt.callLater(() => _selfWriting = false);
    }

    function updateField(idx: int, field: string, value: var): void {
        if (idx < 0 || idx >= timeoutsModel.count)
            return;
        timeoutsModel.setProperty(idx, field, value);
        _commit();
    }

    function removeAt(idx: int): void {
        if (idx < 0 || idx >= timeoutsModel.count)
            return;
        timeoutsModel.remove(idx);
        _commit();
    }

    function addTimeout(): void {
        timeoutsModel.append({
            timeout: 300,
            idleAction: "",
            returnAction: ""
        });
        _commit();
    }

    function formatDuration(seconds: int): string {
        if (seconds < 60)
            return seconds + qsTr("s");
        if (seconds < 3600)
            return Math.floor(seconds / 60) + qsTr("m");
        return Math.floor(seconds / 3600) + qsTr("h") + " " + Math.floor((seconds % 3600) / 60) + qsTr("m");
    }

    function formatAction(action: string): string {
        if (!action || action === "")
            return qsTr("No action");
        if (action === "lock")
            return qsTr("Lock screen");
        if (action === "dpms off")
            return qsTr("Turn off display");
        if (action === "suspend" || action === "suspend-then-hibernate")
            return qsTr("Suspend");
        if (action.startsWith("["))
            return qsTr("Custom command");
        return action;
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.normal

    onTimeoutsChanged: {
        if (_selfWriting)
            return;
        _syncFromConfig();
    }

    Component.onCompleted: _syncFromConfig()

    ListModel {
        id: timeoutsModel
    }

    ListView {
        id: listView

        Layout.fillWidth: true
        Layout.preferredHeight: contentHeight
        spacing: Tokens.spacing.normal
        model: timeoutsModel
        clip: true

        header: Item {
            width: ListView.view.width
            height: 56 + Tokens.spacing.normal

            StyledRect {
                anchors.fill: parent
                anchors.bottomMargin: Tokens.spacing.normal
                radius: Tokens.rounding.normal
                color: Colours.palette.m3primary

                TapHandler {
                    onTapped: root.addTimeout()
                }

                HoverHandler {
                    id: addBtnHover

                    onHoveredChanged: parent.color = hovered ? Qt.lighter(Colours.palette.m3primary, 1.1) : Colours.palette.m3primary
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.normal

                    MaterialIcon {
                        text: "add_circle"
                        font.pointSize: Tokens.font.size.large
                        color: Colours.palette.m3onPrimary
                    }

                    StyledText {
                        text: qsTr("Add idle timeout")
                        font.pointSize: Tokens.font.size.normal
                        color: Colours.palette.m3onPrimary
                    }
                }
            }
        }

        add: Transition {
            ParallelAnimation {
                Anim {
                    property: "opacity"
                    from: 0
                    to: 1
                }
                Anim {
                    property: "scale"
                    from: 0.80
                    to: 1
                }
            }
        }
        remove: Transition {
            ParallelAnimation {
                Anim {
                    property: "opacity"
                    from: 1
                    to: 0
                }
                Anim {
                    property: "scale"
                    from: 1
                    to: 0.80
                }
            }
        }
        removeDisplaced: Transition {
            Anim {
                property: "y"
            }
        }

        footer: StyledText {
            visible: timeoutsModel.count === 0
            width: ListView.view.width
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("No idle timeouts configured")
            color: Qt.alpha(Colours.palette.m3onSurface, 0.6)
            font.pointSize: Tokens.font.size.small
        }

        delegate: StyledRect {
            id: card

            required property int index
            required property int timeout
            required property string idleAction
            required property string returnAction

            property bool editing: false

            width: ListView.view.width
            implicitHeight: (editing ? cardCol.implicitHeight : headerRow.implicitHeight) + Tokens.padding.large * 2
            radius: Tokens.rounding.normal
            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

            Behavior on implicitHeight {
                Anim {}
            }

            ColumnLayout {
                id: cardCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.normal

                RowLayout {
                    id: headerRow

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: formatDuration(card.timeout) + " - " + formatAction(card.idleAction) //qmllint disable unqualified
                        font.pointSize: Tokens.font.size.normal
                        font.weight: Font.Medium
                    }

                    IconTextButton {
                        icon: card.editing ? "check" : "edit"
                        text: card.editing ? qsTr("Done") : qsTr("Edit")
                        onClicked: card.editing = !card.editing
                    }

                    IconButton {
                        icon: "delete"
                        onClicked: root.removeAt(card.index)
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    active: card.editing
                    visible: active && opacity > 0
                    opacity: card.editing ? 1 : 0

                    sourceComponent: ColumnLayout {
                        spacing: Tokens.spacing.normal

                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: timeoutRow.implicitHeight + Tokens.padding.large * 2
                            radius: Tokens.rounding.normal
                            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)

                            RowLayout {
                                id: timeoutRow

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Tokens.padding.large
                                spacing: Tokens.spacing.normal

                                StyledText {
                                    Layout.fillWidth: true
                                    text: qsTr("Timeout (seconds)")
                                }

                                CustomSpinBox {
                                    min: 10
                                    max: 7200
                                    step: 10
                                    value: card.timeout
                                    onValueModified: v => {
                                        if (Math.round(v) !== card.timeout)
                                            root.updateField(card.index, "timeout", Math.round(v));
                                    }
                                }
                            }
                        }

                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: actionField.implicitHeight + Tokens.padding.normal * 2
                            radius: Tokens.rounding.normal
                            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)

                            StyledTextField {
                                id: actionField

                                anchors.fill: parent
                                anchors.margins: Tokens.padding.normal
                                text: card.idleAction
                                placeholderText: qsTr("Idle action: lock, dpms off, suspend, or custom command")
                                onEditingFinished: {
                                    if (text !== card.idleAction)
                                        root.updateField(card.index, "idleAction", text);
                                }
                            }
                        }

                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: returnActionField.implicitHeight + Tokens.padding.normal * 2
                            radius: Tokens.rounding.normal
                            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)

                            StyledTextField {
                                id: returnActionField

                                anchors.fill: parent
                                anchors.margins: Tokens.padding.normal
                                text: card.returnAction
                                placeholderText: qsTr("Return action (optional): dpms on, etc.")
                                onEditingFinished: {
                                    if (text !== card.returnAction)
                                        root.updateField(card.index, "returnAction", text);
                                }
                            }
                        }
                    }

                    Behavior on opacity {
                        Anim {}
                    }
                }
            }
        }
    }
}
