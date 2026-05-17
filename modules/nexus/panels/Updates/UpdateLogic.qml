pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

Item {
    id: logic

    property var panel: null

    readonly property string shellUpstreamUrl: "https://github.com/caelestia-dots/shell.git"
    readonly property string cliUpstreamUrl: "https://github.com/caelestia-dots/cli.git"

    readonly property string shellGitPath: {
        const url = Qt.resolvedUrl(".");
        const path = url.toString().replace(/^file:\/\//, "");
        const parts = path.split("/");
        parts.splice(-5);
        const resolved = parts.join("/");
        return resolved;
    }
    property string cliGitPath: ""

    property Process shellVersionProc: Process {
        command: ["sh", "-c", "git -C " + logic.shellGitPath + " describe --tags --match 'v*' --long 2>/dev/null || " + "git -C " + logic.shellGitPath + " describe --tags --match 'v*' 2>/dev/null || " + "caelestia -v 2>/dev/null | grep -oP 'caelestia-shell \\K[0-9.]+' || " + "git -C " + logic.shellGitPath + " rev-parse --short HEAD 2>/dev/null || echo 'Unknown'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (logic.panel) {
                    logic.panel.setPkg(0, {
                        installed: text.trim() || "Unknown"
                    });
                    logic.shellRemoteProc.running = true;
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() && logic.panel) {
                    console.warn("shellVersionProc error:", text.trim());
                }
            }
        }
    }

    property Process shellRemoteProc: Process {
        command: ["sh", "-c", "LOCAL=$(git -C " + logic.shellGitPath + " rev-parse HEAD 2>/dev/null); " + "REMOTE=$(git ls-remote " + logic.shellUpstreamUrl + " refs/heads/main 2>/dev/null | cut -f1); " + "AHEAD=$(git -C " + logic.shellGitPath + " rev-list --count HEAD..$REMOTE 2>/dev/null || echo 0); " + "if [ \"$AHEAD\" -gt 0 ]; then " + "LATEST_TAG=$(git ls-remote --tags --sort=-v:refname " + logic.shellUpstreamUrl + " 'v*' 2>/dev/null | grep -v '\\^{}' | grep -vE 'april-fools|rc|beta|alpha|pre|dev' | head -1 | sed 's/.*refs\\/tags\\///'); " + "if [ -n \"$LATEST_TAG\" ]; then echo \"$LATEST_TAG+$AHEAD\"; else echo \"${REMOTE:0:7}+${AHEAD}\"; fi; " + "else echo ''; fi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!logic.panel)
                    return;
                const remote = text.trim();
                if (remote) {
                    logic.panel.setPkg(0, {
                        available: remote,
                        hasUpdate: true,
                        checking: false
                    });
                } else {
                    logic.panel.setPkg(0, {
                        checking: false
                    });
                }
                logic.panel.checkDone();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    console.warn("shellRemoteProc error:", text.trim());
            }
        }
    }

    property Process cliDetectProc: Process {
        command: ["sh", "-c", "CUSTOM=\"" + (logic.panel ? logic.panel.cliGitPathSetting : "") + "\"; " + "if [ -n \"$CUSTOM\" ] && [ -d \"$CUSTOM/.git\" ]; then " + "  echo \"$CUSTOM\"; " + "else " + "  echo ''; " + "fi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                const customSet = logic.panel && logic.panel.cliGitPathSetting;
                logic.cliGitPath = path;
                logic.cliVersionProc.running = true;
            }
        }
    }

    property Process cliVersionProc: Process {
        command: ["sh", "-c", logic.cliGitPath ? "cd " + logic.cliGitPath + " && git describe --tags --abbrev=0 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo 'Unknown'" : "caelestia -v 2>/dev/null | head -1 | grep -oP '[0-9.]+' || pacman -Q caelestia-cli 2>/dev/null | awk '{print $2}' || echo 'Not found'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!logic.panel)
                    return;
                const ver = text.trim();
                const badge = logic.cliGitPath ? "git" : "unknown";
                logic.panel.setPkg(1, {
                    installed: ver || "Not found",
                    badge: badge,
                    method: logic.cliGitPath ? "git" : "unknown",
                    checking: false
                });
                if (logic.cliGitPath) {
                    logic.cliRemoteProc.running = true;
                } else {
                    logic.panel.checkDone();
                }
            }
        }
    }

    property Process cliRemoteProc: Process {
        command: ["sh", "-c", logic.cliGitPath ? "LOCAL=$(git -C " + logic.cliGitPath + " rev-parse HEAD 2>/dev/null) && " + "REMOTE=$(git ls-remote " + logic.cliUpstreamUrl + " refs/heads/main 2>/dev/null | cut -f1) && " + "if [ -n \"$REMOTE\" ] && [ \"$LOCAL\" != \"$REMOTE\" ]; then " + "  TAGS=$(git ls-remote --tags --sort=-v:refname " + logic.cliUpstreamUrl + " 'v*' 2>/dev/null | grep -v '\\^{}' | head -1 | sed 's/.*refs\\/tags\\///'); " + "  if [ -n \"$TAGS\" ]; then echo \"$TAGS\"; else echo \"${REMOTE:0:7}\"; fi; " + "else echo ''; fi" : "echo ''"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!logic.panel)
                    return;
                const remote = text.trim();
                if (remote) {
                    logic.panel.setPkg(1, {
                        available: remote,
                        hasUpdate: true,
                        checking: false
                    });
                } else {
                    logic.panel.setPkg(1, {
                        checking: false
                    });
                }
                logic.panel.checkDone();
            }
        }
    }

    property Process quickshellVersionProc: Process {
        command: ["sh", "-c", "pacman -Q quickshell-git 2>/dev/null || pacman -Q quickshell 2>/dev/null || echo 'quickshell Not_installed'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!logic.panel)
                    return;
                const parts = text.trim().split(/\s+/);
                const pkgName = parts[0] || "";
                let ver = parts[1] || "Not installed";
                const badge = pkgName.includes("-git") ? "AUR" : (ver === "Not_installed" ? "" : "pacman");
                if (pkgName.includes("-git") && ver.includes(".r")) {
                    const match = ver.match(/^([0-9.]+)\.r(\d+)/);
                    if (match)
                        ver = match[1] + "-r" + match[2];
                }
                logic.panel.setPkg(2, {
                    installed: ver.replace("Not_installed", "Not installed"),
                    badge: badge
                });
                logic.quickshellUpdateCheckProc.running = true;
            }
        }
    }

    property Process quickshellUpdateCheckProc: Process {
        command: ["sh", "-c", "(checkupdates 2>/dev/null; paru -Qua 2>/dev/null || yay -Qua 2>/dev/null) | grep -E '^quickshell' || echo ''"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!logic.panel)
                    return;
                const line = text.trim();
                if (line) {
                    const parts = line.split(/\s+/);
                    if (parts.length >= 4 && parts[2] === "->") {
                        logic.panel.setPkg(2, {
                            available: parts[3],
                            hasUpdate: true,
                            checking: false
                        });
                    } else {
                        logic.panel.setPkg(2, {
                            checking: false
                        });
                    }
                } else {
                    logic.panel.setPkg(2, {
                        checking: false
                    });
                }
                logic.panel.checkDone();
            }
        }
    }

    property Process qtVersionProc: Process {
        command: ["sh", "-c", "pacman -Q qt6-base 2>/dev/null | awk '{print $2}' || echo 'Not installed'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!logic.panel)
                    return;
                logic.panel.setPkg(3, {
                    installed: text.trim() || "Not installed",
                    badge: "pacman"
                });
                logic.qtUpdateCheckProc.running = true;
            }
        }
    }

    property Process qtUpdateCheckProc: Process {
        command: ["sh", "-c", "checkupdates 2>/dev/null | grep '^qt6-base ' || echo ''"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!logic.panel)
                    return;
                const line = text.trim();
                if (line) {
                    const parts = line.split(/\s+/);
                    if (parts.length >= 4 && parts[2] === "->") {
                        logic.panel.setPkg(3, {
                            available: parts[3],
                            hasUpdate: true,
                            checking: false
                        });
                    } else {
                        logic.panel.setPkg(3, {
                            checking: false
                        });
                    }
                } else {
                    logic.panel.setPkg(3, {
                        checking: false
                    });
                }
                logic.panel.checkDone();
            }
        }
    }

    property Process previewProc: Process {
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!logic.panel)
                    return;
                const output = text.trim() || "No changes to preview";
                if (logic.panel.previewIndex >= 0) {
                    logic.panel.setPkg(logic.panel.previewIndex, {
                        preview: output
                    });
                }
            }
        }
    }

    property string _expectedCommit: ""
    property string _repoPollingFor: ""

    property Process expectedCommitProc: Process {
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                logic._expectedCommit = text.trim();
            }
        }
    }

    property Process headCheckProc: Process {
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!logic.panel || !logic._repoPollingFor)
                    return;
                const currentHead = text.trim();
                if (currentHead !== logic._expectedCommit && currentHead.length === 40) {
                    // HEAD changed, pull completed
                    logic.panel.statusMessage = "Update applied. Rechecking...";
                    pullCompleteTimer.stop();
                    logic._repoPollingFor = "";
                    logic.panel.installing = false;
                    logic.panel.installTarget = "";
                    logic.panel.checkForUpdates();
                }
            }
        }
    }

    property Process gitPullProc: Process {
        property string _repoKey: ""

        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!logic.panel)
                    return;
                const output = text.trim();
                if (!output) {
                    logic.panel.installing = false;
                    logic.panel.installTarget = "";
                    logic.panel.statusMessage = "Update failed - no output from git";
                    return;
                }
                if (output.includes("CONFLICT") || output.includes("Merge conflict") || output.includes("Automatic merge failed")) {
                    logic.panel.installing = false;
                    logic.panel.installTarget = "";
                    logic.panel.statusMessage = "Merge conflicts - manual resolution required";
                    const idx = logic.gitPullProc._repoKey === "shell" ? 0 : 1; //qmllint disable
                    logic.panel.setPkg(idx, {
                        hasUpdate: true,
                        preview: "Merge conflicts detected. Please resolve manually:\n" + output.substring(0, 500)
                    });
                } else if (output.includes("error:") || output.includes("fatal:")) {
                    logic.panel.installing = false;
                    logic.panel.installTarget = "";
                    const idx = logic.gitPullProc._repoKey === "shell" ? 0 : 1; //qmllint disable
                    let errorMsg = "Update failed";
                    if (output.includes("unstaged changes")) {
                        errorMsg = "Local changes block update - commit or stash first";
                    } else if (output.includes("divergent")) {
                        errorMsg = "Divergent branches - manual merge required";
                    }
                    logic.panel.statusMessage = errorMsg;
                    logic.panel.setPkg(idx, {
                        hasUpdate: true,
                        preview: "Git error:\n" + output.substring(0, 300)
                    });
                } else {
                    logic.panel.statusMessage = "Pull complete. Waiting for changes to apply...";
                    pullCompleteTimer.start();
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const err = text.trim();
                if (err && logic.panel) {
                    // Surface git errors to UI
                    if (err.includes("error:") || err.includes("fatal:")) {
                        logic.panel.installing = false;
                        logic.panel.installTarget = "";
                        const idx = logic.gitPullProc._repoKey === "shell" ? 0 : 1; //qmllint disable
                        let errorMsg = "Update failed";
                        if (err.includes("unstaged changes")) {
                            errorMsg = "Local changes block update - commit or stash first";
                        } else if (err.includes("divergent")) {
                            errorMsg = "Divergent branches - manual merge required";
                        }
                        logic.panel.statusMessage = errorMsg;
                        logic.panel.setPkg(idx, {
                            hasUpdate: true,
                            preview: "Git error:\n" + err.substring(0, 300)
                        });
                    }
                }
            }
        }
    }

    property Process pacmanUpdateProc: Process {
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!logic.panel)
                    return;
                logic.panel.installing = false;
                logic.panel.installTarget = "";
                logic.panel.statusMessage = "Update complete. Rechecking...";
                logic.panel.checkForUpdates();
            }
        }
    }

    property Process updateAllProc: Process {
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!logic.panel)
                    return;
                const output = text.trim();
                if (output.includes("CONFLICT") || output.includes("Merge conflict") || output.includes("Automatic merge failed")) {
                    logic.panel.installing = false;
                    logic.panel.installTarget = "";
                    logic.panel.statusMessage = "Merge conflicts - manual resolution required";
                } else {
                    logic.panel.installing = false;
                    logic.panel.installTarget = "";
                    logic.panel.statusMessage = "All updates complete. Rechecking...";
                    logic.panel.checkForUpdates();
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() && logic.panel) {
                    console.warn("updateAllProc stderr:", text.trim());
                }
            }
        }
    }

    function startCheck() {
        shellVersionProc.running = true;
        cliDetectProc.running = true;
        quickshellVersionProc.running = true;
        qtVersionProc.running = true;
    }

    function runGitPull(repoPath: string, key: string) {
        logic.gitPullProc._repoKey = key;
        // Capture current HEAD before any operations
        logic._repoPollingFor = key;
        logic.expectedCommitProc.command = ["sh", "-c", "cd " + repoPath + " && git rev-parse HEAD"];
        logic.expectedCommitProc.running = true;
        // Detect remote by upstream URL and rebase onto upstream/main
        const upstreamUrl = key === "shell" ? logic.shellUpstreamUrl : logic.cliUpstreamUrl;
        logic.gitPullProc.command = ["sh", "-c", "cd " + repoPath + " && " + "remote=$(git remote -v | grep '" + upstreamUrl + "' | head -1 | awk '{print $1}') && " + "if [ -z \"$remote\" ]; then remote='origin'; fi && " + "echo 'Fetching from' $remote/main && " + "git fetch -q $remote main 2>&1 && " + "git rebase $remote/main 2>&1"];
        logic.gitPullProc.running = true;
        console.log("[Updates] gitPullProc started for", key);
    }

    function runPacmanUpdate(pkgNames: string) {
        pacmanUpdateProc.command = ["sh", "-c", "paru -S --noconfirm " + pkgNames + " 2>&1 || yay -S --noconfirm " + pkgNames + " 2>&1 || pkexec pacman -S --noconfirm " + pkgNames + " 2>&1"];
        pacmanUpdateProc.running = true;
    }

    function runUpdateAll(cmd: string) {
        updateAllProc.command = ["sh", "-c", cmd];
        updateAllProc.running = true;
    }

    function loadPreview(idx: int, method: string, key: string) {
        if (method === "git") {
            const repoPath = key === "shell" ? shellGitPath : cliGitPath;
            if (!repoPath) {
                panel.setPkg(idx, {
                    preview: "Repository path unknown"
                });
                return;
            }
            previewProc.command = ["sh", "-c", "cd " + repoPath + " && " + "git fetch -q " + (key === "shell" ? shellUpstreamUrl : cliUpstreamUrl) + " 2>/dev/null; " + "git log --oneline HEAD..FETCH_HEAD 2>/dev/null || echo 'No commits to preview'"];
        } else {
            const pacmanName = key === "quickshell" ? "quickshell-git quickshell" : "qt6-base";
            previewProc.command = ["sh", "-c", "paru -Si " + pacmanName + " 2>/dev/null | grep -E '^(Name|Version|Description|URL)' || pacman -Si " + pacmanName + " 2>/dev/null | grep -E '^(Name|Version|Description|URL)' || echo 'No details available'"];
        }
        previewProc.running = true;
    }

    Timer {
        id: pullCompleteTimer

        interval: 500
        repeat: true
        onTriggered: {
            if (!logic.panel || !logic._repoPollingFor) {
                stop();
                return;
            }
            // Check if pull completed by comparing HEAD to expected
            const repoPath = logic._repoPollingFor === "shell" ? logic.shellGitPath : logic.cliGitPath;
            if (repoPath) {
                logic.headCheckProc.command = ["sh", "-c", "cd " + repoPath + " && git rev-parse HEAD"];
                logic.headCheckProc.running = true;
            }
        }
    }
}
