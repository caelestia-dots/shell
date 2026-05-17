pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property int activeTabIndex: 0

    property bool checking: false
    property bool installing: false
    property string installTarget: ""
    property string statusMessage: ""
    property int previewIndex: -1

    property string cliGitPathSetting: Config.paths.cliGit

    property var packages: [
        {
            key: "shell",
            display: "Shell",
            icon: "desktop_windows",
            method: "git",
            installed: "",
            available: "",
            hasUpdate: false,
            preview: "",
            badge: "git",
            checking: false
        },
        {
            key: "cli",
            display: "CLI",
            icon: "terminal",
            method: "git",
            installed: "",
            available: "",
            hasUpdate: false,
            preview: "",
            badge: "git",
            checking: false
        },
        {
            key: "quickshell",
            display: "quickshell-git",
            icon: "widgets",
            method: "pacman",
            installed: "",
            available: "",
            hasUpdate: false,
            preview: "",
            badge: "AUR",
            checking: false
        },
        {
            key: "qt",
            display: "Qt6",
            icon: "code",
            method: "pacman",
            installed: "",
            available: "",
            hasUpdate: false,
            preview: "",
            badge: "pacman",
            checking: false
        }
    ]

    readonly property int updateCount: {
        let count = 0;
        for (let i = 0; i < packages.length; i++) {
            if (packages[i].hasUpdate)
                count++;
        }
        return count;
    }

    property int _checksRemaining: 0
    property var logic: null

    function saveCliPath(path: string) {
        root.cliGitPathSetting = path;
        GlobalConfig.paths.cliGit = path;
    }

    function setPkg(idx, props) {
        const pkgs = root.packages.slice();
        pkgs[idx] = Object.assign({}, pkgs[idx], props);
        root.packages = pkgs;
    }

    function checkDone() {
        root._checksRemaining--;
        if (root._checksRemaining <= 0) {
            root.checking = false;
            if (root.updateCount > 0) {
                root.statusMessage = root.updateCount + " update" + (root.updateCount > 1 ? "s" : "") + " available";
            } else {
                root.statusMessage = "Everything is up to date";
            }
        }
    }

    function checkForUpdates() {
        if (!logic) {
            retryTimer.start();
            return;
        }
        root.checking = true;
        root.statusMessage = "";
        root.previewIndex = -1;
        root._checksRemaining = 4;
        root.setPkg(0, {
            checking: true,
            hasUpdate: false,
            available: "",
            preview: ""
        });
        root.setPkg(1, {
            checking: true,
            hasUpdate: false,
            available: "",
            preview: ""
        });
        root.setPkg(2, {
            checking: true,
            hasUpdate: false,
            available: "",
            preview: ""
        });
        root.setPkg(3, {
            checking: true,
            hasUpdate: false,
            available: "",
            preview: ""
        });
        logic.startCheck();
    }

    function updatePackage(idx) {
        const pkg = root.packages[idx];
        root.installing = true;
        root.installTarget = pkg.key;
        if (pkg.method === "git") {
            const repoPath = pkg.key === "shell" ? logic.shellGitPath : logic.cliGitPath;
            root.statusMessage = "Pulling " + pkg.display + "...";
            logic.runGitPull(repoPath, pkg.key);
        } else {
            const pacmanName = pkg.key === "quickshell" ? "quickshell-git quickshell" : "qt6-base";
            root.statusMessage = "Updating " + pkg.display + "...";
            logic.runPacmanUpdate(pacmanName);
        }
    }

    function updateAll() {
        const gitPkgs = [];
        const pacmanPkgs = [];
        for (let i = 0; i < packages.length; i++) {
            if (!packages[i].hasUpdate)
                continue;
            if (packages[i].method === "git")
                gitPkgs.push(i);
            else
                pacmanPkgs.push(i);
        }
        if (gitPkgs.length === 0 && pacmanPkgs.length === 0)
            return;
        root.installing = true;
        root.installTarget = "all";
        let cmd = "";
        for (let i = 0; i < gitPkgs.length; i++) {
            const pkg = packages[gitPkgs[i]];
            const repoPath = pkg.key === "shell" ? logic.shellGitPath : logic.cliGitPath;
            const upstreamUrl = pkg.key === "shell" ? logic.shellUpstreamUrl : logic.cliUpstreamUrl;
            if (repoPath) {
                cmd += "echo '>>> Updating " + pkg.display + "' && " + "cd " + repoPath + " && " + "remote=$(git remote -v | grep '" + upstreamUrl + "' | head -1 | awk '{print $1}') && " + "if [ -z \"$remote\" ]; then remote='origin'; fi && " + "git fetch -q $remote main && git rebase $remote/main 2>&1 && ";
            }
        }
        if (pacmanPkgs.length > 0) {
            const names = [];
            for (let i = 0; i < pacmanPkgs.length; i++) {
                if (packages[pacmanPkgs[i]].key === "quickshell")
                    names.push("quickshell-git");
                else
                    names.push("qt6-base");
            }
            cmd += "paru -S --noconfirm " + names.join(" ") + " 2>&1 || yay -S --noconfirm " + names.join(" ") + " 2>&1 || pkexec pacman -S --noconfirm " + names.join(" ") + " 2>&1 && ";
        }
        cmd += "echo 'Done'";
        root.statusMessage = "Updating all...";
        logic.runUpdateAll(cmd);
    }

    function showPreview(idx) {
        if (root.previewIndex === idx) {
            root.previewIndex = -1;
            return;
        }
        root.previewIndex = idx;
        const pkg = root.packages[idx];
        if (pkg.preview)
            return;
        logic.loadPreview(idx, pkg.method, pkg.key);
    }

    Loader {
        id: logicLoader

        source: "UpdateLogic.qml"
        onLoaded: {
            item.panel = root;
            root.logic = item;
            root.checkForUpdates();
        }
    }

    Timer {
        id: retryTimer

        interval: 100
        onTriggered: root.checkForUpdates()
    }

    ScrollView {
        id: scrollView

        anchors.fill: parent
        clip: true

        ColumnLayout {
            width: scrollView.width
            spacing: Tokens.spacing.large

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.normal

                Rectangle {
                    id: checkBtn

                    implicitWidth: checkBtnLayout.implicitWidth + Tokens.padding.large * 2
                    implicitHeight: 40
                    radius: Tokens.rounding.full
                    color: root.checking ? Qt.alpha(Colours.palette.m3primary, 0.12) : Colours.tPalette.m3surfaceContainer
                    opacity: root.checking ? 0.6 : 1.0

                    RowLayout {
                        id: checkBtnLayout

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: "refresh"
                            font.pointSize: Tokens.font.size.normal
                            color: Colours.palette.m3primary

                            RotationAnimation on rotation {
                                running: root.checking
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                            }
                        }

                        StyledText {
                            text: "Check for Updates"
                            font.pointSize: Tokens.font.size.small
                            font.weight: Font.Medium
                            color: Colours.palette.m3primary
                        }
                    }

                    TapHandler {
                        enabled: !root.checking
                        onTapped: root.checkForUpdates()
                    }

                    HoverHandler {
                        id: checkHover

                        onHoveredChanged: checkBtn.color = root.checking ? Qt.alpha(Colours.palette.m3primary, 0.12) : (hovered ? Colours.tPalette.m3surfaceContainerHigh : Colours.tPalette.m3surfaceContainer)
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Tokens.anim.durations.small
                        }
                    }
                }
                StyledText {
                    text: root.checking ? "Checking for updates..." : root.statusMessage
                    font.pointSize: Tokens.font.size.small
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
                }
            }

            // Package list
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.normal

                Repeater {
                    model: root.packages.length

                    delegate: Loader {
                        required property int modelData

                        Layout.fillWidth: true
                        source: "PackageRow.qml"
                        onLoaded: {
                            item.index = modelData;
                            item.pkg = Qt.binding(() => root.packages[modelData]);
                            item.expanded = Qt.binding(() => root.previewIndex === modelData);
                            item.panel = root;
                        }
                    }
                }
            }

            Rectangle {
                id: updateAllBtn

                Layout.fillWidth: true
                implicitHeight: 44
                radius: Tokens.rounding.full
                color: root.updateCount > 0 ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3onSurface, 0.08)
                opacity: (root.updateCount > 0 && !root.installing) ? 1.0 : 0.5

                StyledText {
                    anchors.centerIn: parent
                    text: root.installing && root.installTarget === "all" ? "Updating..." : "Update All"
                    font.pointSize: Tokens.font.size.normal
                    font.weight: Font.Medium
                    color: root.updateCount > 0 ? Colours.palette.m3onPrimary : Qt.alpha(Colours.palette.m3onSurface, 0.4)
                }

                TapHandler {
                    enabled: root.updateCount > 0 && !root.installing
                    onTapped: root.updateAll()
                }

                HoverHandler {
                    id: updateAllHover

                    onHoveredChanged: {
                        if (root.updateCount > 0 && !root.installing) {
                            updateAllBtn.color = hovered ? Qt.lighter(Colours.palette.m3primary, 1.1) : Colours.palette.m3primary;
                        }
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Tokens.anim.durations.small
                    }
                }
            }

            // Settings section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.normal
                Layout.topMargin: Tokens.spacing.normal * 2

                StyledText {
                    text: "Settings"
                    font.pointSize: Tokens.font.size.normal
                    Layout.leftMargin: Tokens.padding.normal
                    font.weight: Font.Medium
                    color: Colours.palette.m3onSurfaceVariant
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: cliPathLayout.implicitHeight + Tokens.padding.normal * 4
                    radius: Tokens.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    ColumnLayout {
                        id: cliPathLayout

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.normal * 2
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: "CLI Git Path (for manual installs)"
                            font.pointSize: Tokens.font.size.normal
                            color: Colours.palette.m3onSurface
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledRect {
                                Layout.fillWidth: true
                                implicitHeight: Math.max(pathIcon.implicitHeight, cliPathInput.implicitHeight)
                                radius: Tokens.rounding.full
                                color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

                                MaterialIcon {
                                    id: pathIcon

                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: Tokens.padding.normal

                                    text: "folder"
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                StyledTextField {
                                    id: cliPathInput

                                    anchors.left: pathIcon.right
                                    anchors.right: parent.right
                                    anchors.leftMargin: Tokens.spacing.small
                                    anchors.rightMargin: Tokens.padding.normal

                                    topPadding: Tokens.padding.normal
                                    bottomPadding: Tokens.padding.normal

                                    text: root.cliGitPathSetting
                                    placeholderText: qsTr("Path to CLI git repo...")

                                    onEditingFinished: {
                                        root.cliGitPathSetting = text;
                                    }
                                }
                            }

                            Rectangle {
                                implicitWidth: saveBtnText.implicitWidth + Tokens.padding.normal * 2
                                implicitHeight: 36
                                radius: Tokens.rounding.full
                                color: saveBtnHover.hovered ? Qt.lighter(Colours.palette.m3primary, 1.1) : Colours.palette.m3primary

                                StyledText {
                                    id: saveBtnText

                                    anchors.centerIn: parent
                                    text: "Save"
                                    font.pointSize: Tokens.font.size.normal
                                    font.weight: Font.Medium
                                    color: Colours.palette.m3onPrimary
                                }

                                TapHandler {
                                    onTapped: {
                                        root.saveCliPath(cliPathInput.text);
                                        root.checkForUpdates();
                                    }
                                }

                                HoverHandler {
                                    id: saveBtnHover
                                }
                            }
                        }
                    }
                }
            }

            // Bottom spacer
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.padding.large
            }
        }
    }
}
