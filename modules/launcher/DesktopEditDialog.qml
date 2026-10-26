pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.filedialog
import qs.services
import qs.utils
import qs.modules.drawers
import qs.modules.launcher.services

Item {
    id: root

    property DesktopEntry entry
    property bool open
    property bool browsingIcon

    readonly property bool shouldShow: open && !!entry

    signal closed

    function show(e: DesktopEntry): void {
        entry = e;
        nameField.text = e?.name ?? "";
        commentField.text = e?.comment ?? "";
        iconField.text = e?.icon ?? "";
        browsingIcon = false;
        picker.cwd = ["Home"];
        open = true;
        Apps.editingDesktop = true;
        Qt.callLater(() => nameField.forceActiveFocus());
    }

    function close(): void {
        browsingIcon = false;
        open = false;
        Apps.editingDesktop = false;
        closed();
    }

    function save(): void {
        if (!entry)
            return;
        const ok = Apps.saveDesktopMetadata(entry.id, nameField.text.trim(), commentField.text.trim(), iconField.text.trim());
        if (!ok)
            console.warn(`DesktopEditDialog: failed to save ${entry.id}`);
        root.close();
    }

    function startIconBrowse(): void {
        picker.cwd = ["Home"];
        browsingIcon = true;
    }

    // Fill the drawer interaction area so browse mode isn't clipped to the short launcher card
    parent: {
        const win = QsWindow.window;
        const contentWin = win as ContentWindow;
        return contentWin ? contentWin.interactionWrapper : (win as QsWindow)?.contentItem;
    }
    anchors.fill: parent
    visible: shouldShow
    z: 2000
    enabled: shouldShow

    MouseArea {
        anchors.fill: parent
        onClicked: event => {
            const p = mapToItem(card, event.x, event.y);
            if (p.x < 0 || p.y < 0 || p.x > card.width || p.y > card.height)
                root.close();
        }

        StyledRect {
            anchors.fill: parent
            color: Qt.alpha(Colours.palette.m3scrim, 0.55)
        }
    }

    Elevation {
        id: card

        anchors.centerIn: parent
        width: root.browsingIcon ? Math.min(parent.width - Tokens.padding.large * 2, 640) : Math.min(parent.width - Tokens.padding.large * 2, 440)
        height: root.browsingIcon ? Math.min(parent.height - Tokens.padding.large * 2, 560) : panel.implicitHeight
        radius: Tokens.rounding.extraLarge
        level: 3

        Behavior on width {
            Anim {
                type: Anim.DefaultEffects
            }
        }
        Behavior on height {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        StyledRect {
            id: panel

            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3surfaceContainerHigh
            implicitHeight: formCol.implicitHeight + Tokens.padding.large * 2
            clip: true

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: formCol

                // Keep in tree while browsing (opacity) so mid-click hide doesn't leak to scrim
                visible: true
                opacity: root.browsingIcon ? 0 : 1
                enabled: !root.browsingIcon
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.large
                z: root.browsingIcon ? 0 : 1

                StyledText {
                    text: Tr.tr("Edit application")
                    font: Tokens.font.title.small
                    color: Colours.palette.m3onSurface
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.large

                    StyledRect {
                        id: previewBox

                        implicitWidth: 72
                        implicitHeight: 72
                        radius: Tokens.rounding.large
                        color: Colours.palette.m3surfaceContainerHighest
                        clip: true

                        readonly property string preview: Icons.resolveThemeIcon(iconField.text || "", "application-x-executable")

                        IconImage {
                            id: previewImage

                            anchors.fill: parent
                            anchors.margins: Tokens.padding.small
                            asynchronous: true
                            source: previewBox.preview
                            visible: previewBox.preview.length > 0 && status === Image.Ready
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "apps"
                            color: Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.extraLarge
                            visible: !previewImage.visible
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        StyledTextField {
                            id: nameField

                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            type: StyledTextField.Outlined
                            placeholderText: Tr.tr("Application name")
                            verticalPadding: Tokens.padding.medium
                            horizontalPadding: Tokens.padding.medium
                        }

                        StyledTextField {
                            id: commentField

                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            type: StyledTextField.Outlined
                            placeholderText: Tr.tr("Description")
                            verticalPadding: Tokens.padding.medium
                            horizontalPadding: Tokens.padding.medium
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledTextField {
                        id: iconField

                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        type: StyledTextField.Outlined
                        placeholderText: Tr.tr("Icon")
                        supportingText: Tr.tr("Theme name or file path")
                        verticalPadding: Tokens.padding.medium
                        horizontalPadding: Tokens.padding.medium
                    }

                    IconButton {
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: Tokens.padding.extraSmall
                        isRound: true
                        icon: "folder_open"
                        type: IconButton.Tonal
                        // Defer so this button isn't hidden before the click fully finishes
                        onClicked: Qt.callLater(() => root.startIconBrowse())
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.spacing.extraSmall
                    spacing: Tokens.spacing.small

                    Item {
                        Layout.fillWidth: true
                    }

                    IconTextButton {
                        text: Tr.tr("Cancel")
                        icon: "close"
                        type: IconButton.Text
                        onClicked: root.close()
                    }

                    IconTextButton {
                        text: Tr.tr("Save")
                        icon: "check"
                        type: IconButton.Tonal
                        inactiveColour: Colours.palette.m3primaryContainer
                        inactiveOnColour: Colours.palette.m3onPrimaryContainer
                        onClicked: root.save()
                    }
                }
            }

            ColumnLayout {
                visible: root.browsingIcon
                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                spacing: Tokens.spacing.extraSmall
                z: 2

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Tokens.padding.small
                    Layout.rightMargin: Tokens.padding.small
                    Layout.topMargin: Tokens.padding.extraSmall
                    spacing: Tokens.spacing.small

                    IconButton {
                        icon: "arrow_back"
                        type: IconButton.Text
                        onClicked: picker.rejected()
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Choose icon")
                        font: Tokens.font.title.small
                    }
                }

                HeaderBar {
                    Layout.fillWidth: true
                    dialog: picker
                }

                FolderContents {
                    id: folderContents

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 280
                    dialog: picker
                }

                // Compact footer — DialogButtons overlaps in narrow layouts
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Tokens.padding.small
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        text: {
                            const filters = picker.filters.map(f => `*.${f}`).join(", ");
                            return `${picker.filterLabel} (${filters})`;
                        }
                    }

                    IconTextButton {
                        text: Tr.trCtx("Cancel", "button")
                        icon: "close"
                        type: IconButton.Text
                        onClicked: picker.rejected()
                    }

                    IconTextButton {
                        text: Tr.trCtx("Select", "button")
                        icon: "check"
                        type: IconButton.Tonal
                        enabled: picker.selectionValid
                        inactiveColour: Colours.palette.m3primaryContainer
                        inactiveOnColour: Colours.palette.m3onPrimaryContainer
                        onClicked: {
                            if (picker.selectionValid)
                                picker.accepted(folderContents.currentItem.modelData.path);
                        }
                    }
                }
            }

            Keys.onEscapePressed: {
                if (root.browsingIcon)
                    picker.rejected();
                else
                    root.close();
            }
            Keys.onReturnPressed: {
                if (!root.browsingIcon)
                    root.save();
            }
        }
    }

    QtObject {
        id: picker

        property list<string> cwd: ["Home"]
        property string filterLabel: Tr.tr("Images")
        property list<string> filters: Images.validImageExtensions

        readonly property bool selectionValid: {
            const file = folderContents.currentItem?.modelData;
            return !!(file && !file.isDir && (filters.includes("*") || filters.some(f => f.toLowerCase() === file.suffix.toLowerCase())));
        }

        function accepted(path: string): void {
            iconField.text = path.startsWith("file://") ? path.slice(7) : path;
            root.browsingIcon = false;
        }

        function rejected(): void {
            root.browsingIcon = false;
        }
    }
}
