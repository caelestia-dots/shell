pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

ConnectedRect {
    id: root

    required property var action
    property bool first
    property bool last
    property bool recording

    readonly property string currentBind: Keybinds.bindFor(action.id)
    readonly property bool isDefault: Keybinds.isDefault(action.id)

    signal recordRequested
    signal resetRequested
    signal cancelled
    signal captured(string bind)

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Tokens.padding.medium * 2
    clip: false

    focus: recording
    activeFocusOnTab: false

    StateLayer {
        enabled: !root.recording
        onClicked: root.recordRequested()
    }

    Keys.onPressed: event => {
        if (!root.recording)
            return;

        if (event.key === Qt.Key_Escape) {
            root.cancelled();
            event.accepted = true;
            return;
        }

        const bind = Keybinds.keyEventToBind(event);
        event.accepted = true;
        if (!bind)
            return;

        root.captured(bind);
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.recording
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton
        hoverEnabled: true
        cursorShape: Qt.CrossCursor
        onPressed: event => {
            // Ignore the click that started recording
            if (event.button === Qt.LeftButton && !root.activeFocus)
                return;
            const bind = Keybinds.mouseEventToBind(event.button);
            if (!bind)
                return;
            root.captured(bind);
            event.accepted = true;
        }
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.action.label()
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.action.description()
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        StyledRect {
            Layout.preferredHeight: bindLabel.implicitHeight + Tokens.padding.small * 2
            Layout.preferredWidth: Math.max(bindLabel.implicitWidth + Tokens.padding.medium * 2, 72)
            radius: Tokens.rounding.medium
            color: root.recording ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHighest

            StyledText {
                id: bindLabel

                anchors.centerIn: parent
                text: root.recording ? Tr.tr("Press a key…") : (root.currentBind || Tr.tr("None"))
                color: root.recording ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                font: Tokens.font.label.medium
            }
        }

        IconButton {
            visible: !root.isDefault || root.currentBind === ""
            icon: "restart_alt"
            type: IconButton.Text
            isRound: true
            font: Tokens.font.icon.medium
            onClicked: root.resetRequested()
        }
    }

    onRecordingChanged: {
        if (recording)
            forceActiveFocus();
    }
}
