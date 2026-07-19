pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    property var liveMonitors: []
    property var drafts: ({})

    readonly property string configFileName: "hypr-displays.conf"
    readonly property string configFilePath: `${Quickshell.env("HOME")}/.config/caelestia/${configFileName}`

    function refreshMonitors(): void {
        queryProc.running = true;
    }

    function liveStateOf(m): var {
        const mirroring = m.mirrorOf !== "none";
        return {
            mode: mirroring ? "mirror" : "extend",
            enabled: !m.disabled,
            mirrorOf: mirroring ? liveMonitors.find(x => String(x.id) === m.mirrorOf).name : ""
        };
    }

    function effectiveStateOf(m): var {
        void drafts;
        return drafts[m.name] ?? liveStateOf(m);
    }

    function editDraft(name: string, key: string, value: var): void {
        const m = liveMonitors.find(x => x.name === name);
        if (!m)
            return;
        const next = Object.assign({}, drafts);
        next[name] = Object.assign({}, effectiveStateOf(m), {
            [key]: value
        });
        drafts = next;
    }

    function discardDraft(name: string): void {
        const next = Object.assign({}, drafts);
        delete next[name];
        drafts = next;
    }

    function validMirrorTargets(excludeName: string): list<string> {
        void drafts;
        return liveMonitors.filter(m => {
            if (m.name === excludeName)
                return false;
            const s = effectiveStateOf(m);
            return s.enabled && s.mode !== "mirror";
        }).map(m => m.name);
    }

    function effectiveMirrorTarget(excludeName: string, requested: string): string {
        const valid = validMirrorTargets(excludeName);
        if (valid.length === 0)
            return "";
        if (requested && valid.includes(requested))
            return requested;
        const focusedName = Hypr.focusedMonitor?.name;
        if (focusedName && valid.includes(focusedName))
            return focusedName;
        return valid[0];
    }

    function monitorConfigLine(m, state): string {
        const focused = m.name === Hypr.focusedMonitor?.name;
        if (!state.enabled && !focused)
            return `monitor = ${m.name},disable`;
        if (state.mode === "mirror" && !focused) {
            const target = effectiveMirrorTarget(m.name, state.mirrorOf);
            if (target)
                return `monitor = ${m.name},preferred,auto,1,mirror,${target}`;
        }
        return `monitor = ${m.name},preferred,auto,1`;
    }

    function buildConfigContent(): string {
        const lines = ["# managed by caelestia: displays card -- do not edit by hand"];
        for (const m of liveMonitors)
            lines.push(monitorConfigLine(m, effectiveStateOf(m)));
        return lines.join("\n") + "\n";
    }

    function commitDrafts(): void {
        configFile.setText(buildConfigContent());
        reloadProc.running = true;
    }

    Layout.fillWidth: true
    visible: liveMonitors.length > 1
    implicitHeight: visible ? layout.implicitHeight + Tokens.padding.large * 2 : 0
    radius: Tokens.rounding.normal
    color: Colours.tPalette.m3surfaceContainer
    clip: true

    Component.onCompleted: {
        refreshMonitors();
        hyprlandFile.reload();
    }

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name.includes("mon"))
                root.refreshMonitors();
        }

        target: Hyprland
    }

    Process {
        id: queryProc

        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.liveMonitors = JSON.parse(text) ?? [];
                } catch (e) {
                    root.liveMonitors = [];
                }
            }
        }
    }

    Process {
        id: reloadProc

        command: ["hyprctl", "reload"]
        onRunningChanged: {
            if (!running)
                root.refreshMonitors();
        }
    }

    FileView {
        id: configFile

        path: root.configFilePath
        printErrors: false
    }

    FileView {
        id: hyprlandFile

        path: `${Quickshell.env("HOME")}/.config/hypr/hyprland.conf`
        printErrors: false
        onLoaded: {
            const cur = text();
            if (!cur.includes(root.configFileName)) {
                setText(`${cur.replace(/\n+$/, "")}\nsource = ${root.configFilePath}\n`);
                if (!configFile.text())
                    configFile.setText(root.buildConfigContent());
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.normal

        StyledText {
            text: qsTr("Displays")
            font.pointSize: Tokens.font.size.normal
        }

        Repeater {
            model: root.liveMonitors

            delegate: ColumnLayout {
                id: row

                required property int index
                required property var modelData

                readonly property var live: root.liveStateOf(modelData)
                readonly property var cfg: root.drafts[modelData.name] ?? live

                readonly property string monitorName: modelData.name
                readonly property bool isEnabled: cfg.enabled
                readonly property string mirrorOf: cfg.mirrorOf
                readonly property bool isFocused: monitorName === Hypr.focusedMonitor?.name
                readonly property bool isMirroring: cfg.mode === "mirror"

                readonly property bool dirty: !isFocused && (cfg.mode !== live.mode || cfg.enabled !== live.enabled || (cfg.mode === "mirror" && cfg.mirrorOf !== live.mirrorOf))

                readonly property string mirrorTargetName: root.effectiveMirrorTarget(monitorName, mirrorOf)

                readonly property string statusText: {
                    if (!isEnabled)
                        return qsTr("Off");
                    if (isFocused)
                        return qsTr("Primary");
                    if (isMirroring)
                        return qsTr("Duplicating %1").arg(mirrorTargetName);
                    return qsTr("Extending");
                }

                Layout.fillWidth: true
                Layout.topMargin: index > 0 ? Tokens.spacing.small : 0
                spacing: Tokens.spacing.smaller

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.normal

                    StyledRect {
                        id: modeBtn

                        readonly property bool clickable: row.isEnabled && !row.isFocused && (row.isMirroring || root.validMirrorTargets(row.monitorName).length > 0)

                        implicitWidth: implicitHeight
                        implicitHeight: badgeIcon.implicitHeight + Tokens.padding.smaller * 2

                        radius: Tokens.rounding.full
                        color: !row.isEnabled ? Colours.palette.m3surfaceContainerHighest : row.isMirroring ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

                        StateLayer {
                            disabled: !modeBtn.clickable
                            color: row.isMirroring ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                            onClicked: {
                                if (row.isMirroring) {
                                    root.editDraft(row.monitorName, "mode", "extend");
                                    return;
                                }
                                root.editDraft(row.monitorName, "mode", "mirror");
                                const valid = root.validMirrorTargets(row.monitorName);
                                if (!valid.includes(row.mirrorOf))
                                    root.editDraft(row.monitorName, "mirrorOf", valid[0]);
                            }
                        }

                        MaterialIcon {
                            id: badgeIcon

                            anchors.centerIn: parent
                            text: !row.isEnabled ? "tv_off" : row.isMirroring ? "screen_share" : "monitor"
                            color: !row.isEnabled ? Colours.palette.m3onSurfaceVariant : row.isMirroring ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                            font.pointSize: Tokens.font.size.large
                            opacity: row.isEnabled ? 1.0 : 0.55
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: row.monitorName
                            font.pointSize: Tokens.font.size.normal
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: row.statusText
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Tokens.font.size.small
                            elide: Text.ElideRight
                        }
                    }

                    TextButton {
                        readonly property var validTargets: root.validMirrorTargets(row.monitorName)

                        type: TextButton.Tonal
                        visible: row.isMirroring
                        text: row.mirrorTargetName
                        enabled: validTargets.length > 1
                        onClicked: {
                            const cur = validTargets.includes(row.mirrorOf) ? row.mirrorOf : validTargets[0];
                            const idx = validTargets.indexOf(cur);
                            const next = validTargets[(idx + 1) % validTargets.length];
                            root.editDraft(row.monitorName, "mirrorOf", next);
                        }
                    }

                    StyledSwitch {
                        visible: !row.isFocused
                        checked: row.isEnabled
                        onToggled: root.editDraft(row.monitorName, "enabled", checked)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: row.dirty
                    spacing: Tokens.spacing.small

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        type: TextButton.Text
                        text: qsTr("Reset")
                        onClicked: root.discardDraft(row.monitorName)
                    }

                    TextButton {
                        type: TextButton.Filled
                        text: qsTr("Apply")
                        onClicked: root.commitDrafts()
                    }
                }
            }
        }
    }
}
