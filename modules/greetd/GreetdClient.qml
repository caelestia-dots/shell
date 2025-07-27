pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root
    
    signal authenticationSucceeded()
    signal authenticationFailed(string message)
    signal sessionStarted()
    
    property string username: ""
    property string password: ""
    property string session: ""
    property bool authenticating: false
    
    // Socket connection to greetd
    property var socket: null
    property string socketPath: "/run/greetd.sock"
    
    function authenticate(user: string, pass: string, sess: string): void {
        if (authenticating) return;
        
        username = user;
        password = pass;
        session = sess;
        authenticating = true;
        
        // Try using greetd directly via socket or fall back to using agreety/tuigreet
        connectToGreetd();
    }
    
    function connectToGreetd(): void {
        // For now, we'll use a simpler approach with a helper script
        // that interfaces with greetd. In a production environment,
        // you'd implement the full greetd protocol over the socket.
        
        greetdProcess.start();
    }
    
    Process {
        id: greetdProcess
        
        // This assumes you have a helper script that handles greetd communication
        // You'll need to create this script based on your greetd configuration
        command: ["sh", "-c", `echo '${root.password}' | greetd-client login ${root.username} - ${root.session}`]
        
        onExited: (code, status) => {
            root.authenticating = false;
            
            if (code === 0) {
                root.authenticationSucceeded();
                // Start the session
                startSession();
            } else {
                // Parse error from stderr if available
                const errorMsg = stderr || "Authentication failed";
                root.authenticationFailed(errorMsg);
            }
        }
        
        property string stderr: ""
        
        onStderrChanged: line => {
            stderr += line;
        }
    }
    
    function startSession(): void {
        // The session should be started by greetd after successful authentication
        // This is typically handled by the greetd configuration
        root.sessionStarted();
        
        // For systemd-based systems, you might need to signal that the greeter is done
        Utils.exec(["loginctl", "activate", root.session]);
    }
    
    // Alternative approach using a custom greetd protocol implementation
    function createGreetdAuthScript(): string {
        // This would be a more robust implementation that properly
        // communicates with greetd over its socket protocol
        return `#!/bin/sh
# Greetd authentication helper
# This script interfaces with greetd to authenticate users

USERNAME="$1"
PASSWORD="$2"
SESSION="$3"

# Connect to greetd socket and perform authentication
# Implementation depends on your specific greetd setup
# You might use socat, nc, or a custom program

# For now, we'll use greetd-client if available
if command -v greetd-client >/dev/null 2>&1; then
    echo "$PASSWORD" | greetd-client login "$USERNAME" - "$SESSION"
else
    # Fallback to manual session start (requires proper permissions)
    echo "Error: greetd-client not found"
    exit 1
fi
`;
    }
}