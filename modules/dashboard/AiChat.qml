pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils
import qs.config
import Caelestia
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {
    id: root

    implicitWidth: 700
    implicitHeight: 600

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Compact header
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + Appearance.padding.small * 2

            color: "transparent"

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.margins: Appearance.padding.small
                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Chat")
                    font.pointSize: Appearance.font.size.large
                    font.weight: Font.Medium
                    color: Colours.palette.m3onSurface
                }

                Item { Layout.fillWidth: true }

                // Model indicator
                StyledRect {
                    implicitWidth: modelText.implicitWidth + Appearance.padding.normal * 2
                    implicitHeight: modelText.implicitHeight + Appearance.padding.small * 2
                    color: Colours.palette.m3surfaceContainerHighest
                    radius: Appearance.rounding.full

                    StyledText {
                        id: modelText
                        anchors.centerIn: parent
                        text: Ai.models[Ai.currentModelId]?.name ?? "No Model"
                        color: Colours.palette.m3onSurface
                        font.pointSize: Appearance.font.size.small
                    }
                }

                IconButton {
                    icon: "settings"
                    type: IconButton.Text
                }
            }
        }

        // Messages area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StyledListView {
                id: messageList

                anchors.fill: parent
                anchors.leftMargin: Appearance.padding.large
                anchors.rightMargin: Appearance.padding.large
                anchors.topMargin: Appearance.padding.normal
                anchors.bottomMargin: Appearance.padding.small

                clip: true
                spacing: Appearance.spacing.small

                model: Ai.messageIDs

                delegate: MessageItem {
                    required property int index
                    required property var modelData

                    width: messageList.width
                    messageId: modelData
                }

                onCountChanged: Qt.callLater(() => {
                    messageList.positionViewAtEnd();
                })
            }

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                visible: messageList.count === 0
                spacing: Appearance.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "chat_bubble_outline"
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.extraLarge * 2
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Start a conversation")
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.normal
                }
            }
        }

        // Input area with status
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: inputColumn.height
            Layout.minimumHeight: inputColumn.height
            Layout.topMargin: Appearance.padding.normal

            ColumnLayout {
                id: inputColumn
                width: parent.width
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.small

                // Compact status bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small
                    visible: !Ai.currentModelHasApiKey

                    MaterialIcon {
                        text: "warning"
                        color: Colours.palette.m3error
                        font.pointSize: Appearance.font.size.extraSmall
                    }

                    StyledText {
                        text: qsTr("API key required")
                        color: Colours.palette.m3error
                        font.pointSize: Appearance.font.size.extraSmall
                    }

                    Item { Layout.fillWidth: true }
                }

                // Input row
                StyledRect {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48

                    color: Colours.palette.m3surfaceContainerHighest
                    radius: Appearance.rounding.full

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.padding.large
                        anchors.rightMargin: Appearance.padding.small
                        spacing: Appearance.spacing.small

                        TextInput {
                            id: inputField

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            color: Colours.palette.m3onSurface
                            font.family: Appearance.font.family.sans
                            font.pointSize: Appearance.font.size.normal
                            verticalAlignment: TextInput.AlignVCenter

                            focus: true
                            activeFocusOnTab: true

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                text: qsTr("Message...")
                                color: Colours.palette.m3outline
                                font: inputField.font
                                visible: !inputField.text && !inputField.activeFocus
                            }

                            Keys.onReturnPressed: event => {
                                if (event.modifiers & Qt.ShiftModifier) {
                                    return;
                                }
                                sendMessage();
                                event.accepted = true;
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                acceptedButtons: Qt.NoButton
                            }
                        }

                        IconButton {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            icon: "send"
                            type: IconButton.Filled
                            disabled: inputField.text.trim().length === 0
                            onClicked: sendMessage()
                        }
                    }
                }
            }
        }
    }

    function sendMessage() {
        const message = inputField.text.trim();
        if (message.length === 0) return;

        Ai.sendUserMessage(message);
        inputField.text = "";
    }

    // Message item component
    component MessageItem: Item {
        id: messageItem

        required property string messageId

        // Revision counter to force binding updates
        property int revision: 0

        // Direct property binding to the message object with revision dependency
        readonly property var message: {
            revision;
            return Ai.messageByID[messageItem.messageId];
        }

                // Extract properties with revision dependency to ensure reactivity
        readonly property string messageContent: {
            revision;
            return message?.content ?? "";
        }
        readonly property string messageRole: {
            revision;
            return message?.role ?? "";
        }
        readonly property bool messageThinking: {
            revision;
            return message?.thinking ?? false;
        }
        readonly property bool messageDone: {
            revision;
            return message?.done ?? false;
        }
        readonly property string messageModel: {
            revision;
            return message?.model ?? "";
        }

        function formatText(content) {
            // Simple markdown to HTML conversion
            content = content.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>'); // **bold**
            content = content.replace(/\*(.*?)\*/g, '<b>$1</b>'); // *italic* (treating as bold for simplicity)
            content = content.replace(/`(.*?)`/g, '<code>$1</code>'); // `code`
            content = content.replace(/```([\s\S]*?)```/g, '<pre>$1</pre>'); // ```codeblock```
            return content;
        }

        readonly property bool isUser: messageRole === "user"
        readonly property bool isInterface: messageRole === "interface"

        visible: message !== undefined && !isInterface
        implicitHeight: visible ? messageBubble.implicitHeight + Appearance.spacing.small : 0

        // Listen for message updates and increment revision to trigger re-evaluation
        Connections {
            target: Ai
            function onMessageUpdated(msgId) {
                if (msgId === messageItem.messageId) {
                    messageItem.revision++;
                }
            }
            function onMessagesChanged() {
                messageItem.revision++;
            }
        }

        // Message bubble
        StyledRect {
            id: messageBubble

            anchors.left: isUser ? undefined : parent.left
            anchors.right: isUser ? parent.right : undefined

            implicitWidth: {
                const maxWidth = parent.width * 0.75;
                const padding = Appearance.padding.normal * 2;
                if (messageContent.length > 0) {
                    const textWidth = messageText.implicitWidth + padding;
                    return Math.min(maxWidth, Math.max(60, textWidth));
                } else {
                    // Thinking dots
                    return 60;
                }
            }
            implicitHeight: {
                const padding = Appearance.padding.normal;
                if (messageContent.length > 0) {
                    const bottomPadding = isUser ? padding : Appearance.padding.small;
                    return messageText.height + padding + bottomPadding;
                } else {
                    // Thinking dots height
                    return 32;
                }
            }

            color: isUser
                ? Colours.palette.m3primaryContainer
                : Colours.palette.m3surfaceContainerHigh
            radius: Appearance.rounding.large

            // Subtle shadow for depth
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 1
                radius: 2
                samples: 5
                color: Qt.rgba(0, 0, 0, 0.08)
            }

            // Message text
            StyledText {
                id: messageText

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: Appearance.padding.normal
                anchors.rightMargin: Appearance.padding.normal
                anchors.topMargin: Appearance.padding.normal
                anchors.bottomMargin: isUser ? Appearance.padding.normal : Appearance.padding.small

                visible: messageContent.length > 0
                text: isUser ? messageContent : formatText(messageContent)
                color: isUser
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurface
                wrapMode: Text.Wrap
                textFormat: isUser ? Text.PlainText : Text.RichText
                font.pointSize: Appearance.font.size.normal
            }

            // Thinking indicator (animated dots)
            Row {
                id: thinkingDots
                anchors.centerIn: parent
                visible: messageContent.length === 0 && messageThinking && !messageDone
                spacing: 6

                Repeater {
                    model: 3

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: isUser
                            ? Colours.palette.m3onPrimaryContainer
                            : Colours.palette.m3onSurfaceVariant

                        // Smooth wave animation
                        SequentialAnimation on scale {
                            running: messageContent.length === 0 && messageThinking && !messageDone
                            loops: Animation.Infinite

                            PauseAnimation { duration: index * 200 }
                            NumberAnimation {
                                from: 1.0
                                to: 1.4
                                duration: 500
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                from: 1.4
                                to: 1.0
                                duration: 500
                                easing.type: Easing.InOutQuad
                            }
                            PauseAnimation { duration: (2 - index) * 200 }
                        }

                        SequentialAnimation on opacity {
                            running: messageContent.length === 0 && messageThinking && !messageDone
                            loops: Animation.Infinite

                            PauseAnimation { duration: index * 200 }
                            NumberAnimation {
                                from: 0.4
                                to: 1.0
                                duration: 500
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                from: 1.0
                                to: 0.4
                                duration: 500
                                easing.type: Easing.InOutQuad
                            }
                            PauseAnimation { duration: (2 - index) * 200 }
                        }
                    }
                }
            }
        }
    }
}
