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

    title: Tr.tr("Updates")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.padding.large
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Toolbar
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: toolbar.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: toolbar

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                IconButton {
                    icon: Updates.busy ? "stop" : "autorenew"
                    type: IconButton.Tonal
                    isRound: true
                    enabled: !Updates.installing
                    onClicked: Updates.busy ? Updates.stop() : Updates.refresh()
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Updates.statusMessage || Tr.tr("System updates")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: !!Updates.error
                        text: Updates.error
                        color: Colours.palette.m3error
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                IconTextButton {
                    visible: Updates.hasUpdates || Updates.installing
                    icon: Updates.installing ? "stop" : "install_desktop"
                    text: Updates.installing ? Tr.trCtx("Cancel", "button") : Tr.tr("Update")
                    type: IconTextButton.Tonal
                    isRound: true
                    shapeMorph: true
                    enabled: !Updates.busy
                    onClicked: {
                        if (Updates.installing) {
                            Updates.stopInstall();
                            return;
                        }
                        Updates.requestUpdateSystem("logged");
                        nexusPwField.text = "";
                        Qt.callLater(() => nexusPwField.forceActiveFocus());
                    }
                }

                IconButton {
                    icon: "settings"
                    type: IconButton.Text
                    isRound: true
                    onClicked: root.nState.openSubPage(1)
                }
            }
        }

        // Password dialog (logged / Nexus mode)
        ConnectedRect {
            Layout.fillWidth: true
            visible: Updates.awaitingPassword && Updates.pendingMode === "logged"
            first: true
            last: true
            implicitHeight: pwCol.implicitHeight + Tokens.padding.medium * 2

            ColumnLayout {
                id: pwCol
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Authenticate")
                    font: Tokens.font.title.small
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Enter your password to start the system update.")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                }

                StyledTextField {
                    id: nexusPwField
                    Layout.fillWidth: true
                    placeholderText: Tr.tr("Password")
                    echoMode: TextInput.Password
                    enabled: !Updates.installing
                    Keys.onReturnPressed: {
                        Updates.confirmPassword(nexusPwField.text);
                        nexusPwField.text = "";
                    }
                    Keys.onEnterPressed: {
                        Updates.confirmPassword(nexusPwField.text);
                        nexusPwField.text = "";
                    }
                }

                StyledText {
                    visible: Updates.authError.length > 0
                    Layout.fillWidth: true
                    text: Updates.authError
                    color: Colours.palette.m3error
                    font: Tokens.font.body.small
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: Tokens.spacing.small

                    IconTextButton {
                        text: Tr.trCtx("Cancel", "button")
                        type: IconTextButton.Text
                        enabled: !Updates.installing
                        onClicked: {
                            Updates.cancelPassword();
                            nexusPwField.text = "";
                        }
                    }

                    IconTextButton {
                        text: Tr.tr("Update")
                        type: IconTextButton.Tonal
                        enabled: nexusPwField.text.length > 0 && !Updates.installing
                        onClicked: {
                            Updates.confirmPassword(nexusPwField.text);
                            nexusPwField.text = "";
                        }
                    }
                }
            }
        }

        // Single-package warning (plasmoid parity)
        ConnectedRect {
            Layout.fillWidth: true
            visible: Updates.showSingleWarning
            first: true
            last: true
            color: Colours.palette.m3errorContainer
            implicitHeight: warnCol.implicitHeight + Tokens.padding.medium * 2

            ColumnLayout {
                id: warnCol
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Updating single packages is blocked by default due to high risk of system breakage. Enable it in settings?")
                    color: Colours.palette.m3onErrorContainer
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: Tokens.spacing.small

                    IconTextButton {
                        text: Tr.trCtx("Cancel", "button")
                        type: IconTextButton.Text
                        onClicked: Updates.showSingleWarning = false
                    }

                    IconTextButton {
                        text: Tr.trCtx("Enable", "button")
                        type: IconTextButton.Tonal
                        onClicked: {
                            GlobalConfig.utilities.updates.allowSingleModification = true;
                            Updates.showSingleWarning = false;
                        }
                    }
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Available")
            visible: Updates.hasUpdates || Updates.busy
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            visible: !Updates.busy && !Updates.hasUpdates
            text: Tr.tr("No updates available.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.medium
            horizontalAlignment: Text.AlignHCenter
        }

        Repeater {
            model: Updates.packages

            ConnectedRect {
                id: pkgRow

                required property var modelData
                required property int index

                property bool expanded

                Layout.fillWidth: true
                first: index === 0
                last: index === Updates.packages.length - 1
                implicitHeight: pkgCol.implicitHeight + Tokens.padding.medium * 2

                ColumnLayout {
                    id: pkgCol

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            visible: {
                                const s = (pkgRow.modelData.source || "").toUpperCase();
                                return s !== "AUR";
                            }
                            text: {
                                const s = (pkgRow.modelData.source || "").toUpperCase();
                                if (s.startsWith("FLATPAK"))
                                    return "deployed_code";
                                return "settings";
                            }
                            color: Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.medium
                        }

                        StyledText {
                            visible: (pkgRow.modelData.source || "").toUpperCase() === "AUR"
                            text: "👽"
                            font.family: "Noto Color Emoji"
                            font.pixelSize: Math.round(Tokens.font.icon.medium.pointSize * 1.35)
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: pkgRow.modelData.name
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: {
                                    const s = pkgRow.modelData.source || "";
                                    const frm = pkgRow.modelData.from || "";
                                    const to = pkgRow.modelData.to || "";
                                    return `${s}  ·  ${frm} → ${to}`;
                                }
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }

                        IconButton {
                            icon: pkgRow.expanded ? "expand_less" : "expand_more"
                            type: IconButton.Text
                            isRound: true
                            onClicked: pkgRow.expanded = !pkgRow.expanded
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: pkgRow.expanded
                        spacing: Tokens.spacing.small

                        StyledText {
                            Layout.fillWidth: true
                            visible: !!(pkgRow.modelData.desc || "").trim()
                            text: (pkgRow.modelData.desc || "").trim()
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            IconTextButton {
                                icon: "info"
                                text: Tr.tr("Info")
                                type: IconTextButton.Text
                                onClicked: Updates.showPackageInfo(pkgRow.modelData)
                            }

                            IconTextButton {
                                icon: "download"
                                text: Tr.tr("Update")
                                type: IconTextButton.Text
                                onClicked: Updates.updatePackage(pkgRow.modelData)
                            }

                            IconTextButton {
                                icon: "delete"
                                text: Tr.tr("Uninstall")
                                type: IconTextButton.Text
                                onClicked: Updates.uninstallPackage(pkgRow.modelData)
                            }

                            IconTextButton {
                                visible: !!(pkgRow.modelData.url)
                                icon: "link"
                                text: Tr.tr("URL")
                                type: IconTextButton.Text
                                onClicked: Updates.openPackageUrl(pkgRow.modelData)
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }

        // Footer actions
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.medium
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "delete_sweep"
                text: Tr.tr("Clear orphans")
                type: IconTextButton.Text
                enabled: !Updates.installing
                onClicked: Updates.cleanupOrphans()
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Tokens.spacing.medium
        }

        // Live update output
        ConnectedRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            visible: Updates.logVisible
            first: true
            last: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Output")
                        font: Tokens.font.title.small
                    }

                    IconButton {
                        visible: Updates.installing
                        icon: "stop"
                        type: IconButton.Text
                        isRound: true
                        onClicked: Updates.stopInstall()
                    }

                    IconButton {
                        visible: !Updates.installing
                        icon: "close"
                        type: IconButton.Text
                        isRound: true
                        onClicked: Updates.logVisible = false
                    }
                }

                ListView {
                    id: logList

                    // Reassigning logLines resets the view to the top; keep pinned
                    // to the end unless the user scrolls up while reading.
                    property bool stickToEnd: true

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: Updates.logLines
                    boundsBehavior: Flickable.StopAtBounds

                    function scrollToLatest(): void {
                        if (!stickToEnd)
                            return;
                        Qt.callLater(() => {
                            if (stickToEnd)
                                logList.positionViewAtEnd();
                        });
                    }

                    delegate: StyledText {
                        required property string modelData
                        width: logList.width
                        text: modelData
                        font: Tokens.font.mono.small
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WrapAnywhere
                    }

                    StyledScrollBar.vertical: StyledScrollBar {
                        flickable: logList
                    }

                    onMovementEnded: stickToEnd = atYEnd
                    onCountChanged: scrollToLatest()
                    onContentHeightChanged: scrollToLatest()

                    Connections {
                        target: Updates
                        function onLogLinesChanged(): void {
                            logList.scrollToLatest();
                        }
                        function onInstallingChanged(): void {
                            if (Updates.installing)
                                logList.stickToEnd = true;
                        }
                    }
                }
            }
        }
    }
}
