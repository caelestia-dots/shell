pragma Singleton

import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Searcher {
    id: root

    // Desktop application directories to scan and watch
    readonly property var desktopDirectories: [
        "/usr/share/applications",
        "/usr/local/share/applications", 
        "/var/lib/snapd/desktop/applications",
        (Paths.stringify(Paths.home).startsWith("file:///") ? Paths.stringify(Paths.home).substring(7) : Paths.stringify(Paths.home)) + "/.local/share/applications",
        (Paths.stringify(Paths.home).startsWith("file:///") ? Paths.stringify(Paths.home).substring(7) : Paths.stringify(Paths.home)) + "/.local/share/flatpak/exports/share/applications"
    ]

    // Dynamic application list built from scanning directories
    property var _applications: []
    list: _applications.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))


    useFuzzy: Config.launcher.useFuzzy.apps

    // Function to parse a desktop file content and create an AppEntry
    function parseDesktopFileContent(filePath: string, content: string): QtObject {
        try {
            const lines = content.split('\n');
            let id = filePath.slice(filePath.lastIndexOf('/') + 1).replace(/\.desktop$/, "");
            let name = "";
            let comment = "";
            let genericName = "";
            let icon = "";
            let execString = "";
            let categories = [];
            let noDisplay = false;
            let desktopFile = filePath;

            let inDesktopEntry = false;
            for (const line of lines) {
                const trimmed = line.trim();
                if (trimmed === '[Desktop Entry]') {
                    inDesktopEntry = true;
                    continue;
                } else if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
                    inDesktopEntry = false;
                    continue;
                }

                if (!inDesktopEntry || !trimmed.includes('=') || trimmed.startsWith('#')) continue;

                const equalIndex = trimmed.indexOf('=');
                const key = trimmed.substring(0, equalIndex).trim();
                const value = trimmed.substring(equalIndex + 1).trim();

                switch (key) {
                    case 'Name':
                        name = value;
                        break;
                    case 'Comment':
                        comment = value;
                        break;
                    case 'GenericName':
                        genericName = value;
                        break;
                    case 'Icon':
                        icon = value;
                        break;
                    case 'Exec':
                        execString = value;
                        break;
                    case 'Categories':
                        categories = value.split(';').filter(c => c.length > 0);
                        break;
                    case 'NoDisplay':
                        noDisplay = value.toLowerCase() === 'true';
                        break;
                }
            }

            // Use Qt.createQmlObject to create a QtObject with the parsed properties
            return Qt.createQmlObject(
                'import QtQuick 2.0; QtObject {' +
                'property string id: "' + id.replace(/"/g, '\\"') + '"; ' +
                'property string name: "' + name.replace(/"/g, '\\"') + '"; ' +
                'property string comment: "' + comment.replace(/"/g, '\\"') + '"; ' +
                'property string genericName: "' + genericName.replace(/"/g, '\\"') + '"; ' +
                'property string icon: "' + icon.replace(/"/g, '\\"') + '"; ' +
                'property string execString: "' + execString.replace(/"/g, '\\"') + '"; ' +
                'property var categories: ' + JSON.stringify(categories) + '; ' +
                'property bool noDisplay: ' + (noDisplay ? 'true' : 'false') + '; ' +
                'property string desktopFile: "' + desktopFile.replace(/"/g, '\\"') + '"; ' +
                '}',
                root
            );
        } catch (e) {
            console.warn("Failed to parse desktop file:", filePath, e);
            return Qt.createQmlObject('import QtQuick 2.0; QtObject {}', root);
        }
    }

    // Function to refresh applications by re-scanning directories
    function refreshApplications() {
        //console.log("Scanning for desktop applications...");
        scanAppsProc.running = true;
    }

    // Process to scan for desktop files and parse them
    Process {
        id: scanAppsProc
        
        running: true
        command: ["bash", "-c",
            "dirs=(" + root.desktopDirectories.join(' ') + "); " +
            "for dir in \"${dirs[@]}\"; do " +
            "if [ -d \"$dir\" ]; then " +
            "find -L \"$dir\" -name '*.desktop' -type f 2>/dev/null | while read -r file; do " +
            "echo '===FILE:$file==='; " +
            "cat \"$file\" 2>/dev/null; " +
            "echo '===ENDFILE==='; " +
            "done; " +
            "fi; " +
            "done"
        ]
        
        stdout: StdioCollector {
            onStreamFinished: {
                const sections = text.split('===ENDFILE===');
                //console.log("Found", sections.length - 1, "desktop file sections");
                
                const apps = [];
                
                for (const section of sections) {
                    if (!section.trim()) continue;
                    
                    const lines = section.split('\n');
                    let filePath = "";
                    let content = [];
                    
                    for (const line of lines) {
                        if (line.startsWith('===FILE:')) {
                            filePath = line.substring(9, line.length - 3);
                        } else if (line.trim()) {
                            content.push(line);
                        }
                    }
                    
                    if (filePath && content.length > 0) {
                        const appEntry = parseDesktopFileContent(filePath, content.join('\n'));
                        if (appEntry && appEntry.name) {
                            apps.push(appEntry);
                        }
                    }
                }
                
                root._applications = apps;
                //console.log("Total apps parsed:", apps.length);
                //console.log("Visible apps (not NoDisplay):", apps.filter(a => !a.noDisplay).length);
            }
        }
    }

    // Monitor changes using inotify
    Process {
        id: watchAppsProc
        
        running: true
        command: ["bash", "-c",
            "dirs=(" + root.desktopDirectories.join(' ') + "); " +
            "valid_dirs=(); " +
            "for dir in \"${dirs[@]}\"; do " +
            "if [ -d \"$dir\" ]; then valid_dirs+=(\"$dir\"); fi; done; " +
            "if [ ${#valid_dirs[@]} -gt 0 ]; then " +
            "stdbuf -oL inotifywait -r -e close_write,moved_to,moved_from,create,delete -m \"${valid_dirs[@]}\"; " +
            "fi;"
        ]
        
        stdout: StdioCollector {
            id: watchStdout
            waitForEnd: false
        }
        
    }
    Connections {
        target: watchStdout
        function onTextChanged() {
            console.log("WatchAppsProc output (stdout):", watchStdout.text);
            if (watchStdout.text.includes('.desktop')) {
                console.log("Desktop file changed:", watchStdout.text);
                refreshTimer.restart();
            }
        }
    }

    // Debounce timer to avoid excessive refreshes
    Timer {
        id: refreshTimer
        interval: 1000 // 1 second debounce
        onTriggered: () => refreshApplications()
    }

    Component.onCompleted: {
        refreshApplications();
    }

    function sanitizeExecString(execString) {
        // Remove desktop entry field codes like %F, %U, %f, %u, %i, %c, %k, etc.
        // Also remove Flatpak-specific markers like @@u and @@
        return execString.replace(/\s?%[fFuUdDnNickvm]/g, "")
                         .replace(/\s?@@u/g, "")
                         .replace(/\s?@@/g, "");
    }

    function launch(entry: var): void {
        var execString = sanitizeExecString(entry.execString);
        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: ["app2unit", "--", "foot", `${Quickshell.configDir}/assets/wrap_term_launch.sh`, ...execString.split(" ")],
                workingDirectory: entry.workingDirectory
            });
        else
            Quickshell.execDetached({
                command: ["app2unit", "--", ...execString.split(" ")],
                workingDirectory: entry.workingDirectory
            });
    }
}
