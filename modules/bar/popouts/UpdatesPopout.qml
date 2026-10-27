pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus

ColumnLayout {
    id: root

    required property PopoutState popouts

    width: Math.max(480, Tokens.sizes.bar.networkWidth + Tokens.padding.extraLarge * 2)
    spacing: Tokens.spacing.small

    readonly property string titleText: {
        if (Updates.installing)
            return Updates.statusMessage || Tr.tr("Updating…");
        if (Updates.busy)
            return Updates.statusMessage || Tr.tr("Updates");
        if (!Updates.hasUpdates)
            return Tr.tr("Updates");
        if (Updates.downloadSizeLabel)
            // TRANSLATORS: %1 = update count, %2 = total download size (e.g. "12.3 MiB")
            return Tr.tr("%1 Updates (%2)").arg(Updates.count).arg(Updates.downloadSizeLabel);
        // TRANSLATORS: %1 = update count
        return Tr.tr("%1 Updates").arg(Updates.count);
    }

    // Fixed body height (~10 compact rows) so refresh does not collapse the popout
    readonly property int bodyHeight: Math.round((Tokens.font.body.small.pointSize + Tokens.padding.small) * 10)

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.medium
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: root.titleText
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            elide: Text.ElideRight
        }

        IconButton {
            icon: Updates.busy ? "stop" : "autorenew"
            type: IconButton.Text
            isRound: true
            onClicked: Updates.busy ? Updates.stop() : Updates.refresh()
        }
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        Layout.topMargin: Tokens.spacing.extraSmall
        implicitHeight: 1
        color: Colours.palette.m3outlineVariant
        opacity: 0.5
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: root.bodyHeight
        Layout.rightMargin: Tokens.padding.extraSmall
        clip: true

        ListView {
            id: pkgList

            anchors.fill: parent
            visible: Updates.hasUpdates && !Updates.busy
            clip: true
            interactive: contentHeight > height
            spacing: Tokens.spacing.extraSmall
            model: Updates.packages

            delegate: Item {
                id: row

                required property var modelData
                required property int index

                width: pkgList.width
                implicitHeight: rowLayout.implicitHeight + Tokens.padding.extraSmall

                RowLayout {
                    id: rowLayout

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        visible: {
                            const s = (row.modelData.source || "").toUpperCase();
                            return s !== "AUR";
                        }
                        text: {
                            const s = (row.modelData.source || "").toUpperCase();
                            if (s.startsWith("FLATPAK"))
                                return "deployed_code";
                            return "settings";
                        }
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        visible: (row.modelData.source || "").toUpperCase() === "AUR"
                        text: "👽"
                        font.family: "Noto Color Emoji"
                        font.pixelSize: Math.round(Tokens.font.icon.small.pointSize * 1.35)
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: row.modelData.name
                        font: Tokens.font.body.small
                        elide: Text.ElideMiddle
                    }

                    StyledText {
                        text: {
                            const frm = row.modelData.from || "";
                            const to = row.modelData.to || "";
                            if (frm && to)
                                return `${frm} → ${to}`;
                            return to || frm;
                        }
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        elide: Text.ElideLeft
                        Layout.maximumWidth: root.width * 0.48
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: pkgList
            }
        }

        StyledText {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !Updates.busy && !Updates.hasUpdates
            horizontalAlignment: Text.AlignHCenter
            text: Tr.tr("No updates available.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
        }

        CircularIndicator {
            anchors.centerIn: parent
            running: Updates.busy
            visible: Updates.busy
        }
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        implicitHeight: 1
        color: Colours.palette.m3outlineVariant
        opacity: 0.5
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        IconTextButton {
            Layout.fillWidth: true
            visible: Updates.hasUpdates
            icon: "install_desktop"
            text: Updates.installing ? Tr.tr("Updating…") : Tr.tr("Update system")
            type: IconTextButton.Filled
            enabled: !Updates.busy && !Updates.installing && !Updates.awaitingPassword
            onClicked: {
                Updates.requestUpdateSystem("background");
                root.popouts.currentName = "updatesPassword";
            }
        }

        Item {
            Layout.fillWidth: true
            visible: !Updates.hasUpdates
        }

        IconButton {
            icon: "open_in_new"
            type: IconButton.Tonal
            isRound: true
            onClicked: {
                root.popouts.hasCurrent = false;
                Updates.prepareNexus();
                WindowFactory.create();
            }
        }
    }
}
