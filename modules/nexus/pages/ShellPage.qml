pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.widgets
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property string principalId: "principal"

    // Curated Material Symbols for activity icons
    readonly property var activityIconOptions: [
        { id: "home", label: Tr.tr("Home") },
        { id: "apartment", label: Tr.tr("Apartment") },
        { id: "work", label: Tr.tr("Work") },
        { id: "work_outline", label: Tr.tr("Work outline") },
        { id: "sports_esports", label: Tr.tr("Games") },
        { id: "stadia_controller", label: Tr.tr("Controller") },
        { id: "school", label: Tr.tr("School") },
        { id: "menu_book", label: Tr.tr("Study") },
        { id: "code", label: Tr.tr("Code") },
        { id: "terminal", label: Tr.tr("Terminal") },
        { id: "brush", label: Tr.tr("Design") },
        { id: "palette", label: Tr.tr("Art") },
        { id: "music_note", label: Tr.tr("Music") },
        { id: "movie", label: Tr.tr("Movies") },
        { id: "photo_camera", label: Tr.tr("Photos") },
        { id: "chat", label: Tr.tr("Chat") },
        { id: "mail", label: Tr.tr("Mail") },
        { id: "public", label: Tr.tr("Web") },
        { id: "cloud", label: Tr.tr("Cloud") },
        { id: "science", label: Tr.tr("Science") },
        { id: "fitness_center", label: Tr.tr("Fitness") },
        { id: "restaurant", label: Tr.tr("Food") },
        { id: "coffee", label: Tr.tr("Coffee") },
        { id: "shopping_bag", label: Tr.tr("Shopping") },
        { id: "travel_explore", label: Tr.tr("Travel") },
        { id: "flight", label: Tr.tr("Flight") },
        { id: "favorite", label: Tr.tr("Favorite") },
        { id: "star", label: Tr.tr("Star") },
        { id: "bolt", label: Tr.tr("Bolt") },
        { id: "dark_mode", label: Tr.tr("Night") },
        { id: "light_mode", label: Tr.tr("Day") },
        { id: "dashboard", label: Tr.tr("Dashboard") },
        { id: "apps", label: Tr.tr("Apps") },
        { id: "layers", label: Tr.tr("Layers") },
        { id: "folder", label: Tr.tr("Folder") },
        { id: "person", label: Tr.tr("Person") },
        { id: "groups", label: Tr.tr("Groups") },
        { id: "settings", label: Tr.tr("Settings") }
    ]

    title: Tr.tr("Shell")

    function newActivityId(): string {
        return `activity-${Date.now().toString(36)}`;
    }

    function isPrincipal(item: var): bool {
        return (item?.id ?? "") === root.principalId;
    }

    function installedApps(): var {
        const apps = [...DesktopEntries.applications.values];
        apps.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        const out = [];
        const seen = {};
        for (let i = 0; i < apps.length; i++) {
            const a = apps[i];
            const cls = (a.startupClass || a.id || "").trim();
            if (!cls || seen[cls])
                continue;
            seen[cls] = true;
            out.push({
                id: cls,
                label: a.name ? `${a.name} (${cls})` : cls
            });
        }
        return out;
    }

    function appLabelForClass(classMatch: string): string {
        const cls = (classMatch || "").trim();
        if (!cls)
            return Tr.tr("Untitled rule");
        const apps = DesktopEntries.applications.values;
        for (let i = 0; i < apps.length; i++) {
            const a = apps[i];
            if ((a.startupClass || "") === cls || (a.id || "") === cls)
                return a.name || cls;
        }
        return cls;
    }

    function rulesFor(activityId: string, workspaceIndex: int): var {
        return GlobalConfig.activities.appRules.values.filter(r => (r.activityId || "") === activityId && (r.workspaceIndex || 0) === workspaceIndex);
    }

    function removeRule(rule: var): void {
        const vals = GlobalConfig.activities.appRules.values;
        const idx = vals.indexOf(rule);
        if (idx >= 0) {
            GlobalConfig.activities.appRules.remove(idx);
            Activities.syncSoon();
        }
    }

    function addRule(activityId: string, workspaceIndex: int, classMatch: string): void {
        if (!classMatch)
            return;
        const existing = root.rulesFor(activityId, workspaceIndex);
        if (existing.some(r => (r.classMatch || "") === classMatch))
            return;
        const rule = {
            classMatch: classMatch,
            activityId: activityId,
            workspaceIndex: workspaceIndex
        };
        GlobalConfig.activities.appRules.insert(rule);
        Activities.moveOpenWindowsForRule(rule);
        Activities.syncSoon();
    }

    function openLookSubPage(activityId: string, pageIdx: int): void {
        root.nState.editingActivityId = activityId || root.principalId;
        root.nState.openSubPage(pageIdx);
    }

    function resolvedWallpaper(activityId: string): string {
        void Activities.styleRevision;
        return Activities.resolveStyle(activityId).wallpaper || "";
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Group workspaces into activities and give each one its own wallpaper and colours. Empty look fields inherit from Home.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        SectionHeader {
            first: true
            text: Tr.tr("General")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Enable activities")
            subtext: Tr.tr("Show activity pills on the bar and use activity shortcuts")
            checked: GlobalConfig.activities.enabled
            onToggled: {
                GlobalConfig.activities.enabled = checked;
                Activities.syncSoon();
            }
        }

        ToggleRow {
            text: Tr.tr("Show app icons on workspaces")
            subtext: Tr.tr("Use real application icons; when off, show category icons under the workspace marker")
            checked: GlobalConfig.activities.showWindowIcons
            onToggled: GlobalConfig.activities.showWindowIcons = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Cross-activity desktop shortcuts")
            subtext: Tr.tr("Allow next/previous desktop shortcuts to leave the current activity; when off, they stay inside it")
            checked: GlobalConfig.activities.crossActivityWorkspaces
            onToggled: GlobalConfig.activities.crossActivityWorkspaces = checked
        }

        SectionHeader {
            text: Tr.tr("Activities")
        }

        Repeater {
            model: GlobalConfig.activities.activities.values

            ConnectedRect {
                id: actRow

                required property var modelData
                required property int index

                Layout.fillWidth: true
                first: index === 0
                last: index === GlobalConfig.activities.activities.count - 1
                implicitHeight: actCol.implicitHeight + Tokens.padding.medium * 2

                readonly property string activityId: modelData.id || ""
                readonly property var look: {
                    void Activities.styleRevision;
                    return Activities.resolveStyle(activityId);
                }

                ColumnLayout {
                    id: actCol

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

                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                const mapped = Activities.mappedActivities[actRow.index];
                                const range = mapped ? `${mapped.startWs}–${mapped.endWs}` : "?";
                                // TRANSLATORS: %1 = workspace id range, e.g. "1–2"
                                return Tr.tr("Workspaces %1").arg(range);
                            }
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                        }

                        IconButton {
                            icon: "delete"
                            type: IconButton.Text
                            isRound: true
                            visible: !root.isPrincipal(actRow.modelData)
                            enabled: !root.isPrincipal(actRow.modelData)
                            onClicked: {
                                if (root.isPrincipal(actRow.modelData))
                                    return;
                                GlobalConfig.activities.activities.remove(actRow.index);
                                Activities.syncSoon();
                            }
                        }
                    }

                    // Name + icon + desktop count on one standalone row
                    ConnectedRect {
                        id: nameIconRow

                        Layout.fillWidth: true
                        first: true
                        last: true
                        implicitHeight: nameIconLayout.implicitHeight + Tokens.padding.medium + Math.max(0, Tokens.padding.large - nameField.verticalPadding) * 2

                        RowLayout {
                            id: nameIconLayout

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Tokens.padding.largeIncreased
                            anchors.rightMargin: Tokens.padding.largeIncreased
                            spacing: Tokens.spacing.medium

                            IconButton {
                                Layout.alignment: Qt.AlignVCenter
                                icon: actRow.modelData.icon || "home"
                                type: IconButton.Tonal
                                isRound: true
                                onClicked: iconPicker.open = true
                            }

                            StyledTextField {
                                id: nameField

                                Layout.fillWidth: true
                                Layout.minimumWidth: Tokens.sizes.nexus.smallTextFieldWidth
                                Layout.alignment: Qt.AlignVCenter
                                verticalPadding: Tokens.padding.small
                                // Outlined field cuts a notch for placeholderText — use it as the label
                                placeholderText: Tr.tr("Name")
                                text: actRow.modelData.name ? Tr.trMarked(actRow.modelData.name) : ""
                                onEditingFinished: {
                                    actRow.modelData.name = text;
                                    Activities.syncSoon();
                                }
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                text: Tr.tr("Desktops")
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                            }

                            StyledSpinBox {
                                Layout.alignment: Qt.AlignVCenter
                                from: 1
                                to: 10
                                stepSize: 1
                                value: actRow.modelData.workspaceCount
                                cLayer: 2
                                onValueModified: {
                                    actRow.modelData.workspaceCount = Math.round(value);
                                    Activities.syncSoon();
                                }
                            }
                        }
                    }

                    DialogSelectButton {
                        id: iconPicker

                        Layout.fillWidth: true
                        Layout.preferredHeight: open ? implicitHeight : 0
                        Layout.maximumHeight: open ? 10000 : 0
                        clip: true
                        opacity: open ? 1 : 0
                        rootParent: root.flickable
                        icon: actRow.modelData.icon || "home"
                        label: Tr.tr("Change icon")
                        header: Tr.tr("Activity icon")
                        acceptLabel: Tr.trCtx("Select", "button")
                        searchable: true
                        searchPlaceholder: Tr.tr("Search icons")
                        iconGrid: true
                        iconGridColumns: 6
                        model: root.activityIconOptions
                        onAccepted: {
                            if (!selectedItem)
                                return;
                            actRow.modelData.icon = selectedItem;
                            Activities.syncSoon();
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.topMargin: Tokens.spacing.small
                        text: Tr.tr("Look")
                        font: Tokens.font.label.large
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: !root.isPrincipal(actRow.modelData) && !Activities.activityHasStyleOverride(actRow.activityId)
                        text: Tr.tr("Inheriting wallpaper and colours from Home")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                    }

                    ClipRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round(width * 0.28)
                        color: Colours.tPalette.m3surfaceContainer
                        radius: Tokens.rounding.large

                        WallpaperImpl {
                            anchors.fill: parent
                            // Preview the activity's resolved wallpaper path
                            source: root.resolvedWallpaper(actRow.activityId) || Wallpapers.fallback
                        }
                    }

                    ButtonRow {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Tokens.spacing.small

                        IconTextButton {
                            icon: "wallpaper"
                            text: Tr.tr("Wallpapers")
                            isRound: true
                            shapeMorph: true
                            type: IconTextButton.Tonal
                            horizontalPadding: Tokens.padding.large
                            verticalPadding: Tokens.padding.small
                            disabled: !Config.background.wallpaperEnabled
                            onClicked: root.openLookSubPage(actRow.activityId, 1)
                        }

                        IconTextButton {
                            icon: "palette"
                            text: Tr.tr("Colours")
                            isRound: true
                            shapeMorph: true
                            type: IconTextButton.Tonal
                            horizontalPadding: Tokens.padding.large
                            verticalPadding: Tokens.padding.small
                            onClicked: root.openLookSubPage(actRow.activityId, 3)
                        }
                    }

                    ToggleRow {
                        first: true
                        text: Tr.tr("Transparency")
                        checked: actRow.look.transparency > 0
                        onToggled: Activities.setActivityTransparency(actRow.activityId, checked)
                    }

                    ToggleRow {
                        text: Tr.tr("Dark theme")
                        subtext: Tr.tr("Shell and bar colours")
                        checked: actRow.look.mode !== "light"
                        onToggled: Activities.setActivityMode(actRow.activityId, checked ? "dark" : "light")
                    }

                    ToggleRow {
                        last: !Activities.activityHasStyleOverride(actRow.activityId) || root.isPrincipal(actRow.modelData)
                        text: Tr.tr("Light apps")
                        subtext: Tr.tr("Keep GTK/Qt apps light even if the shell is dark")
                        checked: actRow.look.lightApps > 0
                        onToggled: Activities.setActivityLightApps(actRow.activityId, checked)
                    }

                    IconTextButton {
                        Layout.alignment: Qt.AlignRight
                        visible: !root.isPrincipal(actRow.modelData) && Activities.activityHasStyleOverride(actRow.activityId)
                        icon: "reset_settings"
                        text: Tr.tr("Use Home look")
                        type: IconTextButton.Text
                        isRound: true
                        shapeMorph: true
                        onClicked: Activities.clearActivityStyle(actRow.activityId)
                    }

                    Repeater {
                        model: Math.max(1, actRow.modelData.workspaceCount || 1)

                        ColumnLayout {
                            id: deskBlock

                            required property int index
                            readonly property var deskRules: root.rulesFor(actRow.modelData.id, deskBlock.index)

                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledText {
                                Layout.fillWidth: true
                                Layout.topMargin: Tokens.spacing.small
                                // TRANSLATORS: %1 = 1-based desktop number within the activity
                                text: Tr.tr("Desktop %1").arg(deskBlock.index + 1)
                                font: Tokens.font.label.large
                            }

                            // Connected Material list: pins + trailing "Add app"
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.extraSmall / 2

                                Repeater {
                                    model: deskBlock.deskRules

                                    ConnectedRect {
                                        id: pinRow

                                        required property var modelData
                                        required property int index

                                        Layout.fillWidth: true
                                        first: index === 0
                                        last: false
                                        implicitHeight: pinLayout.implicitHeight + Tokens.padding.medium * 2

                                        RowLayout {
                                            id: pinLayout

                                            anchors.fill: parent
                                            anchors.margins: Tokens.padding.medium
                                            anchors.leftMargin: Tokens.padding.largeIncreased
                                            anchors.rightMargin: Tokens.padding.largeIncreased
                                            spacing: Tokens.spacing.medium

                                            IconImage {
                                                Layout.alignment: Qt.AlignVCenter
                                                asynchronous: true
                                                implicitSize: Math.round(Tokens.font.icon.medium.pointSize * 1.6)
                                                source: Icons.getAppIcon(pinRow.modelData.classMatch || "", "application-x-executable")
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 0

                                                StyledText {
                                                    Layout.fillWidth: true
                                                    text: root.appLabelForClass(pinRow.modelData.classMatch)
                                                    font: Tokens.font.body.small
                                                    elide: Text.ElideRight
                                                }

                                                StyledText {
                                                    Layout.fillWidth: true
                                                    visible: !!(pinRow.modelData.classMatch)
                                                    text: pinRow.modelData.classMatch
                                                    color: Colours.palette.m3outline
                                                    font: Tokens.font.label.small
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            IconButton {
                                                icon: "close"
                                                type: IconButton.Text
                                                isRound: true
                                                inactiveOnColour: Colours.palette.m3error
                                                label.fill: 0
                                                onClicked: root.removeRule(pinRow.modelData)
                                            }
                                        }
                                    }
                                }

                                DialogSelectButton {
                                    rootParent: root.flickable
                                    first: deskBlock.deskRules.length === 0
                                    last: true
                                    icon: "add"
                                    label: Tr.tr("Add app")
                                    header: Tr.tr("Installed apps")
                                    acceptLabel: Tr.trCtx("Add", "button")
                                    searchable: true
                                    searchPlaceholder: Tr.tr("Search apps")
                                    model: root.installedApps()
                                    onAccepted: {
                                        if (!selectedItem)
                                            return;
                                        root.addRule(actRow.modelData.id, deskBlock.index, selectedItem);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        IconTextButton {
            Layout.alignment: Qt.AlignRight
            icon: "add"
            text: Tr.tr("Add activity")
            type: IconTextButton.Tonal
            isRound: true
            shapeMorph: true
            onClicked: {
                GlobalConfig.activities.activities.insert({
                    id: root.newActivityId(),
                    name: Tr.tr("New activity"),
                    icon: "dashboard",
                    workspaceCount: 1
                });
                Activities.syncSoon();
            }
        }
    }
}
