pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

Item {
    id: root

    required property var entry
    required property var list
    required property ScreenState screenState

    // What's on screen trails the selected entry until the new content has loaded,
    // so skimming through the list doesn't flash placeholder content in between
    property var shown: null
    property string fullText
    property bool textLoaded
    property string loadingKey

    readonly property string key: entry ? Clipboard.keyOf(entry) : ""
    readonly property string infoText: {
        if (!shown)
            return "";
        if (shown.image || !textLoaded)
            return shown.info;

        const max = GlobalConfig.launcher.clipboard.previewMaxChars;
        return fullText.length >= max ? Tr.tr("%1+ chars").arg(max) : Tr.trN("%n char", "%n chars", fullText.length);
    }

    function load(): void {
        loadTimer.stop();
        textProc.running = false;

        // Images load themselves
        if (!entry || entry.image)
            return;

        if (!shown) {
            // Nothing on screen yet, so show the preview text right away
            shown = Clipboard.snapshot(entry);
            fullText = "";
            textLoaded = false;
        }

        loadTimer.restart();
    }

    onKeyChanged: load()
    Component.onCompleted: load()

    // Debounced so skimming the list doesn't decode every entry
    Timer {
        id: loadTimer

        interval: 80
        onTriggered: {
            if (!root.entry)
                return;
            root.loadingKey = root.key;
            textProc.exec(Clipboard.textCommand(root.entry));
        }
    }

    Process {
        id: textProc

        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.entry || root.entry.image || root.loadingKey !== root.key)
                    return;

                root.fullText = text.slice(0, GlobalConfig.launcher.clipboard.previewMaxChars);
                root.textLoaded = true;
                root.shown = Clipboard.snapshot(root.entry);
            }
        }
    }

    StyledRect {
        id: card

        anchors.fill: parent
        anchors.margins: Tokens.padding.small

        visible: !!root.entry && !!root.shown
        clip: true
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.large

        Item {
            id: inner

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium

            Item {
                id: header

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                implicitHeight: typeBadge.implicitHeight

                Badge {
                    id: typeBadge

                    anchors.left: parent.left

                    primary: true
                    icon: root.shown?.image ? "image" : "notes"
                    label: root.shown?.image ? Tr.tr("Image") : Tr.tr("Text")
                }

                Badge {
                    anchors.right: parent.right

                    label: root.infoText
                }
            }

            ClipRect {
                anchors.top: header.bottom
                anchors.topMargin: Tokens.spacing.medium
                anchors.bottom: buttons.top
                anchors.bottomMargin: Tokens.spacing.medium
                anchors.left: parent.left
                anchors.right: parent.right

                radius: Tokens.rounding.medium
                color: Colours.palette.m3surfaceContainerLowest

                Loader {
                    anchors.fill: parent

                    // Stays around while an image is on screen, even if a text entry is selected
                    active: (root.entry?.image ?? false) || (root.shown?.image ?? false)
                    visible: root.shown?.image ?? false

                    sourceComponent: ClipImage {
                        entry: root.entry?.image ? root.entry : root.shown
                        fillMode: Image.PreserveAspectFit
                        onLoaded: {
                            if (!root.entry?.image || Clipboard.keyOf(entry) !== root.key)
                                return;

                            root.shown = Clipboard.snapshot(root.entry);
                            root.textLoaded = false;
                        }
                    }
                }

                StyledText {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium

                    visible: !!root.shown && !root.shown.image
                    text: root.textLoaded ? root.fullText : (root.shown?.preview ?? "")
                    font: Tokens.font.body.small
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignTop
                }
            }

            Flow {
                id: buttons

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                spacing: Tokens.spacing.small

                HintButton {
                    keys: "↵"
                    label: Tr.tr("Copy")
                    onClicked: {
                        Clipboard.copy(root.entry);
                        root.screenState.launcher = false;
                    }
                }

                HintButton {
                    keys: "⌥↵"
                    label: Tr.tr("Paste")
                    onClicked: {
                        Clipboard.paste(root.entry);
                        root.screenState.launcher = false;
                    }
                }

                HintButton {
                    keys: "⌥P"
                    label: root.entry?.pinned ? Tr.tr("Unpin") : Tr.tr("Pin")
                    onClicked: root.list?.togglePinClip(root.entry)
                }

                HintButton {
                    keys: "Del"
                    label: Tr.tr("Delete")
                    onClicked: root.list?.removeClip(root.entry)
                }

                HintButton {
                    keys: "⌥Del"
                    label: Clipboard.confirmingClear ? Tr.tr("Confirm") : Tr.tr("Clear")
                    danger: Clipboard.confirmingClear
                    onClicked: Clipboard.clear()
                }
            }
        }
    }

    component Badge: StyledRect {
        id: badge

        property string icon
        property bool primary
        required property string label

        implicitWidth: badgeRow.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: badgeRow.implicitHeight + Tokens.padding.small

        radius: Tokens.rounding.full
        color: primary ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHighest

        Row {
            id: badgeRow

            anchors.centerIn: parent

            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter

                visible: badge.icon !== ""
                text: badge.icon
                color: badge.primary ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter

                text: badge.label
                color: badge.primary ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }
        }
    }

    component HintButton: StyledRect {
        id: button

        required property string keys
        required property string label
        property bool danger

        signal clicked

        implicitWidth: buttonText.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: buttonText.implicitHeight + Tokens.padding.small * 2

        radius: Tokens.rounding.full
        color: danger ? Colours.palette.m3errorContainer : Colours.palette.m3surfaceContainerHigh

        StateLayer {
            radius: button.radius
            onClicked: button.clicked()
        }

        StyledText {
            id: buttonText

            anchors.centerIn: parent

            text: `${button.keys} ${button.label}`
            color: button.danger ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
        }
    }
}
