pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string configPath: Quickshell.env("HOME") + "/.config/caelestia/shell.json"
    property var configData: ({})
    property bool loaded: false
    property var expandedStates: ({})
    property var jsonFileData: ({})
    property bool isSaving: false
    
    signal valueChanged(path: list<string>)

    readonly property var configSections: [
        { name: "appearance", title: "Appearance", icon: "palette" },
        { name: "general", title: "General", icon: "settings" },
        { name: "background", title: "Background", icon: "wallpaper" },
        { name: "bar", title: "Bar", icon: "horizontal_rule" },
        { name: "border", title: "Border", icon: "border_style" },
        { name: "dashboard", title: "Dashboard", icon: "dashboard" },
        { name: "controlCenter", title: "Control Center", icon: "tune" },
        { name: "launcher", title: "Launcher", icon: "rocket_launch" },
        { name: "notifs", title: "Notifications", icon: "notifications" },
        { name: "osd", title: "OSD", icon: "speaker" },
        { name: "session", title: "Session", icon: "power_settings_new" },
        { name: "winfo", title: "Window Info", icon: "info" },
        { name: "lock", title: "Lock Screen", icon: "lock" },
        { name: "utilities", title: "Utilities", icon: "widgets" },
        { name: "sidebar", title: "Sidebar", icon: "side_navigation" },
        { name: "services", title: "Services", icon: "apps" }
    ]
    
    // Map of readonly properties by path
    readonly property var readonlyProperties: ({
        "dashboard.sizes.tabIndicatorHeight": true,
        "dashboard.sizes.tabIndicatorSpacing": true,
        "dashboard.sizes.infoWidth": true,
        "dashboard.sizes.infoIconSize": true,
        "dashboard.sizes.dateTimeWidth": true,
        "dashboard.sizes.mediaWidth": true,
        "dashboard.sizes.mediaProgressSweep": true,
        "dashboard.sizes.mediaProgressThickness": true,
        "dashboard.sizes.resourceProgessThickness": true,
        "dashboard.sizes.weatherWidth": true,
        "dashboard.sizes.mediaCoverArtSize": true,
        "dashboard.sizes.mediaVisualiserSize": true,
        "dashboard.sizes.resourceSize": true
    })

    Component.onCompleted: loadConfig()

    Timer {
        id: loadTimer
        interval: 100
        onTriggered: loadConfig()
    }

    FileView {
        id: jsonFile
        path: root.configPath
        watchChanges: true
        
        onLoaded: {
            try {
                root.jsonFileData = JSON.parse(text());
                loadConfig();
            } catch (e) {
                console.error("Failed to parse shell.json:", e);
                // Fall back to Config object if JSON parsing fails
                loadConfigFromObject();
            }
        }
        
        onFileChanged: {
            // Don't reload if we're the ones who just saved
            if (root.isSaving) {
                return;
            }
            // Reload when file changes externally
            try {
                root.jsonFileData = JSON.parse(text());
                loadConfig();
            } catch (e) {
                console.error("Failed to parse shell.json after change:", e);
            }
        }
        
        onLoadFailed: err => {
            console.warn("Failed to load shell.json:", FileViewError.toString(err));
            // Fall back to Config object if file doesn't exist
            loadConfigFromObject();
        }
    }

    function loadConfig() {
        const sections = {};
        for (const section of configSections) {
            const sectionName = section.name;
            // Merge JSON data with defaults from Config object
            // Priority: JSON file > Config object defaults
            const jsonSection = root.jsonFileData[sectionName] || {};
            const configSection = Config[sectionName];
            sections[sectionName] = mergeWithDefaults(jsonSection, configSection);
        }
        root.configData = sections;
        root.loaded = true;
    }
    
    function loadConfigFromObject() {
        // Fallback: load from Config object (defaults + JSON merged by JsonAdapter)
        const sections = {};
        for (const section of configSections) {
            sections[section.name] = collectObjectData(Config[section.name]);
        }
        root.configData = sections;
        root.loaded = true;
    }
    
    function mergeWithDefaults(jsonData, configObject) {
        // Create object with all properties from Config (for structure)
        const result = collectObjectData(configObject);
        
        // Override with values from JSON file
        function applyJsonValues(target, source) {
            for (const key in source) {
                if (source.hasOwnProperty(key)) {
                    const value = source[key];
                    if (value !== null && typeof value === "object" && !Array.isArray(value)) {
                        if (!target[key] || typeof target[key] !== "object") {
                            target[key] = {};
                        }
                        applyJsonValues(target[key], value);
                    } else {
                        // Use JSON value, which takes priority
                        target[key] = value;
                    }
                }
            }
        }
        
        applyJsonValues(result, jsonData);
        return result;
    }

    function collectObjectData(obj) {
        if (!obj) return {};
        
        const data = {};
        for (const key in obj) {
            if (key.startsWith("_") || key === "objectName" || key.endsWith("Changed"))
                continue;
            if (typeof obj[key] === "function")
                continue;
            
            const value = obj[key];
            
            if (value === null || value === undefined) {
                continue;
            } else if (typeof value === "boolean" || typeof value === "number" || typeof value === "string") {
                data[key] = value;
            } else if (Array.isArray(value)) {
                data[key] = Array.from(value);
            } else if (typeof value === "object") {
                data[key] = collectObjectData(value);
            }
        }
        return data;
    }

    Process {
        id: saveProcess
        command: ["sh", "-c", ""]

        onExited: (code, status) => {
            if (code !== 0) {
                console.error("Failed to save config:", saveProcess.stderr);
            }
            // Reset saving flag after a short delay to allow file system to settle
            resetSavingTimer.start();
        }
    }

    Timer {
        id: resetSavingTimer
        interval: 200
        onTriggered: root.isSaving = false
    }

    function saveConfig() {
        if (!root.jsonFileData) return false;
        
        try {
            root.isSaving = true;
            // Save only the JSON file data (not the merged data with defaults)
            const jsonString = JSON.stringify(root.jsonFileData, null, 4);
            const escapedJson = jsonString.replace(/'/g, "'\"'\"'");
            saveProcess.command = ["sh", "-c", `printf '%s' '${escapedJson}' > ${root.configPath}`];
            saveProcess.running = true;
            return true;
        } catch (e) {
            console.error("Failed to save config:", e);
            root.isSaving = false;
            return false;
        }
    }

    function getPropertyType(value): string {
        if (value === null || value === undefined) return "unknown";
        if (typeof value === "boolean") return "bool";
        if (typeof value === "number") return Number.isInteger(value) ? "int" : "real";
        if (typeof value === "string") return "string";
        if (typeof value === "object" && value !== null) {
            return Array.isArray(value) ? "list<var>" : "object";
        }
        return "unknown";
    }

    function getPropertiesForObject(obj, propertyPath = []): var {
        if (!obj || typeof obj !== "object") return [];

        const props = [];
        for (const key in obj) {
            if (!obj.hasOwnProperty(key)) continue;
            
            const value = obj[key];
            const type = getPropertyType(value);
            
            if (type !== "unknown") {
                const fullPath = [...propertyPath, key].join(".");
                const writable = !root.readonlyProperties[fullPath];
                props.push({ name: key, type: type, value: value, writable: writable });
            }
        }
        return props;
    }

    function getSectionData(sectionName: string): var {
        return (root.loaded && root.configData) ? (root.configData[sectionName] || null) : null;
    }

    function updateValue(path: list<string>, value): void {
        if (!root.configData || path.length === 0) return;

        // Update in configData (for UI display)
        let obj = root.configData;
        for (let i = 0; i < path.length - 1; i++) {
            if (!obj[path[i]]) {
                console.warn("Path segment not found in configData:", path[i], "at index", i);
                return;
            }
            obj = obj[path[i]];
        }
        const lastKey = path[path.length - 1];
        obj[lastKey] = value;

        // Update in jsonFileData (the source of truth for the JSON file)
        let jsonObj = root.jsonFileData;
        for (let i = 0; i < path.length - 1; i++) {
            if (!jsonObj[path[i]]) {
                jsonObj[path[i]] = {};
            }
            jsonObj = jsonObj[path[i]];
        }
        jsonObj[lastKey] = value;

        // Save to file first
        saveConfig();
        
        // Then notify Config object to reload from file
        // This ensures Config picks up the value from JSON
        root.valueChanged(path);
    }
    
    function setExpandedState(path: string, expanded: bool): void {
        root.expandedStates[path] = expanded;
    }
    
    function getExpandedState(path: string): bool {
        return root.expandedStates[path] ?? false;
    }

    function formatPropertyName(name: string): string {
        return name.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase()).trim();
    }
}
