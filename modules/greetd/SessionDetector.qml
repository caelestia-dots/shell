import QtQuick

QtObject {
    id: root
    
    // For greetd module, we'll use a static list based on common sessions
    // In production, greetd itself provides the session list
    readonly property var sessions: {
        const detectedSessions = [];
        
        // Check for common session types - these are the most likely to be installed
        const commonSessions = [
            { id: "hyprland", name: "Hyprland", exec: "Hyprland" },
            { id: "hyprland-uwsm", name: "Hyprland (uwsm)", exec: "uwsm start -- hyprland.desktop" },
            { id: "plasma", name: "KDE Plasma", exec: "/usr/bin/startplasma-wayland" },
            { id: "gnome", name: "GNOME", exec: "gnome-session" },
            { id: "sway", name: "Sway", exec: "sway" },
            { id: "i3", name: "i3", exec: "i3" }
        ];
        
        // For testing, just return Hyprland and Plasma
        // In production, greetd would handle session detection
        return [
            { id: "hyprland", name: "Hyprland", exec: "Hyprland" },
            { id: "plasma", name: "KDE Plasma", exec: "/usr/bin/startplasma-wayland" }
        ];
    }
    
    readonly property string defaultSession: "hyprland"
}