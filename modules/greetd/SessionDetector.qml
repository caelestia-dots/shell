pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root
    
    property var sessions: []
    property string defaultSession: "hyprland"
    
    Component.onCompleted: detectSessions()
    
    function detectSessions(): void {
        let detectedSessions = [];
        
        // Check X11 sessions
        checkSessionDir("/usr/share/xsessions/", detectedSessions);
        
        // Check Wayland sessions
        checkSessionDir("/usr/share/wayland-sessions/", detectedSessions);
        
        // Sort sessions alphabetically but keep Hyprland first if available
        detectedSessions.sort((a, b) => {
            if (a.id === "hyprland") return -1;
            if (b.id === "hyprland") return 1;
            return a.name.localeCompare(b.name);
        });
        
        sessions = detectedSessions;
        
        // Set default session
        if (detectedSessions.find(s => s.id === "hyprland")) {
            defaultSession = "hyprland";
        } else if (detectedSessions.length > 0) {
            defaultSession = detectedSessions[0].id;
        }
    }
    
    function checkSessionDir(dir: string, sessionList: var): void {
        const dirProcess = Utils.exec(["ls", "-1", dir]);
        
        if (dirProcess.stdout) {
            const files = dirProcess.stdout.trim().split("\n").filter(f => f.endsWith(".desktop"));
            
            for (const file of files) {
                const fullPath = dir + file;
                const sessionInfo = parseDesktopFile(fullPath);
                
                if (sessionInfo && sessionInfo.exec) {
                    sessionList.push({
                        id: file.replace(".desktop", ""),
                        name: sessionInfo.name,
                        comment: sessionInfo.comment || "",
                        exec: sessionInfo.exec,
                        tryExec: sessionInfo.tryExec || "",
                        desktopNames: sessionInfo.desktopNames || [],
                        file: fullPath
                    });
                }
            }
        }
    }
    
    function parseDesktopFile(path: string): var {
        const readProcess = Utils.exec(["cat", path]);
        
        if (!readProcess.stdout) return null;
        
        const lines = readProcess.stdout.split("\n");
        let info = {
            name: "",
            comment: "",
            exec: "",
            tryExec: "",
            desktopNames: []
        };
        
        for (const line of lines) {
            if (line.startsWith("Name=")) {
                info.name = line.substring(5);
            } else if (line.startsWith("Comment=")) {
                info.comment = line.substring(8);
            } else if (line.startsWith("Exec=")) {
                info.exec = line.substring(5);
            } else if (line.startsWith("TryExec=")) {
                info.tryExec = line.substring(8);
            } else if (line.startsWith("DesktopNames=")) {
                info.desktopNames = line.substring(13).split(";").filter(n => n);
            }
        }
        
        return info;
    }
    
    function getSessionCommand(sessionId: string): string {
        const session = sessions.find(s => s.id === sessionId);
        return session ? session.exec : sessionId;
    }
}