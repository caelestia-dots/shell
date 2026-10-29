pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.utils

Singleton {
    id: root

    readonly property var cfg: GlobalConfig.utilities.updates
    readonly property bool checkArch: cfg.checkArch
    readonly property bool checkAur: cfg.checkAur
    readonly property bool checkFlatpak: cfg.checkFlatpak
    readonly property string aurWrapper: cfg.aurWrapper || "yay"
    readonly property int pollIntervalMinutes: Math.max(1, cfg.pollIntervalMinutes || 30)
    readonly property bool notificationsEnabled: cfg.notifications
    readonly property bool allowSingleModification: cfg.allowSingleModification

    property list<var> packages: []
    property bool busy: false
    property bool installing: false
    property string statusMessage: ""
    // Status glyph above the bar count; refresh action buttons use autorenew
    readonly property string glyph: "refresh"
    property string statusIcon: "refresh"
    property string error: ""
    property string authError: ""
    property real downloadSizeMb: 0
    property bool showSingleWarning: false
    property int pendingNexusPageIdx: -1
    // "background" | "logged" while the password UI is open
    property string pendingMode: ""
    property string installMode: ""
    property list<string> logLines: []
    property bool logVisible: false
    property int lastExitCode: 0
    // Ephemeral; cleared after writing to the update script stdin
    property string _authPw: ""

    readonly property int count: packages.length
    readonly property bool hasUpdates: count > 0
    readonly property bool awaitingPassword: pendingMode.length > 0
    readonly property string downloadSizeLabel: root.humanize(downloadSizeMb)

    readonly property string scriptPath: `${Quickshell.shellDir}/scripts/check-system-updates.py`
    readonly property string updateScriptPath: `${Quickshell.shellDir}/scripts/run-system-update.sh`

    function humanize(mib: real): string {
        if (!mib || mib <= 0)
            return "";
        const units = ["MiB", "GiB", "TiB"];
        let v = mib;
        let i = 0;
        while (v >= 1024 && i < units.length - 1) {
            v /= 1024;
            i++;
        }
        return `${v.toFixed(2)} ${units[i]}`;
    }

    function refresh(): void {
        if (checkProc.running || root.installing)
            return;
        root.busy = true;
        root.error = "";
        root.statusMessage = Tr.tr("Checking for updates…");
        root.statusIcon = "refresh";
        root.downloadSizeMb = 0;
        root.packages = [];

        const args = ["python3", root.scriptPath];
        if (root.checkArch)
            args.push("--arch");
        if (root.checkAur)
            args.push("--aur", root.aurWrapper);
        if (root.checkFlatpak)
            args.push("--flatpak");
        if (!root.checkArch && !root.checkAur && !root.checkFlatpak) {
            root.busy = false;
            root.statusMessage = Tr.tr("No update sources enabled");
            root.statusIcon = "info";
            return;
        }
        checkProc.command = args;
        checkTimeout.restart();
        checkProc.running = true;
    }

    function stop(): void {
        checkTimeout.stop();
        if (checkProc.running)
            checkProc.running = false;
        root.busy = false;
        root.statusMessage = root.hasUpdates ? root.summaryText() : "";
        root.statusIcon = root.hasUpdates ? root.glyph : "check_circle";
        poll.restart();
    }

    function summaryText(): string {
        if (!root.hasUpdates)
            return Tr.tr("System is up to date");
        if (root.downloadSizeLabel)
            return Tr.trN("%n update available (%1)", "%n updates available (%1)", root.count).arg(root.downloadSizeLabel);
        return Tr.trN("%n update available", "%n updates available", root.count);
    }

    function runInTerminal(shellCmd: string, message: string): void {
        root.statusMessage = message;
        root.statusIcon = "terminal";
        const term = GlobalConfig.general.apps.terminal;
        const banner = `echo ${JSON.stringify(Tr.tr("##### Caelestia updates #####"))}; `;
        const footer = `; echo; read -n 1 -p ${JSON.stringify(Tr.tr("Press any key to close…"))}`;
        const wrapped = `${banner}${shellCmd}${footer}`;
        Quickshell.execDetached([...term, "bash", "-c", wrapped]);
        // Re-check after a delay so the list refreshes once the user closes the terminal
        Qt.callLater(() => poll.restart());
        refreshTimer.restart();
    }

    function buildUpdateArgs(): var {
        const args = [root.updateScriptPath];
        if (root.checkAur) {
            args.push("--aur", root.aurWrapper);
            const flags = `${root.cfg.aurFlags || ""}`.trim().split(/\s+/).filter(f => f.length);
            for (let i = 0; i < flags.length; i++)
                args.push("--aur-flag", flags[i]);
        } else if (root.checkArch) {
            args.push("--arch");
        }
        if (root.checkFlatpak) {
            args.push("--flatpak");
            const flags = `${root.cfg.flatpakFlags || ""}`.trim().split(/\s+/).filter(f => f.length);
            for (let i = 0; i < flags.length; i++)
                args.push("--flatpak-flag", flags[i]);
        }
        if (!root.checkAur && !root.checkArch && !root.checkFlatpak)
            args.push("--arch");
        return args;
    }

    function appendLog(line: string): void {
        if (!line.length)
            return;
        const next = root.logLines.slice();
        next.push(line);
        while (next.length > 500)
            next.shift();
        root.logLines = next;
    }

    function requestUpdateSystem(mode: string): void {
        if (root.busy || root.installing || root.awaitingPassword)
            return;
        if (mode !== "background" && mode !== "logged")
            return;
        root.authError = "";
        root.pendingMode = mode;
    }

    function cancelPassword(): void {
        root.pendingMode = "";
        root.authError = "";
    }

    function confirmPassword(password: string): void {
        if (!root.awaitingPassword || root.installing)
            return;
        const pw = password || "";
        if (!pw.length) {
            root.authError = Tr.tr("Password required");
            return;
        }
        root.authError = "";
        root.installMode = root.pendingMode;
        root.installing = true;
        root.logLines = [];
        root.logVisible = root.installMode === "logged";
        root.lastExitCode = 0;
        root.error = "";
        root.statusMessage = Tr.tr("Updating system…");
        root.statusIcon = "install_desktop";
        root.appendLog(Tr.tr("Authenticating…"));

        root._authPw = pw;
        // Ensure stdin is open for this attempt (closed after writing so sudo cannot hang)
        authProc.stdinEnabled = true;
        authProc.command = ["sudo", "-S", "-v"];
        authTimeout.restart();
        authProc.running = true;
    }

    function stopInstall(): void {
        authTimeout.stop();
        installTimeout.stop();
        if (authProc.running)
            authProc.running = false;
        if (installProc.running)
            installProc.running = false;
        root._authPw = "";
        root.installing = false;
        root.installMode = "";
        root.pendingMode = "";
        root.statusMessage = root.hasUpdates ? root.summaryText() : "";
        root.statusIcon = root.hasUpdates ? root.glyph : "check_circle";
        root.appendLog(Tr.tr("Update cancelled."));
    }

    function onAuthFinished(code: int): void {
        authTimeout.stop();
        if (code !== 0) {
            root._authPw = "";
            root.installing = false;
            root.installMode = "";
            const locked = `${authErrCollector.text}`.toLowerCase().includes("locked");
            root.authError = locked
                ? Tr.tr("Too many failed attempts. Wait a minute and try again.")
                : Tr.tr("Incorrect password");
            root.statusMessage = root.hasUpdates ? root.summaryText() : "";
            root.statusIcon = root.hasUpdates ? root.glyph : "check_circle";
            Toaster.toast(Tr.tr("Authentication failed"), root.authError, "gpp_bad", Toast.Error);
            // Keep pendingMode so the password UI stays open for retry
            return;
        }
        // Auth OK — hand password to the update script over stdin (creates askpass itself)
        root.pendingMode = "";
        root.appendLog(Tr.tr("Starting system update…"));
        if (root.installMode === "background")
            Toaster.toast(Tr.tr("Updating system"), Tr.tr("Running in the background…"), "install_desktop");
        installProc.stdinEnabled = true;
        installProc.command = root.buildUpdateArgs();
        installTimeout.restart();
        installProc.running = true;
    }

    function onInstallFinished(code: int): void {
        installTimeout.stop();
        const wasBackground = root.installMode === "background";
        root._authPw = "";
        root.lastExitCode = code;
        root.installing = false;
        root.installMode = "";
        if (code === 0) {
            root.appendLog(Tr.tr("Update finished successfully."));
            Toaster.toast(Tr.tr("System updated"), Tr.tr("All updates were installed."), "check_circle");
        } else {
            root.appendLog(Tr.tr("Update failed (exit %1).").arg(code));
            // Background has no Nexus log panel — surface the last stderr lines in the toast
            let detail = Tr.tr("See the log for details.");
            if (wasBackground && root.logLines.length) {
                const tail = root.logLines.slice(-4).join("\n").trim();
                if (tail.length)
                    detail = tail;
            }
            Toaster.toast(Tr.tr("Update failed"), detail, "error", Toast.Error);
        }
        root.statusIcon = root.glyph;
        root.refresh();
    }

    function updatePackage(pkg: var): void {
        if (!pkg)
            return;
        if (!root.allowSingleModification && !(pkg.source || "").startsWith("FLATPAK")) {
            root.showSingleWarning = true;
            return;
        }
        const name = pkg.name;
        const src = pkg.source || "";
        let cmd = "";
        if (src.startsWith("FLATPAK"))
            cmd = `flatpak update ${JSON.stringify(pkg.from)}`;
        else if (src === "AUR")
            cmd = `${root.aurWrapper} -S ${JSON.stringify(name)}`;
        else
            cmd = `sudo pacman -S ${JSON.stringify(name)}`;
        root.runInTerminal(cmd, Tr.tr("Updating %1…").arg(name));
    }

    function uninstallPackage(pkg: var): void {
        if (!pkg)
            return;
        const name = pkg.name;
        const src = pkg.source || "";
        let cmd = "";
        if (src.startsWith("FLATPAK"))
            cmd = `flatpak remove ${JSON.stringify(pkg.from)}`;
        else if (src === "AUR")
            cmd = `sudo ${root.aurWrapper} -R ${JSON.stringify(name)}`;
        else
            cmd = `sudo pacman -R ${JSON.stringify(name)}`;
        root.runInTerminal(cmd, Tr.tr("Uninstalling %1…").arg(name));
    }

    function showPackageInfo(pkg: var): void {
        if (!pkg)
            return;
        const name = pkg.name;
        const src = pkg.source || "";
        const pause = `read -n 1 -p ${JSON.stringify(Tr.tr("Press any key to close…"))}`;
        let cmd = "";
        if (src.startsWith("FLATPAK"))
            cmd = `flatpak info ${JSON.stringify(pkg.from)}; ${pause}`;
        else if (src === "AUR")
            cmd = `${root.aurWrapper} -Sii ${JSON.stringify(name)}; ${pause}`;
        else
            cmd = `pacman -Sii ${JSON.stringify(name)}; ${pause}`;
        const term = GlobalConfig.general.apps.terminal;
        Quickshell.execDetached([...term, "bash", "-c", cmd]);
    }

    function openPackageUrl(pkg: var): void {
        if (pkg?.url)
            Quickshell.execDetached(["xdg-open", pkg.url]);
    }

    function cleanupOrphans(): void {
        root.runInTerminal("sudo pacman -Rns $(pacman -Qtdq)", Tr.tr("Cleaning orphans…"));
    }

    function prepareNexus(): void {
        // Updates is index 4 in PageRegistry (Shell, Network, Devices, Audio, Updates, …)
        root.pendingNexusPageIdx = 4;
    }

    function maybeNotify(list: list<var>): void {
        if (!root.notificationsEnabled)
            return;
        if (!GlobalConfig.utilities.toasts.updatesAvailable)
            return;
        const next = list.map(p => `${p.name} > ${p.to}`);
        const prev = (root.cfg.lastList || "").split("\n").filter(l => l.length);
        const diff = next.filter(l => !prev.includes(l));
        root.cfg.lastList = next.join("\n");
        if (diff.length <= 0)
            return;
        const body = diff.slice(0, 8).join("\n") + (diff.length > 8 ? "\n…" : "");
        Toaster.toast(Tr.trN("%n new update", "%n new updates", diff.length), body, root.glyph);
    }

    function onCheckFinished(code: int, text: string): void {
        const pkgs = [];
        let size = 0;
        for (const line of text.split("\n")) {
            const t = line.trim();
            if (!t.startsWith("{"))
                continue;
            try {
                const o = JSON.parse(t);
                pkgs.push(o);
                size += Number(o.size) || 0;
            } catch (e) {
                // skip bad lines
            }
        }
        root.packages = pkgs;
        root.downloadSizeMb = size;
        root.busy = false;
        root.statusMessage = root.summaryText();
        root.statusIcon = root.hasUpdates ? root.glyph : "check_circle";
        if (code !== 0 && pkgs.length === 0) {
            root.error = Tr.tr("Update check failed");
            root.statusIcon = "error";
        }
        root.maybeNotify(pkgs);
        poll.restart();
    }

    function ensureStatusIcon(): void {
        const list = GlobalConfig.bar.statusIcons;
        const values = list.values;
        for (let i = 0; i < values.length; i++) {
            if (values[i].id === "updates")
                return;
        }
        // Insert after vpn when present, else append
        let at = values.length;
        for (let i = 0; i < values.length; i++) {
            if (values[i].id === "vpn") {
                at = i + 1;
                break;
            }
        }
        list.insert({
            id: "updates",
            enabled: true
        }, at);
    }

    Component.onCompleted: {
        root.ensureStatusIcon();
        root.refresh();
    }

    Timer {
        id: poll
        interval: root.pollIntervalMinutes * 60 * 1000
        repeat: true
        running: root.checkArch || root.checkAur || root.checkFlatpak
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshTimer
        interval: 90 * 1000
        repeat: false
        onTriggered: root.refresh()
    }

    // Safety net if a check hangs (e.g. package helper blocking on stdin)
    Timer {
        id: checkTimeout
        interval: 120 * 1000
        repeat: false
        onTriggered: {
            if (!root.busy)
                return;
            root.stop();
            root.error = Tr.tr("Update check timed out");
            root.statusMessage = root.error;
            root.statusIcon = "error";
        }
    }

    Process {
        id: checkProc
        stdout: StdioCollector {
            onStreamFinished: {
                checkTimeout.stop();
                root.onCheckFinished(checkProc.exitCode ?? 0, text);
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: authProc
        stdinEnabled: true
        stdout: StdioCollector {}
        stderr: StdioCollector {
            id: authErrCollector
        }
        onStarted: {
            authProc.write(root._authPw + "\n");
            // Close stdin so sudo -S cannot hang waiting for another password attempt
            authProc.stdinEnabled = false;
        }
        onExited: code => root.onAuthFinished(code)
    }

    Process {
        id: installProc
        stdinEnabled: true
        stdout: SplitParser {
            onRead: data => root.appendLog(data)
        }
        stderr: SplitParser {
            onRead: data => root.appendLog(data)
        }
        onStarted: {
            installProc.write(root._authPw + "\n");
            root._authPw = "";
            installProc.stdinEnabled = false;
        }
        onExited: code => root.onInstallFinished(code)
    }

    Timer {
        id: authTimeout
        interval: 20000
        repeat: false
        onTriggered: {
            if (!authProc.running)
                return;
            root.appendLog(Tr.tr("Authentication timed out."));
            authProc.running = false;
            root._authPw = "";
            root.installing = false;
            root.installMode = "";
            root.authError = Tr.tr("Authentication timed out. Wait a minute if the account was locked, then try again.");
            root.statusMessage = root.hasUpdates ? root.summaryText() : "";
            root.statusIcon = root.hasUpdates ? root.glyph : "check_circle";
            Toaster.toast(Tr.tr("Authentication failed"), root.authError, "gpp_bad", Toast.Error);
        }
    }

    // Safety net: AUR builds can be long, but a hung sudo must not stick forever
    Timer {
        id: installTimeout
        interval: 45 * 60 * 1000
        repeat: false
        onTriggered: {
            if (!root.installing)
                return;
            root.appendLog(Tr.tr("Update timed out."));
            root.stopInstall();
            Toaster.toast(Tr.tr("Update failed"), Tr.tr("Timed out waiting for the package manager."), "error", Toast.Error);
        }
    }
}
