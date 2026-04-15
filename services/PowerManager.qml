pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// An abstraction layer for emitting commands from different power management backends.
Singleton {
    id: root

    // --- GENERIC STATE ---
    // Expose generic string properties that UI can bind to
    property string activeBackend: "unknown" // Will be "ppd" (power-profiles-daemon) or "tlp"
    property string currentProfile: "balanced" // "saver", "balanced", or "performance"

    // --- INITIALIZATION & DETECTION ---
    Component.onCompleted: {
        // Run a background check to see which daemon is active.
        checkBackendProc.running = true;
    }

    // Checks the which power management backend is in use
    Process {
        id: checkBackendProc

        command: ["systemctl", "is-active", "tlp"]
        stdout: StdioCollector {
            id: tlpCollector

            onStreamFinished: {
                if (tlpCollector.text.trim() === "active")
                    root.activeBackend = "tlp";
                else {
                    root.activeBackend = "ppd";
                    // Only sync if PowerProfiles is actually alive
                    if (typeof PowerProfiles !== "undefined" && PowerProfiles.profile !== undefined) {
                        root.currentProfile = mapPpdToGeneric(PowerProfiles.profile);
                    }
                }
            }
        }
    }

    // A dedicated process for running TLP commands ---
    Process {
        id: tlpProcess

        // Custom property to remember what we are trying to switch to
        property string pendingProfile: ""

        onExited: exitCode => {
            // Exit code 0 means the password was correct and the command succeeded
            if (exitCode === 0)
                root.currentProfile = pendingProfile;
        }
    }
    //
    // --- ABSTRACTION METHODS ---
    function setProfile(targetProfile) {
        switch (activeBackend) {
        case ("ppd"):
            // PPD is instant and requires no password, so we can safely update the UI immediately
            root.currentProfile = targetProfile;
            if (targetProfile === "saver")
                PowerProfiles.profile = PowerProfile.PowerSaver;
            else if (targetProfile === "performance")
                PowerProfiles.profile = PowerProfile.Performance;
            else
                PowerProfiles.profile = PowerProfile.Balanced;
            break;
        case ("tlp"):
            // Store the profile we want to switch to
            tlpProcess.pendingProfile = targetProfile;
            let tlpCommandArg = "balanced";
            if (targetProfile === "saver")
                tlpCommandArg = "power-saver";
            if (targetProfile === "performance")
                tlpCommandArg = "performance";
            tlpProcess.command = ["pkexec", "tlp", tlpCommandArg];
            tlpProcess.running = true;
            break;
        }
    }

    // --- HELPER METHODS ---
    function mapPpdToGeneric(ppdProfile) {
        if (ppdProfile === PowerProfile.PowerSaver)
            return "saver";
        if (ppdProfile === PowerProfile.Performance)
            return "performance";
        return "balanced";
    }
}
