import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property DesktopEntry app: nState.selectedApp
    readonly property bool favouriteByRegex: app && matchedByRegex(GlobalConfig.launcher.favouriteApps, app.id)
    readonly property bool hiddenByRegex: app && matchedByRegex(GlobalConfig.launcher.hiddenApps, app.id)

    function isRegexEntry(s: string): bool {
        return /^\^.*\$$/.test(s);
    }

    function matchedByRegex(filterList: list<string>, id: string): bool {
        return filterList.some(f => isRegexEntry(f) && new RegExp(f).test(id));
    }

    onAppChanged: {
        // Auto close when app lost
        if (!app)
            nState.closeSubPage();
    }

    title: Tr.tr("App info")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.large
            spacing: Tokens.spacing.large

            IconImage {
                asynchronous: true
                implicitSize: Math.round(Tokens.font.icon.large.pointSize * 3)
                source: Quickshell.iconPath(root.app?.icon, "image-missing")
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                StyledText {
                    Layout.fillWidth: true
                    text: root.app?.name ?? ""
                    font: Tokens.font.title.medium
                    wrapMode: Text.WordWrap
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: text
                    text: (root.app?.comment || root.app?.genericName) ?? ""
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                }
            }
        }

        // Launcher
        SectionHeader {
            first: true
            text: Tr.tr("Launcher")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Favourite")
            subtext: root.favouriteByRegex ? Tr.tr("Matched by a regex in favouriteApps — edit the config file to change") : Tr.tr("Pin to the top of the launcher")
            enabled: !root.favouriteByRegex
            checked: root.app && Strings.testRegexList(GlobalConfig.launcher.favouriteApps, root.app.id)
            onToggled: {
                const apps = GlobalConfig.launcher.favouriteApps;
                GlobalConfig.launcher.favouriteApps = checked ? [...apps, root.app.id] : apps.filter(a => a !== root.app.id);
            }
        }

        ToggleRow {
            last: true
            text: Tr.tr("Hidden")
            subtext: root.hiddenByRegex ? Tr.tr("Matched by a regex in hiddenApps — edit the config file to change") : Tr.tr("Hide from the launcher")
            enabled: !root.hiddenByRegex
            checked: root.app && Strings.testRegexList(GlobalConfig.launcher.hiddenApps, root.app.id)
            onToggled: {
                const apps = GlobalConfig.launcher.hiddenApps;
                GlobalConfig.launcher.hiddenApps = checked ? [...apps, root.app.id] : apps.filter(a => a !== root.app.id);
            }
        }

        // Details
        SectionHeader {
            text: Tr.tr("Details")
        }

        WrapInfoRow {
            id: appId

            first: true
            label: Tr.tr("App ID")
            value: root.app?.id ?? ""
            labelComp.Layout.preferredWidth: Math.max(labelComp.implicitWidth, command.labelComp.implicitWidth)
        }

        WrapInfoRow {
            id: command

            last: true
            label: Tr.tr("Command")
            value: (root.app?.command ?? []).join(" ")
            labelComp.Layout.preferredWidth: Math.max(labelComp.implicitWidth, appId.labelComp.implicitWidth)
        }
    }

    component WrapInfoRow: ConnectedRect {
        id: row

        property alias label: label.text
        property alias value: value.text
        readonly property alias labelComp: label

        Layout.fillWidth: true
        implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2

        RowLayout {
            id: rowLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.medium

            StyledText {
                id: label

                Layout.alignment: Qt.AlignTop
                font: Tokens.font.body.small
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                id: value

                Layout.fillWidth: true
                Layout.maximumWidth: implicitWidth + 1 // Whyyyyyyyyy
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }
        }
    }
}
