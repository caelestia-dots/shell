pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Keyboard & mouse")

    property string recordingId
    property bool confirmOpen
    property string pendingActionId
    property string pendingBind
    property string pendingConflictLabel

    function categoryActions(category: string): var {
        return Keybinds.catalog.filter(a => a.category === category);
    }

    function stopRecording(): void {
        if (root.recordingId)
            root.recordingId = "";
    }

    function handleCapture(actionId: string, bind: string): void {
        root.recordingId = "";
        Keybinds.conflictWarning = "";

        const conflict = Keybinds.findConflict(actionId, bind);
        if (conflict) {
            root.pendingActionId = actionId;
            root.pendingBind = bind;
            root.pendingConflictLabel = conflict.label();
            root.confirmOpen = true;
            return;
        }

        Keybinds.setBind(actionId, bind, false);
    }

    function acceptOverwrite(): void {
        Keybinds.setBind(root.pendingActionId, root.pendingBind, true);
        root.confirmOpen = false;
        root.pendingActionId = "";
        root.pendingBind = "";
        root.pendingConflictLabel = "";
    }

    function cancelOverwrite(): void {
        root.confirmOpen = false;
        root.pendingActionId = "";
        root.pendingBind = "";
        root.pendingConflictLabel = "";
    }

    onRecordingIdChanged: Keybinds.setGrabActive(!!root.recordingId)

    Component.onDestruction: {
        if (root.recordingId)
            Keybinds.setGrabActive(false);
    }

    // PageBase only accepts a single default child
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        implicitHeight: Math.max(col.implicitHeight, root.confirmOpen ? confirmPanel.implicitHeight + Tokens.padding.extraLarge * 4 : 0)

        ColumnLayout {
            id: col

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Click a shortcut, then press a key or mouse button. Esc cancels.")
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            Loader {
                Layout.fillWidth: true
                active: !!Keybinds.conflictWarning
                visible: active

                sourceComponent: StyledRect {
                    color: Colours.palette.m3errorContainer
                    radius: Tokens.rounding.large
                    implicitHeight: warnText.implicitHeight + Tokens.padding.medium * 2

                    StyledText {
                        id: warnText

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        text: Keybinds.conflictWarning
                        color: Colours.palette.m3onErrorContainer
                        font: Tokens.font.body.small
                        wrapMode: Text.WordWrap
                    }
                }
            }

            IconTextButton {
                Layout.alignment: Qt.AlignRight
                icon: "restart_alt"
                text: Tr.tr("Reset all")
                type: IconTextButton.Tonal
                isRound: true
                shapeMorph: true
                onClicked: {
                    root.stopRecording();
                    root.cancelOverwrite();
                    Keybinds.resetAll();
                }
            }

            Repeater {
                model: ["windows", "workspaces", "activities", "apps", "shell", "notifications", "media", "system", "capture"]

                ColumnLayout {
                    id: section

                    required property string modelData

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall / 2
                    visible: actions.count > 0

                    readonly property var actionsList: root.categoryActions(modelData)

                    SectionHeader {
                        first: section.modelData === "windows"
                        text: Keybinds.categoryLabels[section.modelData]()
                    }

                    Repeater {
                        id: actions

                        model: section.actionsList

                        KeybindRow {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            action: modelData
                            first: index === 0
                            last: index === section.actionsList.length - 1
                            recording: root.recordingId === modelData.id
                            onRecordRequested: {
                                root.cancelOverwrite();
                                root.recordingId = modelData.id;
                            }
                            onCancelled: root.recordingId = ""
                            onCaptured: bind => root.handleCapture(modelData.id, bind)
                            onResetRequested: {
                                root.recordingId = "";
                                Keybinds.resetBind(modelData.id);
                            }
                        }
                    }
                }
            }
        }

        // Conflict overwrite confirmation (Plasma-style)
        MouseArea {
            id: confirmBackdrop

            anchors.fill: parent
            visible: root.confirmOpen
            enabled: visible
            z: 10
            onClicked: root.cancelOverwrite()

            StyledRect {
                id: confirmPanel

                anchors.centerIn: parent
                width: Math.min(parent.width - Tokens.padding.extraLarge * 2, 420)
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainerHigh
                implicitHeight: confirmCol.implicitHeight + Tokens.padding.extraLarge * 2

                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    id: confirmCol

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.padding.extraLarge
                    spacing: Tokens.spacing.medium

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Replace shortcut?")
                        font: Tokens.font.title.small
                        wrapMode: Text.WordWrap
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("“%1” is already used by “%2”. Do you want to reassign it?").arg(root.pendingBind).arg(root.pendingConflictLabel)
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.medium
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        Item {
                            Layout.fillWidth: true
                        }

                        IconTextButton {
                            text: Tr.tr("Cancel")
                            type: IconTextButton.Text
                            isRound: true
                            shapeMorph: true
                            onClicked: root.cancelOverwrite()
                        }

                        IconTextButton {
                            text: Tr.tr("Replace")
                            type: IconTextButton.Tonal
                            isRound: true
                            shapeMorph: true
                            onClicked: root.acceptOverwrite()
                        }
                    }
                }
            }
        }
    }
}
